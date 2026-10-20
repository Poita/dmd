# Compiler benchmark harness

`bench.py` measures a dmd against ldc2 on a fixed set of real programs: what
compiling them costs and what running the result costs, in a debug and a
release build, and reports dmd/ldc2 ratios for a tuning set and a held-out set.

```
./bench.py --dmd /path/to/dmd [--ldc ldc2] [--wall] [--out DIR]
           [--sets tuning,heldout] [--suites langbench,whiteout,phobos,dub]
           [--modes debug,release] [--compilers dmd,ldc] [--only NAMES]
           [--dub-packages dyaml,emsi_containers,mir-algorithm]
```

It writes `results.json` (every measurement, the compilers' versions and
paths) and `results.md` (the table) to `--out`, default
`$TMPDIR/cbench-<date>`, and prints the table. A full run takes about an hour.

Only the Python standard library is used. It runs on macOS only, as the counts
come from `/usr/bin/time -l`.

## Honest measurement

* **Heavy-work lock.** The harness re-runs itself under
  `lockf /tmp/omega-heavy.lock`, so no other build or measurement shares the
  machine with it. `--no-lock` skips that, for trying the harness out, not for
  numbers.
* **Counts, not times.** Instructions retired and cycles of each measured
  process are the primary metrics: they are far less sensitive to other load
  than wall time. `--wall` adds wall time.
* **Compile cost** is the sum over every compiler process a build starts,
  each run through a wrapper that appends its `/usr/bin/time -l` report to a
  log. The counts of a process exclude its children, so the linker (which both
  compilers run as a child) is not counted, and dmd is given `-j=1`, as its
  parallel workers are forked children. dub's own work is not counted.
* **Run cost** is the counts of the program on its input. Every langbench
  output is checked against the expected output (or the problem's verifier);
  a wrong output, crash or timeout is reported as such and the item leaves the
  means. Unittest runners must exit 0.
* **Same flags for both compilers.** The wrapper removes the optimization,
  inlining, bounds-check and debug-info flags a build script or dub passes and
  puts in those of the mode:

  | mode    | dmd                     | ldc2            |
  |---------|-------------------------|-----------------|
  | debug   | `-g`                    | `-g`            |
  | release | `-O -release -inline`   | `-O3 -release`  |

* **Ratios** are dmd/ldc2 per item, summarized by geometric means over the
  items both compilers built and ran correctly. Below 1 means dmd is cheaper.

## The sets

The split was fixed before anything was measured with this harness, and must
not be changed to suit results.

**langbench** (`--langbench`, a langbench tree with `problems/*/bench`
inputs): the D implementation of each problem is taken from `impls/`, else
`projects/`, else `runs-large/`, and run on the first benchmark input in name
order. The 40 problems with benchmark inputs are split by this rule: the
**tuning set** is the 20 problems of langbench's `d-fast` suite, the inputs
compiler changes have already been profiled and tuned on; the **held-out set**
is the other 20, which no change has been tuned on.

| tuning | held-out |
|--------|----------|
| chess-perft datalog gitrepo jq kvstore langvm linalg ordered-map regex rrule rubiks sat scheme sitegen template textbuffer toml typeinfer typeset webhooks | bigint buildsys cardgame chip8 commonmark depresolve diff fulltext inflate json jsonschema mime minisql orderbook protowire qrcode softfloat spreadsheet sqlitefile svgraster |

**whiteout** (tuning): the whiteout headless simulation (`--whiteout`, with
the pinned cydonia beside it), built by dub with `-b plain --config=headless`;
the compile cost is the whole build, the run cost is
`--demo-battle --perf --units 512 --ticks 400 --seed 7`.

**phobos** (held-out): the unittests of `std.algorithm.sorting`, `std.array`,
`std.bigint`, `std.conv`, `std.datetime.date`, `std.json`,
`std.math.exponential`, `std.string` and `std.utf`, each compiled with
`-unittest -main -version=StdUnittest` from the module source the compiler
itself imports, and run. Each compiler compiles its own Phobos, so the two
sides are not the same source; the ratios track a dmd over time better than
they compare it with ldc2.

**dub** (held-out): `dub test` of packages from the local dub cache (no
network): `dyaml` 0.9.2 and `emsi_containers` 0.9.0 by default, and
`mir-algorithm` 3.22.4 on request; the compile cost is the build of the test
runner, the run cost that runner.

## Comparing two dmds

Measure each with `--compilers dmd` (or both with the same ldc2) and compare
the `results.json` files; instruction counts of the same program and input
repeat to well under 1%, cycles to a few percent.
