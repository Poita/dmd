/*
Check that the DWARF locations of optimized AArch64 code do not put a
variable live across a call in a register the call may change: a parameter
kept past a call is described where it is kept rather than where it was
passed, and a variable kept in memory is described by its stack slot.
*/
import dshell;

import std.algorithm : canFind, startsWith;
import std.conv : to;
import std.process : execute;
import std.regex : matchFirst, regex;
import std.string : lineSplitter, strip;

int main()
{
    version (OSX)
    {
        version (AArch64) {} else return DISABLED;
    }
    else
        return DISABLED;

    string dwarfdump;
    foreach (tool; ["dwarfdump", "llvm-dwarfdump"])
    {
        try
        {
            if (execute([tool, "--version"]).status == 0)
            {
                dwarfdump = tool;
                break;
            }
        }
        catch (Exception) {}
    }
    if (!dwarfdump)
        return DISABLED;

    immutable src = EXTRA_FILES ~ SEP ~ "debug_locations_opt.d";
    immutable obj = OUTPUT_BASE ~ SEP ~ "debug_locations_opt.o";
    run("$DMD -m$MODEL -g -O -c -of" ~ obj ~ " " ~ src);

    auto r = execute([dwarfdump, "--debug-info", obj]);
    if (r.status)
    {
        writeln(r.output);
        return 1;
    }

    // the variables of keepParams and spills, all live across their call of touch
    immutable checked = ["a", "b", "n", "v0", "v1", "v2", "v3", "v4", "v5", "v6",
        "v7", "v8", "v9", "v10", "v11", "v12", "v13"];
    auto nameRe = regex(`DW_AT_name\s+\("([^"]*)"\)`);
    auto regRe = regex(`DW_AT_location\s+\(DW_OP_reg(\d+)\b`);
    string name;
    bool failed;
    size_t seen;
    foreach (line; r.output.lineSplitter)
    {
        if (auto m = line.matchFirst(nameRe))
            name = m[1];
        else if (line.strip.startsWith("DW_AT_location"))
        {
            if (!checked.canFind(name))
                continue;
            ++seen;
            if (auto m = line.matchFirst(regRe))
            {
                // x0 .. x18 are not preserved across calls
                if (m[1].to!int <= 18)
                {
                    writeln("`", name, "` is located in a register a call changes: ", line.strip);
                    failed = true;
                }
            }
        }
    }
    if (seen != checked.length)
    {
        writeln("found ", seen, " of ", checked.length, " variables");
        failed = true;
    }
    if (failed)
        writeln(r.output);
    return failed;
}
