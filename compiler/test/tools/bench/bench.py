#!/usr/bin/env python3
"""Measure a dmd against ldc2 on fixed programs: compile cost and run cost,
in debug and release builds, split into a tuning set and a held-out set.

See README.md next to this file for what is measured, how the sets are
chosen, and how to read the results. Only the Python standard library is
used; macOS only, as the counts come from `/usr/bin/time -l`.
"""
import argparse
import datetime
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
LOCK = "/tmp/omega-heavy.lock"

# The langbench problems, split once, before any measurement, by this rule: the
# tuning set is the problems of langbench's "d-fast" suite, the inputs compiler
# changes have been profiled and tuned on; the held-out set is every other problem
# with benchmark inputs, which no change has been tuned on. Each set has 20.
LANGBENCH_TUNING = [
    "chess-perft", "datalog", "gitrepo", "jq", "kvstore", "langvm", "linalg",
    "ordered-map", "regex", "rrule", "rubiks", "sat", "scheme", "sitegen",
    "template", "textbuffer", "toml", "typeinfer", "typeset", "webhooks",
]
LANGBENCH_HELDOUT = [
    "bigint", "buildsys", "cardgame", "chip8", "commonmark", "depresolve", "diff",
    "fulltext", "inflate", "json", "jsonschema", "mime", "minisql", "orderbook",
    "protowire", "qrcode", "softfloat", "spreadsheet", "sqlitefile", "svgraster",
]
# where an implementation of a problem is taken from, the first that has one
LANGBENCH_ROOTS = ["impls", "projects", "runs-large"]

# Phobos modules whose unittests are compiled and run, held out: no change has
# been tuned on them.
PHOBOS_MODULES = [
    "std.algorithm.sorting", "std.array", "std.bigint", "std.conv", "std.datetime.date",
    "std.json", "std.math.exponential", "std.string", "std.utf",
]

# dub packages whose unittests are compiled and run, held out. The versions are
# those in the local dub cache; nothing is fetched.
DUB_PACKAGES = {
    "dyaml": {"version": "0.9.2", "deps": {"tinyendian": "0.2.0"}},
    "emsi_containers": {"version": "0.9.0", "deps": {}},
    "mir-algorithm": {"version": "3.22.4", "deps": {"mir-core": "1.7.4"}},
}
DEFAULT_DUB_PACKAGES = ["dyaml", "emsi_containers"]

# The whiteout headless simulation, the program the tuning has been driven by.
WHITEOUT_RUN = ["--demo-battle", "--perf", "--units", "512", "--ticks", "400", "--seed", "7"]
WHITEOUT_PACKAGES = ["bindbc-bgfx", "bindbc-common", "bindbc-loader", "bindbc-sdl", "box3d"]

# Flags a build script or dub may pass that set the optimization, debug info or
# bounds checking, which the compiler wrapper replaces with those of the mode.
DROPPED_FLAG = re.compile(
    r"^(-O[0-5sz]?|-release|-inline|-enable-inlining|-g|-gc|-gs|-gf|-gdwarf=.*|--?boundscheck=.*"
    r"|--?mcpu=.*|--?flto=.*|--?ffast-math|-j=.*|-enable-cross-module-inlining)$")

MODE_FLAGS = {
    ("dmd", "debug"): ["-g"],
    ("dmd", "release"): ["-O", "-release", "-inline"],
    ("ldc", "debug"): ["-g"],
    ("ldc", "release"): ["-O3", "-release"],
}

MACHO = (b"\xcf\xfa\xed\xfe", b"\xca\xfe\xba\xbe", b"\xfe\xed\xfa\xcf", b"!<arch>")
BUILD_DIRS = {".dub", "bin", "build", ".build", "objs", "obj", "__pycache__"}


def log(msg):
    print(msg, file=sys.stderr, flush=True)


# ---------------------------------------------------------------- compilers

