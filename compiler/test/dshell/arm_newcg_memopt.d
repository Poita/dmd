// Each program in extra-files/arm_newcg_memopt has a load of each of its
// functions named opt... removed, taken from a store or moved out of a loop by
// the new AArch64 code generator, and runs correctly with and without that.
module test.dshell.arm_newcg_memopt;

import dshell;
import std.algorithm : canFind, map;
import std.array : array;
import std.conv : to;
import std.file : dirEntries, readText, SpanMode;
import std.path : baseName, stripExtension;
import std.regex : matchAll, regex;
import std.stdio : File, writeln;
import std.string : lineSplitter;

int main()
{
    version (AArch64) {} else return DISABLED;

    const dir = shellExpand("$EXTRA_FILES/arm_newcg_memopt");
    auto srcs = dirEntries(dir, "*.d", SpanMode.shallow).map!(e => e.name).array;
    int failures;
    foreach (src; srcs)
    {
        const name = src.baseName.stripExtension;
        const exe = OUTPUT_BASE ~ "_" ~ name ~ EXE;
        const log = OUTPUT_BASE ~ "_" ~ name ~ ".mem";
        {
            auto f = File(log, "w");
            run("$DMD -m$MODEL -O -inline -of" ~ exe ~ " " ~ src, stdout, f,
                ["DMD_NEWCG": "1", "DMD_NEWCG_MEMOPT": "1"]);
        }
        const text = readText(src);
        const memLog = readText(log);
        // the functions named opt..., by the names their mangled names end in
        foreach (m; text.matchAll(regex(`\bopt[A-Z]\w*`)))
        {
            const fn = m.hit;
            const tag = fn.length.to!string ~ fn;
            bool done;
            foreach (line; memLog.lineSplitter)
                if (line.canFind("newcg-memopt:") && line.canFind(tag))
                    done = true;
            if (!done)
            {
                writeln(name, ": ", fn, " has no load optimized");
                ++failures;
            }
        }
        run(exe);
        run("$DMD -m$MODEL -O -inline -of" ~ exe ~ " " ~ src, stdout, stderr,
            ["DMD_NEWCG": "1", "DMD_NEWCG_NOMEMOPT": "1"]);
        run(exe);
    }
    return failures ? 1 : 0;
}
