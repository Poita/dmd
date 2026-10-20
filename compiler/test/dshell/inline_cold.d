// Calls on paths that end in a throw, in an assert's message or in a catch handler
// are inlined only when the function is about as cheap as the call; the same
// functions called on the paths that run normally are inlined.
module test.dshell.inline_cold;

import dshell;
import std.algorithm : canFind, startsWith;
import std.process : execute;
import std.string : lineSplitter, strip;

int main()
{
    version (Posix) {} else return DISABLED;

    Vars.set("SRC", "$EXTRA_FILES/inline_cold/cold.d");
    Vars.set("OBJ", "$OUTPUT_BASE/cold$OBJ");
    const r = execute([Vars.DMD, "-m" ~ Vars.MODEL, "-O", "-inline", "-v", "-c",
                       "-of=" ~ Vars.OBJ, Vars.SRC]);
    if (r.status)
    {
        writeln(r.output);
        return 1;
    }

    // "inlined   callee =>" is followed by a line naming the caller
    string[] pairs;
    string callee;
    foreach (line; r.output.lineSplitter)
    {
        if (line.startsWith("inlined "))
            callee = line["inlined ".length .. $].strip;
        else if (callee.length)
        {
            pairs ~= callee ~ " " ~ line.strip;
            callee = null;
        }
    }

    int failures;
    void expect(string pair, bool inlined)
    {
        if (pairs.canFind(pair) != inlined)
        {
            writefln("%s: expected %sinlined", pair, inlined ? "" : "not ");
            ++failures;
        }
    }

    expect("cold.mix => cold.hotLoop", true);
    expect("cold.mix => cold.hot", true);
    expect("cold.name => cold.hot", true);
    expect("cold.mix => cold.throwBranch", false);
    expect("cold.name => cold.assertMessage", false);
    expect("cold.mix => cold.caught", false);
    expect("cold.mix => cold.noReturnElse", false);
    if (failures)
        writeln(pairs);
    return failures != 0;
}