class Compiler:
    def __init__(self, path, kind):
        self.path = os.path.abspath(shutil.which(path) or path)
        self.kind = kind
        self.version = subprocess.run([self.path, "--version"], capture_output=True, text=True).stdout.split("\n")[0].strip()
        self.git = ""
        d = os.path.dirname(self.path)
        g = subprocess.run(["git", "-C", d, "rev-parse", "--short=10", "HEAD"], capture_output=True, text=True)
        if g.returncode == 0:
            self.git = g.stdout.strip()
        # the dmd parallel workers are forked processes, which the counts of the
        # compiler process leave out, so dmd compiles in one process
        self.serial = []
        if kind == "dmd":
            with tempfile.TemporaryDirectory() as t:
                e = os.path.join(t, "e.d")
                with open(e, "w") as f:
                    f.write("void f() {}\n")
                if subprocess.run([self.path, "-j=1", "-c", "-o-", e], capture_output=True).returncode == 0:
                    self.serial = ["-j=1"]

    def info(self):
        return {"path": self.path, "kind": self.kind, "version": self.version, "git": self.git}

    def wrapper(self, mode, workdir):
        """A directory holding `dmd` and `ldc2` that run this compiler in the mode,
        appending its counts to a log. Returns (directory, log path)."""
        # dub tells compilers apart by their path, so the path names neither
        wdir = tempfile.mkdtemp(prefix="wrap-", dir=workdir)
        logpath = os.path.join(wdir, "time.log")
        flags = MODE_FLAGS[(self.kind, mode)] + self.serial
        script = f"""#!/usr/bin/env python3
import os, re, sys
drop = re.compile({DROPPED_FLAG.pattern!r})
args = [a for a in sys.argv[1:] if not drop.match(a)]
# only a compiling invocation gets the mode's flags; a version query stays as it is
if not any(a in ("--version", "-v", "--help", "-h") for a in args):
    args = {flags!r} + args
os.execv("/usr/bin/time", ["/usr/bin/time", "-l", "-a", "-o", {logpath!r}, {self.path!r}] + args)
"""
        for name in ("dmd", "ldc2", "ldmd2"):
            p = os.path.join(wdir, name)
            with open(p, "w") as f:
                f.write(script)
            os.chmod(p, 0o755)
        open(logpath, "w").close()
        return wdir, logpath

    def name_for_dub(self):
        return "ldc2" if self.kind == "ldc" else "dmd"


def parse_time_log(path):
    """Sum the `/usr/bin/time -l` reports in a log, one per compiler process."""
    text = open(path).read() if os.path.exists(path) else ""
    tot = {"instr": 0, "cycles": 0, "wall": 0.0, "procs": 0, "rss_max": 0}
    for m in re.finditer(r"([\d.]+) real.*?\n(.*?)(?=\n\s*[\d.]+ real|\Z)", text, re.S):
        body = m.group(2)
        tot["procs"] += 1
        tot["wall"] += float(m.group(1))
        i = re.search(r"(\d+)\s+instructions retired", body)
        c = re.search(r"(\d+)\s+cycles elapsed", body)
        r = re.search(r"(\d+)\s+maximum resident set size", body)
        tot["instr"] += int(i.group(1)) if i else 0
        tot["cycles"] += int(c.group(1)) if c else 0
        tot["rss_max"] = max(tot["rss_max"], int(r.group(1)) if r else 0)
    return tot


def timed(cmd, cwd, stdin_path=None, stdout_path=None, timeout=None, env=None):
    """Run cmd under `/usr/bin/time -l`: its exit status, wall time, instructions and cycles."""
    fd, tpath = tempfile.mkstemp(suffix=".time")
    os.close(fd)
    fin = open(stdin_path, "rb") if stdin_path else subprocess.DEVNULL
    fout = open(stdout_path, "wb") if stdout_path else subprocess.DEVNULL
    start = time.perf_counter()
    proc = subprocess.Popen(["/usr/bin/time", "-l", "-o", tpath] + cmd, cwd=cwd, stdin=fin, stdout=fout,
                            stderr=subprocess.DEVNULL, start_new_session=True, env=env)
    try:
        rc = proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        os.killpg(proc.pid, 9)
        proc.wait()
        rc = None
    wall = time.perf_counter() - start
    for f in (fin, fout):
        if hasattr(f, "close"):
            f.close()
    t = parse_time_log(tpath)
    os.unlink(tpath)
    return {"rc": rc, "wall": wall, "instr": t["instr"], "cycles": t["cycles"], "rss_max": t["rss_max"]}


