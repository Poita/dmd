// A function too costly to inline outside loops is inlined where its constant
// arguments decide its conditions so that what is left is cheap; not where they
// do not decide them, nor where the parameter is changed before it is tested.
module test.dshell.inline_constarg;

import dshell;
import std.algorithm : canFind, startsWith;
import std.process : execute;
import std.string : lineSplitter, strip;

int main()
{
    version (Posix) {} else return DISABLED;

    Vars.set("SRC", "$EXTRA_FILES/inline_constarg/constarg.d");
    Vars.set("OBJ", "$OUTPUT_BASE/constarg$OBJ");
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

    expect("constarg.lookup => constarg.unchecked", true);
    expect("constarg.lookup => constarg.either", false);
    expect("constarg.changed => constarg.callsChanged", false);
    if (failures)
        writeln(pairs);
    return failures != 0;
}
