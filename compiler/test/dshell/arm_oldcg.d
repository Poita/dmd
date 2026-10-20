// Programs compiled and run with the old AArch64 code generator only (with -O,
// which the new one otherwise takes over), each of which exits with 0 when
// its results are right.
module test.dshell.arm_oldcg;

import dshell;
import std.file : dirEntries, SpanMode;
import std.path : baseName, stripExtension;
import std.algorithm : sort;
import std.array : array;

int main()
{
    version (AArch64) {} else return DISABLED;

    auto dir = Vars.EXTRA_FILES ~ "/arm_oldcg";
    auto files = dirEntries(dir, "*.d", SpanMode.shallow).array;
    files.sort!((a, b) => a.name < b.name);
    foreach (f; files)
    {
        foreach (flags; ["-O", "-O -inline -release"])
        {
            const exe = Vars.OUTPUT_BASE ~ "/" ~ f.name.baseName.stripExtension ~ Vars.EXE;
            run("$DMD -m$MODEL " ~ flags ~ " -of" ~ exe ~ " " ~ f.name, stdout, stderr,
                ["DMD_NEWCG": "0"]);
            run(exe);
        }
    }
    return 0;
}
