// A function of an imported module marked to be inlined by a pragma(inline, true)
// in its body, possibly in a conditional, is inlined without -inline, while one
// not marked is called.
module test.dshell.pragmainline_imported;

import dshell;
import std.algorithm : canFind;
import std.process : execute;

int main()
{
    version (OSX) {} else return DISABLED;

    Vars.set("IMP", "$OUTPUT_BASE/pi_imp.d");
    Vars.set("SRC", "$OUTPUT_BASE/pi.d");
    Vars.set("OBJ", "$OUTPUT_BASE/pi$OBJ");
    std.file.write(Vars.IMP,
        "module pi_imp;\n" ~
        "int bodyPragma(int x) { pragma(inline, true); return x + 1; }\n" ~
        "int nestedPragma(int x) { { version (all) { pragma(inline, true); } } return x + 2; }\n" ~
        "int staticIfPragma(int x) { static if (true) pragma(inline, true); return x + 3; }\n" ~
        "int notMarked(int x) { return x + 4; }\n");
    std.file.write(Vars.SRC,
        "import pi_imp;\n" ~
        "pragma(inline, true) int twice(int x) { return x * 2; }\n" ~
        "int use(int x) { return twice(x) + bodyPragma(x) + nestedPragma(x) + staticIfPragma(x) + notMarked(x); }\n");
    foreach (j; ["-j=1", "-j=2"])
    {
        run("$DMD -m$MODEL " ~ j ~ " -c -I$OUTPUT_BASE -of=$OBJ $SRC");
        const nm = execute(["nm", Vars.OBJ]);
        if (nm.status)
            return 1;
        foreach (name; ["bodyPragma", "nestedPragma", "staticIfPragma"])
            if (nm.output.canFind(name))
            {
                writeln(name, " is called with ", j, ":\n", nm.output);
                return 1;
            }
        if (!nm.output.canFind("notMarked"))
        {
            writeln("notMarked is not called with ", j, ":\n", nm.output);
            return 1;
        }
    }
    return 0;
}