# ---------------------------------------------------------------- checking outputs

def normalize(text):
    return "\n".join(line.rstrip() for line in text.replace("\r\n", "\n").split("\n")).rstrip("\n")


def tree_files(root):
    out = {}
    for dp, dns, fns in os.walk(root):
        dns.sort()
        for fn in sorted(fns):
            full = os.path.join(dp, fn)
            out[os.path.relpath(full, root)] = full
    return out


def same_trees(expected, actual):
    exp, act = tree_files(expected), tree_files(actual)
    if set(exp) != set(act):
        return False
    for rel in exp:
        a, b = open(exp[rel], "rb").read(), open(act[rel], "rb").read()
        if b"\0" in a[:8192] or b"\0" in b[:8192]:
            if a != b:
                return False
        elif normalize(a.decode("utf-8", "replace")) != normalize(b.decode("utf-8", "replace")):
            return False
    return True


# ---------------------------------------------------------------- items

def copy_tree(src, dst):
    def ignore(d, names):
        out = set()
        for n in names:
            p = os.path.join(d, n)
            if n in BUILD_DIRS and os.path.isdir(p):
                out.add(n)
            elif os.path.isfile(p) and not os.path.islink(p):
                with open(p, "rb") as f:
                    if f.read(8).startswith(MACHO) or n.endswith((".o", ".a")):
                        out.add(n)
        return out
    shutil.copytree(src, dst, ignore=ignore, symlinks=True)


COMPILER_WORD = re.compile(r"(^|[\s;&|(]|exec\s)(?:[^\s=\-\"'][^\s=]*/)?(ldc2|ldmd2|dmd)(?=\s)", re.M)


def retarget(build_sh, wdir, dub_name):
    """The build script with its compiler replaced by the wrapper in wdir."""
    text = re.sub(r"--compiler=(\"[^\"]*\"|'[^']*'|\S+)", f"--compiler={wdir}/{dub_name}", build_sh)
    return "".join(line if line.lstrip().startswith("#") else COMPILER_WORD.sub(lambda m: f"{m.group(1)}\"{wdir}/ldc2\"", line)
                   for line in text.splitlines(keepends=True))


def langbench_cases(corpus, slug):
    """The benchmark input of a problem: the first in name order."""
    tdir = os.path.join(corpus, "problems", slug, "bench")
    dirs = sorted(d for d in os.listdir(tdir) if os.path.isdir(os.path.join(tdir, d, "input")))
    if dirs:
        return tdir, dirs[0], "dir"
    ins = sorted(f for f in os.listdir(tdir) if f.endswith(".in"))
    return tdir, ins[0], "stdin"


def run_langbench_case(corpus, slug, run_sh, timeout):
    tdir, name, mode = langbench_cases(corpus, slug)
    pdir = os.path.join(corpus, "problems", slug)
    verifier = os.path.join(pdir, "verify.py")
    if mode == "dir":
        case = os.path.join(tdir, name)
        out_dir = tempfile.mkdtemp(prefix="bench_out_")
        try:
            m = timed([run_sh, os.path.join(case, "input"), out_dir], pdir, timeout=timeout)
            status = "timeout" if m["rc"] is None else "error" if m["rc"] else None
            if status is None:
                expected = os.path.join(case, "expected")
                if os.path.exists(verifier):
                    v = subprocess.run([sys.executable, verifier, os.path.join(case, "input"), out_dir]
                                       + ([expected] if os.path.isdir(expected) else []), capture_output=True)
                    status = "ok" if v.returncode == 0 else "wrong"
                else:
                    status = "ok" if same_trees(expected, out_dir) else "wrong"
        finally:
            shutil.rmtree(out_dir, ignore_errors=True)
        m["input"] = name
        return status, m
    in_path = os.path.join(tdir, name)
    fd, out_path = tempfile.mkstemp(suffix=".out")
    os.close(fd)
    try:
        m = timed([run_sh], pdir, stdin_path=in_path, stdout_path=out_path, timeout=timeout)
        status = "timeout" if m["rc"] is None else "error" if m["rc"] else None
        if status is None:
            exp = in_path[:-3] + ".out"
            if os.path.exists(verifier):
                v = subprocess.run([sys.executable, verifier, in_path, out_path] + ([exp] if os.path.exists(exp) else []),
                                   capture_output=True)
                status = "ok" if v.returncode == 0 else "wrong"
            else:
                a = open(out_path, encoding="utf-8", errors="replace").read()
                status = "ok" if normalize(a) == normalize(open(exp, encoding="utf-8").read()) else "wrong"
    finally:
        os.unlink(out_path)
    m["input"] = name
    return status, m


