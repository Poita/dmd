// A function the back end can inline, after optimizing it to an expression,
// is inlined when each function goes in a library member of its own.
module test.dshell.lib_backend_inline;

import dshell;
import std.algorithm : canFind;
import std.process : execute;

int main()
{
    version (OSX) {} else return DISABLED;

    Vars.set("SRC", "$OUTPUT_BASE/bi.d");
    Vars.set("LIB", "$OUTPUT_BASE/bi$LIBEXT");
    std.file.write(Vars.SRC,
        "private ulong readU64(const(ubyte)* p)\n" ~
        "{\n" ~
        "    ulong v;\n" ~
        "    foreach (i; 0 .. 8)\n" ~
        "        v |= cast(ulong) p[i] << (8 * i);\n" ~
        "    return v;\n" ~
        "}\n" ~
        "ulong use(const(ubyte)* p) { return readU64(p) ^ readU64(p + 8); }\n");
    run("$DMD -m$MODEL -O -inline -release -lib -of=$LIB $SRC");

    // the members holding use() do not call readU64()
    const dir = Vars.OUTPUT_BASE ~ "/members";
    std.file.mkdirRecurse(dir);
    const ar = execute(["ar", "x", Vars.LIB], null, std.process.Config.none, size_t.max, dir);
    if (ar.status)
        return 1;
    foreach (name; std.file.dirEntries(dir, "*.o", std.file.SpanMode.shallow))
    {
        const nm = execute(["nm", name]);
        if (nm.output.canFind("T __D2bi3useFPxhZm") && nm.output.canFind("U __D2bi7readU64FPxhZm"))
        {
            writeln("use() calls readU64() in ", name);
            return 1;
        }
    }
    return 0;
}
