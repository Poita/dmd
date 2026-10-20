// When optimized, no function named elim_... in extra-files/bce/elim.d calls
// the array bounds error, each named one_... calls it from one place, and each
// named keep_... from at least one: as they call nothing else, by their calls
module test.dshell.bce_elim;

import dshell;
import std.algorithm : canFind;
import std.conv : to;
import std.file : readText;
import std.regex : matchAll, matchFirst, regex;
import std.stdio : File, writeln;
import std.string : lineSplitter;

int main()
{
    version (AArch64) {} else return DISABLED;

    const src = shellExpand("$EXTRA_FILES/bce/elim.d");
    const exe = OUTPUT_BASE ~ "_elim" ~ EXE;
    const asmLog = OUTPUT_BASE ~ "_elim.asm";
    {
        auto f = File(asmLog, "w");
        run("$DMD -m$MODEL -O -vasm -of" ~ exe ~ " " ~ src, f, stderr);
    }
    run(exe);

    const listing = readText(asmLog);
    int failures;
    string[] seen;
    foreach (m; readText(src).matchAll(regex(`\b(elim|one|keep)_\w+`)))
    {
        const fn = m.hit;
        if (seen.canFind(fn))
            continue;
        seen ~= fn;
        const tag = fn.length.to!string ~ fn;
        bool inFn, found;
        uint checks;
        foreach (line; listing.lineSplitter)
        {
            if (line.length && line[$ - 1] == ':' && !line.canFind(' '))
            {
                inFn = line.canFind(tag);
                found |= inFn;
                continue;
            }
            if (inFn && line.matchFirst(regex(`^[0-9a-f]+:\s+(?:[0-9A-F]{2} ){4}\s*bl\s`)))
                ++checks;
        }
        const ok = m[1] == "elim" ? checks == 0 : m[1] == "one" ? checks == 1 : checks > 0;
        if (!found || !ok)
        {
            writeln(fn, found ? " checks bounds in " ~ checks.to!string ~ " places" : " not found");
            ++failures;
        }
    }
    return failures ? 1 : 0;
}
