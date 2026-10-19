// Each program in extra-files/arm_newcg_regalloc runs correctly when made by the new
// AArch64 code generator, and the register allocation of each of its functions named
// copies<N>_... leaves at most N copies from one register to another, and of each
// named loads<N>_... at most N loads of registers kept on the stack.
module test.dshell.arm_newcg_regalloc;

import dshell;
import std.algorithm : canFind, findSplitAfter, map;
import std.array : array, split;
import std.conv : to;
import std.file : dirEntries, readText, SpanMode;
import std.path : baseName, stripExtension;
import std.stdio : File, writeln;
import std.string : lineSplitter;

int main()
{
    version (AArch64) {} else return DISABLED;

    const dir = shellExpand("$EXTRA_FILES/arm_newcg_regalloc");
    auto srcs = dirEntries(dir, "*.d", SpanMode.shallow).map!(e => e.name).array;
    int failures;
    foreach (src; srcs)
    {
        const name = src.baseName.stripExtension;
        const exe = OUTPUT_BASE ~ "_" ~ name ~ EXE;
        const log = OUTPUT_BASE ~ "_" ~ name ~ ".ra";
        {
            auto f = File(log, "w");
            run("$DMD -m$MODEL -O -inline -release -of" ~ exe ~ " " ~ src, stdout, f,
                ["DMD_NEWCG": "1", "DMD_NEWCG_RASTATS": "1"]);
        }
        size_t checked;
        // newcg-ra: copies <n> <weighted> loads <n> <weighted> stores <n> <weighted> <mangled name>
        foreach (line; readText(log).lineSplitter)
        {
            if (!line.canFind("newcg-ra:"))
                continue;
            const words = line.split;
            const fn = words[$ - 1];
            if (!fn.canFind("_D" ~ to!string(name.length) ~ name))
                continue;
            foreach (k, what; ["copies", "loads"])
            {
                auto after = fn.findSplitAfter(what);
                if (!after)
                    continue;
                size_t digits;
                while (digits < after[1].length && after[1][digits] >= '0' && after[1][digits] <= '9')
                    ++digits;
                if (!digits || digits >= after[1].length || after[1][digits] != '_')
                    continue;
                const allowed = after[1][0 .. digits].to!uint;
                const count = words[2 + 3 * k].to!uint;
                ++checked;
                if (count > allowed)
                {
                    writeln(name, ": ", count, " ", what, ", at most ", allowed, " expected: ", line);
                    ++failures;
                }
            }
        }
        if (!checked)
        {
            writeln(name, ": no function named copies<N>_... or loads<N>_... reported");
            ++failures;
        }
        run(exe);
    }
    return failures ? 1 : 0;
}
