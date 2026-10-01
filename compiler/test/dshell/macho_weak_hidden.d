// Template functions are weak definitions that the linker may hide, so calls
// to them within an executable branch directly instead of through a stub.
module test.dshell.macho_weak_hidden;

import dshell;
import std.algorithm : canFind;
import std.process : execute;

int main()
{
    version (OSX) {} else return DISABLED;

    Vars.set("SRC", "$OUTPUT_BASE/wh.d");
    Vars.set("EXE", "$OUTPUT_BASE/wh$EXE");
    std.file.write(Vars.SRC,
        "int twice(T)(T x) { return x * 2; }\n" ~
        "int main() { return twice(21) - 42; }\n");
    run("$DMD -m$MODEL -of=$EXE $SRC");
    run("$EXE");

    const nm = execute(["nm", "-m", Vars.EXE]);
    const dis = execute(["otool", "-tvV", Vars.EXE]);
    if (nm.status || dis.status)
    {
        writeln("nm or otool failed");
        return 1;
    }
    foreach (line; std.string.splitLines(nm.output))
    {
        if (line.canFind("__T5twice") && line.canFind("weak external"))
        {
            writeln("twice is exported: ", line);
            return 1;
        }
    }
    foreach (line; std.string.splitLines(dis.output))
    {
        if (line.canFind("stub for: __D") && line.canFind("__T5twice"))
        {
            writeln("twice is called through a stub: ", line);
            return 1;
        }
    }
    return 0;
}
