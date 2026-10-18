// Each program in extra-files/arm_newcg_coverage is generated entirely by the
// new AArch64 code generator, with no function of its own module falling back to
// the old one, and runs correctly.
module test.dshell.arm_newcg_coverage;

import dshell;
import std.algorithm : canFind, filter, map;
import std.array : array;
import std.file : dirEntries, readText, SpanMode;
import std.path : baseName, stripExtension;
import std.stdio : File, writeln;
import std.string : lineSplitter;

int main()
{
    version (AArch64) {} else return DISABLED;

    const dir = shellExpand("$EXTRA_FILES/arm_newcg_coverage");
    auto srcs = dirEntries(dir, "*.d", SpanMode.shallow).map!(e => e.name).array;
    int failures;
    foreach (src; srcs)
    {
        const name = src.baseName.stripExtension;
        const exe = OUTPUT_BASE ~ "_" ~ name ~ EXE;
        const log = OUTPUT_BASE ~ "_" ~ name ~ ".why";
        // the module's own functions, as their mangled names start
        import std.conv : text;
        const mangled = text(name.length, name);
        {
            auto f = File(log, "w");
            run("$DMD -m$MODEL -O -inline -release -of" ~ exe ~ " " ~ src, stdout, f,
                ["DMD_NEWCG": "1", "DMD_NEWCG_WHY": "1"]);
        }
        foreach (line; readText(log).lineSplitter)
            if (line.canFind("newcg-why:") && line.canFind("_D" ~ mangled))
            {
                writeln(name, ": ", line);
                ++failures;
            }
        run(exe);
    }
    return failures ? 1 : 0;
}
