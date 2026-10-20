#!/usr/bin/env python3
"""Differential fuzzing driver for dmd.

  fuzz.py prog SEEDS   random programs (progfuzz.py) compiled by dmd with each
                       configuration in PROG_CONFIGS, compared with ldc2
  fuzz.py abi SEEDS    calling convention tests (abifuzz.py): objects built by
                       dmd's old and new code generators, without -O, and by
                       the C compiler, linked with each other, compared with
                       the output abifuzz.py computes

SEEDS is a number, a range FROM-TO, or a comma separated list of them.

Each failure is written to WORK/fail/ with the commands that show it, and with
--minimize the program is reduced, keeping the failure, to a .min.d next to it.
A summary line per failing seed goes to stdout; the exit status is 1 when any
seed failed.
"""

import argparse
import concurrent.futures
import os
import shutil
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..'))
DEFAULT_DMD = os.path.join(REPO, 'generated', 'osx', 'release', '64', 'dmd')

# (name, extra environment, flags) of the dmd compilations of each program;
# DMD_NEWCG only matters with -O, where 0 keeps the old code generator
PROG_CONFIGS = [
    ('debug', {}, []),
    ('inline', {}, ['-inline']),
    ('O', {'DMD_NEWCG': '1'}, ['-O']),
    ('O-oldcg', {'DMD_NEWCG': '0'}, ['-O']),
    ('Oi', {'DMD_NEWCG': '1'}, ['-O', '-inline']),
    ('Oir', {'DMD_NEWCG': '1'}, ['-O', '-inline', '-release']),
    ('Oir-oldcg', {'DMD_NEWCG': '0'}, ['-O', '-inline', '-release']),
    ('Oirb', {'DMD_NEWCG': '1'}, ['-O', '-inline', '-release', '-boundscheck=off']),
]

# code generators of the D objects of an ABI test: name -> (environment, flags)
ABI_CODEGENS = {
    'debug': ({}, []),
    'old': ({'DMD_NEWCG': '0'}, ['-O']),
    'new': ({'DMD_NEWCG': '1'}, ['-O']),
    'newi': ({'DMD_NEWCG': '1'}, ['-O', '-inline', '-release']),
}

RUN_TIMEOUT = 20
COMPILE_TIMEOUT = 120


def parse_seeds(text):
    seeds = []
    for part in text.split(','):
        if '-' in part:
            a, b = part.split('-')
            seeds.extend(range(int(a), int(b) + 1))
        else:
            seeds.append(int(part))
    return seeds


def run(cmd, env=None, timeout=COMPILE_TIMEOUT, cwd=None):
    """Runs cmd; returns (status, output), status None on timeout"""
    e = dict(os.environ)
    if env:
        e.update(env)
    try:
        p = subprocess.run(cmd, env=e, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           timeout=timeout)
        return p.returncode, p.stdout.decode('utf-8', 'replace')
    except subprocess.TimeoutExpired:
        return None, ''


def envtext(env):
    return ' '.join('%s=%s' % kv for kv in sorted(env.items()))


# ------------------------------------------------------------------ programs

class ProgCase:
    """Compiling and running one program with the reference and the dmd configurations"""

    def __init__(self, args, d):
        self.args = args
        self.dir = d

    def ref(self, src):
        exe = os.path.join(self.dir, 'ref')
        st, out = run([self.args.ldc, '-O1', '-of=' + exe, src], cwd=self.dir)
        if st != 0:
            return None, 'reference compile failed: ' + out[:2000]
        st, out = run([exe], timeout=RUN_TIMEOUT, cwd=self.dir)
        if st != 0:
            return None, 'reference run failed (%s)' % st
        return out, None

    def dmd(self, src, cfg):
        name, env, flags = cfg
        exe = os.path.join(self.dir, 'dmd-' + name)
        st, out = run([self.args.dmd] + flags + ['-of' + exe, src], env=env, cwd=self.dir)
        if st != 0:
            return 'compile failed (%s): %s' % (st, out[:2000])
        st, out = run([exe], timeout=RUN_TIMEOUT, cwd=self.dir)
        if st is None:
            return 'timed out'
        if st != 0:
            return 'exit %d: %s' % (st, out[-2000:])
        return out

    def failures(self, src, configs):
        """[(config, ref output, dmd output)] of the configurations that differ"""
        ref, err = self.ref(src)
        if ref is None:
            return None, err
        bad = []
        for cfg in configs:
            out = self.dmd(src, cfg)
            if out != ref:
                bad.append((cfg, ref, out))
        return bad, None