def item_langbench(args, comp, mode, work, slug):
    src = next((os.path.join(args.langbench, r, "d", slug) for r in LANGBENCH_ROOTS
                if os.path.exists(os.path.join(args.langbench, r, "d", slug, "build.sh"))), None)
    if not src:
        return {"status": "missing"}
    dst = os.path.join(work, "lb-" + slug)
    copy_tree(src, dst)
    wdir, tlog = comp.wrapper(mode, work)
    bsh = os.path.join(dst, "build.sh")
    with open(bsh) as f:
        text = f.read()
    with open(bsh, "w") as f:
        f.write(retarget(text, wdir, comp.name_for_dub()))
    env = dict(os.environ, PATH=wdir + ":" + os.environ["PATH"], DUB_HOME=os.path.join(work, "dubhome-" + slug))
    b = subprocess.run(["sh", bsh], cwd=dst, capture_output=True, text=True, env=env, timeout=args.build_timeout)
    res = {"compile": parse_time_log(tlog), "source": os.path.relpath(src, args.langbench)}
    if b.returncode:
        res["status"] = "build-failed"
        res["build_log"] = (b.stdout + b.stderr)[-2000:]
        return res
    status, m = run_langbench_case(args.langbench, slug, os.path.join(dst, "run.sh"), args.timeout)
    res.update(status=status, run=m)
    return res


def dub_home_with(work, name, packages):
    """A DUB_HOME holding copies of the given cached packages {name: version or None for all}."""
    home = os.path.join(work, name)
    os.makedirs(os.path.join(home, "packages"), exist_ok=True)
    cache = os.path.expanduser("~/.dub/packages")
    for p, v in packages.items():
        src = os.path.join(cache, p, v) if v else os.path.join(cache, p)
        dst = os.path.join(home, "packages", p, v) if v else os.path.join(home, "packages", p)
        shutil.copytree(src, dst, symlinks=True, ignore=shutil.ignore_patterns(".dub", "*.a", "*.o"))
    local = os.path.join(cache, "local-packages.json")
    if os.path.exists(local):
        shutil.copy(local, os.path.join(home, "packages"))
    return home


def item_whiteout(args, comp, mode, work):
    wo = os.path.join(work, "whiteout")
    os.makedirs(wo)
    src = args.whiteout
    for n in os.listdir(src):
        p = os.path.join(src, n)
        if n in ("source", "dub.sdl", "dub.selections.json"):
            (shutil.copytree if os.path.isdir(p) else shutil.copy)(p, os.path.join(wo, n))
        elif n in ("data", "assets", "shaders"):
            os.symlink(p, os.path.join(wo, n))
    cy = os.path.join(os.path.dirname(os.path.abspath(src)), "cydonia")
    shutil.copytree(cy, os.path.join(work, "cydonia"), symlinks=True,
                    ignore=shutil.ignore_patterns(".dub", ".git", "*.o", "*.a"))
    home = dub_home_with(work, "dubhome", {p: None for p in WHITEOUT_PACKAGES})
    wdir, tlog = comp.wrapper(mode, work)
    env = dict(os.environ, DUB_HOME=home)
    cmd = ["dub", "build", "-b", "plain", "--config=headless", "--skip-registry=all", "--force",
           f"--compiler={wdir}/{comp.name_for_dub()}"]
    b = subprocess.run(cmd, cwd=wo, capture_output=True, text=True, env=env, timeout=args.build_timeout)
    res = {"compile": parse_time_log(tlog)}
    if b.returncode:
        res["status"] = "build-failed"
        res["build_log"] = (b.stdout + b.stderr)[-2000:]
        return res
    m = timed([os.path.join(wo, "whiteout-headless")] + WHITEOUT_RUN, wo, timeout=args.timeout * 10)
    res.update(status="ok" if m["rc"] == 0 else "timeout" if m["rc"] is None else "error", run=m)
    return res


