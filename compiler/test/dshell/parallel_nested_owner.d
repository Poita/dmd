// A template instance nested in a function of a module another worker compiles
// (here one the inliner analyzed: a.first's sort) is left to that worker, which
// generates the function, its statics and the instance once.
module test.dshell.parallel_nested_owner;

import dshell;
import std.algorithm : canFind;

int main()
{
    version (Posix) {} else return DISABLED;

    Vars.set("SRC", "$EXTRA_FILES/parallel_nested_owner");
    Vars.set("OBJ", "$OUTPUT_BASE/ab$OBJ");
    Vars.set("LOG", "$OUTPUT_BASE/compile.log");
    Vars.set("EXE_FILE", "$OUTPUT_BASE/m$EXE");
    auto log = File(Vars.LOG, "w");
    run("$DMD -m$MODEL -j=2 -O -c -I$SRC -of=$OBJ $SRC/a.d $SRC/b.d", log, log);
    log.close();
    const output = std.file.readText(Vars.LOG);
    if (output.canFind("duplicate symbol"))
    {
        writeln(output);
        return 1;
    }
    run("$DMD -m$MODEL -I$SRC -of=$EXE_FILE $SRC/m.d $OBJ");
    run("$EXE_FILE");
    return 0;
}
