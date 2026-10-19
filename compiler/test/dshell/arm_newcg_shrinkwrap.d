// Each program in extra-files/arm_newcg_shrinkwrap is generated entirely by the
// new AArch64 code generator, which sets up the frame and saves the callee saved
// registers of each of its functions named wrapped_... only on the paths that need
// them, and of each named framed_... on entry, and the program runs correctly,
// exceptions and backtraces going through the frames set up late.
module test.dshell.arm_newcg_shrinkwrap;

import dshell;
import std.algorithm : canFind, map;
import std.array : array, split;
import std.conv : text;
import std.file : dirEntries, readText, SpanMode;
import std.path : baseName, stripExtension;
import std.regex : matchFirst, regex;
import std.stdio : File, writeln;
import std.string : lineSplitter;

int main()
{
    version (AArch64) {} else return DISABLED;

    const dir = shellExpand("$EXTRA_FILES/arm_newcg_shrinkwrap");
    auto srcs = dirEntries(dir, "*.d", SpanMode.shallow).map!(e => e.name).array;
    int failures;
    foreach (src; srcs)
    {
        const name = src.baseName.stripExtension;
        const exe = OUTPUT_BASE ~ "_" ~ name ~ EXE;
        const log = OUTPUT_BASE ~ "_" ~ name ~ ".sw";
        // the module's own functions, as their mangled names start
        const mangled = "_D" ~ text(name.length, name);
        {
            auto f = File(log, "w");
            run("$DMD -m$MODEL -O -inline -release -check=assert=on -of" ~ exe ~ " " ~ src, stdout, f,
                ["DMD_NEWCG": "1", "DMD_NEWCG_WHY": "1", "DMD_NEWCG_SWLOG": "1"]);
        }
        bool[string] wrapped;
        foreach (line; readText(log).lineSplitter)
        {
            if (line.canFind("newcg-why:") && line.canFind(mangled))
            {
                writeln(name, ": ", line);
                ++failures;
            }
            if (line.canFind("newcg-shrinkwrap:"))
                wrapped[line.split[$ - 1]] = true;
        }
        // the functions named wrapped_... or framed_..., from the program's source
        size_t checked;
        foreach (m; readText(src).lineSplitter)
        {
            auto c = m.matchFirst(regex(`\b((wrapped|framed)_\w+)\(`));
            if (!c || m.canFind(";"))
                continue;
            const fn = c[1];
            const sym = mangled ~ text(fn.length, fn);
            bool found;
            foreach (w, _; wrapped)
                found |= w.canFind(sym);
            const want = c[2] == "wrapped";
            ++checked;
            if (found != want)
            {
                writeln(name, ": ", fn, want ? " is not shrink-wrapped" : " is shrink-wrapped");
                ++failures;
            }
        }
        if (!checked)
        {
            writeln(name, ": no function named wrapped_... or framed_...");
            ++failures;
        }
        run(exe);
    }
    return failures ? 1 : 0;
}