def module_path(comp, module, work):
    """The source file of a library module as the compiler finds it."""
    e = os.path.join(work, "probe.d")
    with open(e, "w") as f:
        f.write(f"import {module};\n")
    out = subprocess.run([comp.path, "-v", "-c", "-o-", e], capture_output=True, text=True, cwd=work)
    m = re.search(r"^import\s+" + re.escape(module) + r"\s+\((.*?)\)\s*$", out.stdout + out.stderr, re.M)
    return m.group(1) if m else None


def item_phobos(args, comp, mode, work, module):
    path = module_path(comp, module, work)
    if not path:
        return {"status": "missing"}
    wdir, tlog = comp.wrapper(mode, work)
    exe = os.path.join(work, "ut-" + module.replace(".", "_"))
    ver = "-version=StdUnittest" if comp.kind == "dmd" else "-d-version=StdUnittest"
    cmd = [os.path.join(wdir, comp.name_for_dub()), "-unittest", "-main", ver, "-preview=dip1000",
           "-preview=dtorfields", "-preview=fieldwise", "-of=" + exe, "-od=" + work, path]
    b = subprocess.run(cmd, cwd=work, capture_output=True, text=True, timeout=args.build_timeout)
    res = {"compile": parse_time_log(tlog), "source": path}
    if b.returncode:
        res["status"] = "build-failed"
        res["build_log"] = (b.stdout + b.stderr)[-2000:]
        return res
    m = timed([exe], work, timeout=args.timeout)
    res.update(status="ok" if m["rc"] == 0 else "timeout" if m["rc"] is None else "error", run=m)
    return res


def item_dub(args, comp, mode, work, pkg):
    spec = DUB_PACKAGES[pkg]
    home = dub_home_with(work, "dubhome", dict(spec["deps"]))
    src = os.path.join(os.path.expanduser("~/.dub/packages"), pkg, spec["version"], pkg)
    dst = os.path.join(work, pkg)
    shutil.copytree(src, dst, symlinks=True, ignore=shutil.ignore_patterns(".dub", "*.a", "*.o"))
    wdir, tlog = comp.wrapper(mode, work)
    env = dict(os.environ, DUB_HOME=home)
    # `dub test` makes and builds the runner of a library's unittests; the
    # runner it leaves is then measured on its own
    cmd = ["dub", "test", "--skip-registry=all", "--force", "--build=unittest",
           f"--compiler={wdir}/{comp.name_for_dub()}"]
    b = subprocess.run(cmd, cwd=dst, capture_output=True, text=True, env=env, timeout=args.build_timeout)
    res = {"compile": parse_time_log(tlog)}
    exe = next((os.path.join(dst, f) for f in sorted(os.listdir(dst))
                if "test" in f and os.access(os.path.join(dst, f), os.X_OK) and os.path.isfile(os.path.join(dst, f))
                and open(os.path.join(dst, f), "rb").read(4) in MACHO), None)
    if b.returncode or not exe:
        res["status"] = "build-failed" if not exe else "error"
        res["build_log"] = (b.stdout + b.stderr)[-2000:]
        return res
    m = timed([exe], dst, timeout=args.timeout)
    res.update(status="ok" if m["rc"] == 0 else "timeout" if m["rc"] is None else "error", run=m)
    return res


