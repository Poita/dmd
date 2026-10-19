// Each program in extra-files/arm_newcg_loopvec has the loops of its functions
// named vec... vectorized by the new AArch64 code generator, those of its functions
// named novec... not, and runs correctly; and runs correctly with loop vectorization
// turned off.
module test.dshell.arm_newcg_loopvec;

import dshell;
import std.algorithm : canFind, map;
import std.array : array;
import std.file : dirEntries, readText, SpanMode;
import std.path : baseName, stripExtension;
import std.regex : matchAll, regex;
import std.stdio : File, writeln;
import std.string : lineSplitter;

int main()
{
    version (AArch64) {} else return DISABLED;

    const dir = shellExpand("$EXTRA_FILES/arm_newcg_loopvec");
    auto srcs = dirEntries(dir, "*.d", SpanMode.shallow).map!(e => e.name).array;
    int failures;
    foreach (src; srcs)
    {
        const name = src.baseName.stripExtension;
        const exe = OUTPUT_BASE ~ "_" ~ name ~ EXE;
        const log = OUTPUT_BASE ~ "_" ~ name ~ ".vec";
        {
            auto f = File(log, "w");
            run("$DMD -m$MODEL -O -inline -release -check=assert=on -of" ~ exe ~ " " ~ src, stdout, f,
                ["DMD_NEWCG": "1", "DMD_NEWCG_LOOPVEC": "1"]);
        }
        const text = readText(src);
        const vecLog = readText(log);
        // the functions named vec... and novec..., by the names their mangled names end in
        foreach (m; text.matchAll(regex(`\b(no)?vec[A-Z]\w*`)))
        {
            const fn = m.hit;
            import std.conv : to;
            const tag = fn.length.to!string ~ fn;
            bool vectorized;
            foreach (line; vecLog.lineSplitter)
                if (line.canFind("newcg-loopvec: vectorized") && line.canFind(tag))
                    vectorized = true;
            if (vectorized != !fn.canFind("novec"))
            {
                writeln(name, ": ", fn, vectorized ? " vectorized" : " not vectorized");
                ++failures;
            }
        }
        run(exe);
        run("$DMD -m$MODEL -O -inline -release -check=assert=on -of" ~ exe ~ " " ~ src, stdout, stderr,
            ["DMD_NEWCG": "1", "DMD_NEWCG_NOLOOPVEC": "1"]);
        run(exe);
    }
    return failures ? 1 : 0;
}
