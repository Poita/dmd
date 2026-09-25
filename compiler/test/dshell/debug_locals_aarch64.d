/*
Check that lldb reads parameters and locals of AArch64 frames from dmd's DWARF,
including stack-passed parameters and a frame realigned for an over-aligned local.
*/
import dshell;

import std.algorithm : canFind;
import std.process : execute;

int main()
{
    version (OSX)
    {
        version (AArch64) {} else return DISABLED;
    }
    else
        return DISABLED;

    try
    {
        if (execute(["lldb", "--version"]).status)
            return DISABLED;
    }
    catch (Exception)
        return DISABLED;

    immutable src = EXTRA_FILES ~ SEP ~ "debug_locals_aarch64.d";
    immutable exe = OUTPUT_BASE ~ SEP ~ "debug_locals_aarch64";
    run("$DMD -m$MODEL -g -of" ~ exe ~ " " ~ src);

    auto r = execute(["lldb", "--batch",
        "-o", "breakpoint set -f debug_locals_aarch64.d -l 9",
        "-o", "breakpoint set -f debug_locals_aarch64.d -l 19",
        "-o", "run", "-o", "frame variable",
        "-o", "continue", "-o", "frame variable",
        exe]);

    immutable expected = [
        "(int) x = 21", "(double) y = 5", "s = (a = 7, b = 99)",
        "(long) p4 = 4", "(long) p10 = 1010",
        "(long) local = 42", "(double) half = 2.5",
        "(int) n = 40", "(int) m = 41",
    ];
    bool failed;
    foreach (e; expected)
    {
        if (!r.output.canFind(e))
        {
            writeln("missing `", e, "` in lldb output");
            failed = true;
        }
    }
    if (failed)
        writeln(r.output);
    return failed;
}