# ---------------------------------------------------------------- driver

def plan(args):
    """[(set, suite, name, function)] of everything selected."""
    items = []
    want = set(args.sets.split(","))
    probs = set(args.problems.split(",")) if args.problems else None
    suites = set(args.suites.split(","))
    for set_name, lst in (("tuning", LANGBENCH_TUNING), ("heldout", LANGBENCH_HELDOUT)):
        if set_name in want and "langbench" in suites:
            for slug in lst:
                if probs is None or slug in probs:
                    items.append((set_name, "langbench", slug, lambda a, c, m, w, s=slug: item_langbench(a, c, m, w, s)))
    if "tuning" in want and "whiteout" in suites and (probs is None or "headless-sim" in probs):
        items.append(("tuning", "whiteout", "headless-sim", item_whiteout))
    if "heldout" in want and "phobos" in suites:
        for mod in PHOBOS_MODULES:
            if probs is None or mod in probs:
                items.append(("heldout", "phobos", mod, lambda a, c, m, w, mod=mod: item_phobos(a, c, m, w, mod)))
    if "heldout" in want and "dub" in suites:
        for pkg in args.dub_packages.split(","):
            if probs is None or pkg in probs:
                items.append(("heldout", "dub", pkg, lambda a, c, m, w, pkg=pkg: item_dub(a, c, m, w, pkg)))
    return items


def geomean(xs):
    xs = [x for x in xs if x and x > 0]
    return math.exp(sum(map(math.log, xs)) / len(xs)) if xs else float("nan")


