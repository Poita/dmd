// A template instance used by modules that different worker processes compile is
// generated once in the library they write.
module test.dshell.parallel_lib_dedupe;

import dshell;
import std.algorithm : canFind, count, splitter;
import std.process : execute;

int main()
{
    version (Posix) {} else return DISABLED;

    std.file.write(Vars.OUTPUT_BASE ~ "/tmpl.d",
        "module tmpl; T twice(T)(T x) { return x + x; }\n");
    string files = "$OUTPUT_BASE/tmpl.d";
    foreach (m; ["a", "b", "c", "d"])
    {
        std.file.write(Vars.OUTPUT_BASE ~ "/" ~ m ~ ".d",
            "module " ~ m ~ "; import tmpl; int " ~ m ~ "() { return twice(21); }\n");
        files ~= " $OUTPUT_BASE/" ~ m ~ ".d";
    }
    Vars.set("LIB", "$OUTPUT_BASE/dedupe$LIBEXT");
    run("$DMD -m$MODEL -j=4 -lib -I$OUTPUT_BASE -of=$LIB " ~ files);

    const nm = execute(["nm", Vars.LIB]);
    assert(nm.status == 0, nm.output);
    // `twice!int` mangles to _D4tmpl__T5twiceTiZQjFNaNbNiNfiZi
    const definitions = nm.output.splitter('\n')
        .count!(line => line.canFind("tmpl__T5twiceTiZQj") &&
                        (line.canFind(" T ") || line.canFind(" W ")));
    if (definitions != 1)
    {
        writeln(nm.output);
        writefln("twice!int is defined %s times", definitions);
        return 1;
    }
    return 0;
}