def first_diff(a, b):
    al, bl = a.splitlines(), b.splitlines()
    for i, (x, y) in enumerate(zip(al, bl)):
        if x != y:
            return 'line %d: expected %r, got %r' % (i + 1, x, y)
    return 'expected %d lines, got %d: %r' % (len(al), len(bl), b[-300:])


def reduce_lines(lines, interesting, log):
    """Removes lines, and brace delimited blocks, while interesting(lines) holds"""
    def blocks(ls):
        # (start, end) of each line with a lone { and its matching }
        out, stack = [], []
        for i, l in enumerate(ls):
            s = l.strip()
            if s == '{':
                stack.append(i)
            elif s == '}' and stack:
                st = stack.pop()
                out.append((max(0, st - 1), i + 1))   # include the line before (if, for, ...)
        return sorted(out, key=lambda b: b[0] - b[1])   # largest first

    changed = True
    while changed:
        changed = False
        for b0, b1 in blocks(lines):
            if b1 > len(lines):
                continue
            cand = lines[:b0] + lines[b1:]
            if interesting(cand):
                lines = cand
                changed = True
                log('  block -> %d lines' % len(lines))
                break
        if changed:
            continue
        size = max(1, len(lines) // 4)
        while size >= 1:
            i = 0
            while i < len(lines):
                cand = lines[:i] + lines[i + size:]
                if interesting(cand):
                    lines = cand
                    changed = True
                else:
                    i += size
            log('  chunk %d -> %d lines' % (size, len(lines)))
            size //= 2
    return lines


def minimize_prog(args, src, cfg, outpath, log):
    """Reduces the program at src while cfg's output still differs from the reference
    and the unoptimized dmd build still agrees with the reference"""
    work = tempfile.mkdtemp(prefix='fzmin', dir=args.work)
    case = ProgCase(args, work)
    debug = PROG_CONFIGS[0]

    def interesting(lines):
        path = os.path.join(work, 'm.d')
        with open(path, 'w') as f:
            f.write('\n'.join(lines) + '\n')
        ref, err = case.ref(path)
        if ref is None:
            return False
        out = case.dmd(path, cfg)
        if out == ref or out.startswith('compile failed') or out == 'timed out':
            return False
        if cfg[0] != 'debug' and case.dmd(path, debug) != ref:
            return False
        return True

    lines = open(src).read().splitlines()
    if not interesting(lines):
        log('  not reproducible for minimization')
        return
    lines = reduce_lines(lines, interesting, log)
    with open(outpath, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    shutil.rmtree(work, ignore_errors=True)


def prog_seed(args, seed):
    d = tempfile.mkdtemp(prefix='fzp%d-' % seed, dir=args.work)
    src = os.path.join(d, 'fz%d.d' % seed)
    st, text = run([sys.executable, os.path.join(HERE, 'progfuzz.py'), str(seed), '--size', args.size])
    with open(src, 'w') as f:
        f.write(text)
    case = ProgCase(args, d)
    configs = [c for c in PROG_CONFIGS if not args.configs or c[0] in args.configs]
    bad, err = case.failures(src, configs)
    msgs = []
    if bad is None:
        msgs.append('seed %d: skipped, %s' % (seed, err.splitlines()[0] if err else ''))
        shutil.rmtree(d, ignore_errors=True)
        return msgs, False
    if bad:
        faildir = os.path.join(args.work, 'fail')
        os.makedirs(faildir, exist_ok=True)
        for cfg, ref, out in bad:
            name, env, flags = cfg
            base = os.path.join(faildir, 'prog-%d-%s' % (seed, name))
            shutil.copy(src, base + '.d')
            with open(base + '.txt', 'w') as f:
                f.write('%s %s %s %s.d\n' % (envtext(env), args.dmd, ' '.join(flags), base))
                f.write('reference: %s -O1 %s.d\n' % (args.ldc, base))
                f.write(first_diff(ref, out) + '\n')
            msgs.append('seed %d: %s differs: %s' % (seed, name, first_diff(ref, out)[:300]))
        if args.minimize:
            cfg = bad[0][0]
            log = (lambda m: print(m, file=sys.stderr)) if args.verbose else (lambda m: None)
            minimize_prog(args, src, cfg, os.path.join(faildir, 'prog-%d-%s.min.d' % (seed, cfg[0])), log)
    shutil.rmtree(d, ignore_errors=True)
    return msgs, bool(bad)


# ------------------------------------------------------------------ ABI

def abi_seed(args, seed):
    d = tempfile.mkdtemp(prefix='fza%d-' % seed, dir=args.work)
    st, out = run([sys.executable, os.path.join(HERE, 'abifuzz.py'), str(seed), d])
    if st != 0:
        return ['seed %d: generator failed: %s' % (seed, out[:500])], True
    msgs = []
    objs = {}
    for name, (env, flags) in ABI_CODEGENS.items():
        for mod in ('callee', 'caller'):
            obj = os.path.join(d, '%s-%s.o' % (mod, name))
            st, out = run([args.dmd, '-betterC', '-c'] + flags + ['-of' + obj, '-I' + d, os.path.join(d, mod + '.d')],
                          env=env, cwd=d)
            if st != 0:
                msgs.append('seed %d: %s %s compile failed: %s' % (seed, mod, name, out[:500]))
                continue
            objs[(mod, name)] = obj
    for mod in ('callee', 'caller'):
        obj = os.path.join(d, 'c%s.o' % mod)
        st, out = run([args.cc, '-O1', '-c', '-o', obj, os.path.join(d, mod + '.c')], cwd=d)
        if st != 0:
            msgs.append('seed %d: C %s compile failed: %s' % (seed, mod, out[:500]))
            shutil.rmtree(d, ignore_errors=True)
            return msgs, True
        objs[(mod, 'c')] = obj
    expect_d = open(os.path.join(d, 'expect_d.txt')).read()
    expect_c = open(os.path.join(d, 'expect_c.txt')).read()
    links = []
    for callee in ABI_CODEGENS:
        for caller in ABI_CODEGENS:
            links.append(('%s->%s' % (caller, callee), [('caller', caller), ('callee', callee), ('callee', 'c')], expect_d))
        links.append(('C->%s' % callee, [('caller', 'c'), ('callee', callee)], expect_c))
    failed = False
    for label, parts, expect in links:
        if any(p not in objs for p in parts):
            failed = True
            continue
        exe = os.path.join(d, 't')
        # dmd links, so that druntime provides the helpers -betterC code can still call
        st, out = run([args.dmd, '-of' + exe] + [objs[p] for p in parts], cwd=d)
        if st != 0:
            msgs.append('seed %d: %s link failed: %s' % (seed, label, out[:500]))
            failed = True
            continue
        st, out = run([exe], timeout=RUN_TIMEOUT, cwd=d)
        if st != 0 or out != expect:
            failed = True
            el, ol = expect.splitlines(), out.splitlines()
            wrong = [e.split()[0] for e, o in zip(el, ol) if e != o]
            msgs.append('seed %d: %s (caller->callee) wrong: %s%s' % (
                seed, label, ' '.join(wrong[:12]), '' if st == 0 else ' exit %s' % st))
    if failed:
        faildir = os.path.join(args.work, 'fail', 'abi-%d' % seed)
        shutil.rmtree(faildir, ignore_errors=True)
        shutil.copytree(d, faildir, ignore=shutil.ignore_patterns('*.o', 't'))
    shutil.rmtree(d, ignore_errors=True)
    return msgs, failed


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('mode', choices=['prog', 'abi'])
    ap.add_argument('seeds')
    ap.add_argument('--dmd', default=os.environ.get('FUZZ_DMD', DEFAULT_DMD))
    ap.add_argument('--ldc', default=os.environ.get('FUZZ_LDC', 'ldc2'))
    ap.add_argument('--cc', default=os.environ.get('FUZZ_CC', 'cc'))
    ap.add_argument('--work', default=os.path.join(tempfile.gettempdir(), 'dmd-fuzz'))
    ap.add_argument('--jobs', '-j', type=int, default=2)
    ap.add_argument('--size', choices=['small', 'medium', 'large'], default='medium')
    ap.add_argument('--configs', help='comma separated names of the program configurations to run')
    ap.add_argument('--minimize', action='store_true', help='reduce failing programs')
    ap.add_argument('--verbose', '-v', action='store_true')
    args = ap.parse_args()
    args.configs = args.configs.split(',') if args.configs else None
    args.work = os.path.abspath(args.work)
    os.makedirs(args.work, exist_ok=True)
    seeds = parse_seeds(args.seeds)
    fn = prog_seed if args.mode == 'prog' else abi_seed
    t0 = time.time()
    nfail = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as ex:
        futs = {ex.submit(fn, args, s): s for s in seeds}
        for fut in concurrent.futures.as_completed(futs):
            msgs, failed = fut.result()
            nfail += failed
            for m in msgs:
                print(m, flush=True)
    print('%s: %d seeds, %d failing, %.0fs' % (args.mode, len(seeds), nfail, time.time() - t0), flush=True)
    sys.exit(1 if nfail else 0)


if __name__ == '__main__':
    main()