def summarize(results, metrics):
    """Rows of the table: per item, dmd/ldc ratios; then geomeans per set and mode."""
    lines = []
    by = {}
    for r in results:
        by.setdefault((r["set"], r["suite"], r["name"], r["mode"]), {})[r["compiler"]] = r
    cols = []
    for phase in ("compile", "run"):
        for met in metrics:
            cols.append((phase, met))
    head = "| set | suite | item | mode | " + " | ".join(f"{p} {m} dmd/ldc" for p, m in cols) + " | status |"
    lines.append(head)
    lines.append("|" + "---|" * (5 + len(cols)))
    ratios = {}
    for (st, su, name, mode), cs in sorted(by.items()):
        d, l = cs.get("dmd"), cs.get("ldc")
        cells = []
        for phase, met in cols:
            v = None
            if d and l and d.get("status") == "ok" and l.get("status") == "ok":
                a, b = d.get(phase, {}).get(met), l.get(phase, {}).get(met)
                if a and b:
                    v = a / b
                    ratios.setdefault((st, mode, phase, met), []).append(v)
            cells.append(f"{v:.2f}" if v else "-")
        status = "/".join(f"{k}:{cs[k].get('status')}" for k in ("dmd", "ldc") if k in cs)
        lines.append(f"| {st} | {su} | {name} | {mode} | " + " | ".join(cells) + f" | {status} |")
    lines.append("")
    lines.append("Geometric means of dmd/ldc (below 1: dmd cheaper), over the items both built and ran correctly:")
    lines.append("")
    lines.append("| set | mode | " + " | ".join(f"{p} {m}" for p, m in cols) + " | items |")
    lines.append("|" + "---|" * (3 + len(cols)))
    for st in ("tuning", "heldout"):
        for mode in ("debug", "release"):
            vals = [ratios.get((st, mode, p, m), []) for p, m in cols]
            if not any(vals):
                continue
            n = max(len(v) for v in vals)
            lines.append(f"| {st} | {mode} | " + " | ".join(f"{geomean(v):.3f}" if v else "-" for v in vals) + f" | {n} |")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dmd", required=True, help="the dmd to measure")
    ap.add_argument("--ldc", default="ldc2", help="the ldc2 to compare with")
    ap.add_argument("--sets", default="tuning,heldout")
    ap.add_argument("--suites", default="langbench,whiteout,phobos,dub")
    ap.add_argument("--modes", default="debug,release")
    ap.add_argument("--compilers", default="dmd,ldc", help="which of the two to measure")
    ap.add_argument("--only", "--problems", dest="problems", default="",
                    help="comma-separated item names to restrict to (problems, modules, packages, headless-sim)")
    ap.add_argument("--dub-packages", default=",".join(DEFAULT_DUB_PACKAGES),
                    help="dub packages, of " + ", ".join(DUB_PACKAGES))
    ap.add_argument("--wall", action="store_true", help="also report wall time")
    ap.add_argument("--langbench", default="/Users/peter/langbench/.claude/worktrees/perf",
                    help="langbench tree with problems/*/bench inputs")
    ap.add_argument("--whiteout", default="/Users/peter/.claude/jobs/a61665a5/tmp/wv/whiteout",
                    help="whiteout source tree, with the pinned cydonia beside it")
    ap.add_argument("--timeout", type=float, default=120.0, help="seconds per run")
    ap.add_argument("--build-timeout", type=float, default=1800.0, help="seconds per build")
    ap.add_argument("--out", default=None, help="directory for results.json and results.md")
    ap.add_argument("--keep", action="store_true", help="keep the scratch build directories")
    ap.add_argument("--no-lock", action="store_true", help="do not take the heavy-work lock (already held)")
    args = ap.parse_args()

    if not args.no_lock and os.environ.get("BENCH_LOCK_HELD") != "1":
        env = dict(os.environ, BENCH_LOCK_HELD="1")
        os.execvpe("lockf", ["lockf", LOCK, sys.executable] + sys.argv, env)

    comps = {}
    if "dmd" in args.compilers:
        comps["dmd"] = Compiler(args.dmd, "dmd")
    if "ldc" in args.compilers:
        comps["ldc"] = Compiler(args.ldc, "ldc")
    metrics = ["instr", "cycles"] + (["wall"] if args.wall else [])
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    out = args.out or os.path.join(tempfile.gettempdir(), "cbench-" + stamp)
    os.makedirs(out, exist_ok=True)
    scratch = tempfile.mkdtemp(prefix="cbench-work-")
    results = []
    items = plan(args)
    try:
        for set_name, suite, name, fn in items:
            for mode in args.modes.split(","):
                for cname, comp in comps.items():
                    work = tempfile.mkdtemp(prefix=f"{suite}-", dir=scratch)
                    t0 = time.time()
                    try:
                        res = fn(args, comp, mode, work)
                    except Exception as e:  # a broken item is reported, not fatal
                        res = {"status": "harness-error", "error": repr(e)}
                    res.update(set=set_name, suite=suite, name=name, mode=mode, compiler=cname)
                    results.append(res)
                    run = res.get("run", {})
                    log(f"{set_name:8s} {suite:9s} {name:22s} {mode:7s} {cname}: {res.get('status'):12s} "
                        f"compile {res.get('compile', {}).get('instr', 0) / 1e9:7.2f}G instr  "
                        f"run {run.get('instr', 0) / 1e9:7.2f}G instr {run.get('cycles', 0) / 1e9:7.2f}G cyc  "
                        f"({time.time() - t0:.0f}s)")
                    if not args.keep:
                        shutil.rmtree(work, ignore_errors=True)
                    with open(os.path.join(out, "results.json"), "w") as f:
                        json.dump({"date": stamp, "compilers": {k: c.info() for k, c in comps.items()},
                                   "metrics": metrics, "results": results}, f, indent=1)
    finally:
        if not args.keep:
            shutil.rmtree(scratch, ignore_errors=True)
    table = summarize(results, metrics)
    header = "\n".join(f"- {k}: {c.version} {c.git} ({c.path})" for k, c in comps.items())
    with open(os.path.join(out, "results.md"), "w") as f:
        f.write(f"# dmd vs ldc2, {stamp}\n\n{header}\n\n{table}\n")
    print(header)
    print()
    print(table)
    log(f"results in {out}")


if __name__ == "__main__":
    main()
