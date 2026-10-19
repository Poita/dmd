// Nested functions are left out of the object only when calls were inlined into
// the function enclosing them: a function whose every call is inlined is left
// out, while the nested functions of one nothing was inlined into are compiled
// without looking for the unused ones.
module test.dshell.nested_unused_noinline;

import dshell;
import std.algorithm : canFind;
import std.process : execute;

int main()
{
    version (OSX) {} else return DISABLED;

    Vars.set("SRC", "$OUTPUT_BASE/nu.d");
    Vars.set("OBJ", "$OUTPUT_BASE/nu$OBJ");
    std.file.write(Vars.SRC,
        "int inlinedInto(int n)\n" ~
        "{\n" ~
        "    int k = n * 3;\n" ~
        "    pragma(inline, true) int everyCallInlined(int i) { return i + k; }\n" ~
        "    return everyCallInlined(n) + everyCallInlined(n + 1);\n" ~
        "}\n" ~
        "int nothingInlined(int n)\n" ~
        "{\n" ~
        "    int k = n * 3;\n" ~
        "    int neverCalled(int i) { return i + k; }\n" ~
        "    return k;\n" ~
        "}\n");
    foreach (flags; ["-g -debug", "-g", ""])
    {
        run("$DMD -m$MODEL " ~ flags ~ " -c -of=$OBJ $SRC");
        const nm = execute(["nm", Vars.OBJ]);
        if (nm.status)
            return 1;
        if (nm.output.canFind("everyCallInlined"))
        {
            writeln("everyCallInlined is compiled with '", flags, "':\n", nm.output);
            return 1;
        }
        if (!nm.output.canFind("neverCalled"))
        {
            writeln("neverCalled is not compiled with '", flags, "':\n", nm.output);
            return 1;
        }
    }
    return 0;
}
