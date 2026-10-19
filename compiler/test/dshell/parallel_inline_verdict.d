// A function that a worker of a split compilation found cannot be inlined is not
// analyzed again by another worker considering inlining it: the template instances
// its body needs are generated once, by the worker compiling its module.
module test.dshell.parallel_inline_verdict;

import dshell;
import std.algorithm : canFind, count, splitter;
import std.process : execute;

int main()
{
    version (Posix) {} else return DISABLED;

    Vars.set("SRC", "$EXTRA_FILES/parallel_inline_verdict");
    Vars.set("LIB", "$OUTPUT_BASE/ab$LIBEXT");
    run("$DMD -m$MODEL -j=2 -inline -lib -I$SRC -of=$LIB $SRC/a.d $SRC/b.d");

    const nm = execute(["nm", Vars.LIB]);
    assert(nm.status == 0, nm.output);
    // the initializer of `a.Box!int`
    const definitions = nm.output.splitter('\n')
        .count!(line => line.canFind("_D1a__T3BoxTiZQh6__initZ") && line.canFind(" D "));
    if (definitions != 1)
    {
        writeln(nm.output);
        writefln("a.Box!int.init is defined %s times", definitions);
        return 1;
    }
    return 0;
}
