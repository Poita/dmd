// An object file compiled with -g keeps its debug information when the compilation
// is split across worker processes: on Mach-O, combining the workers' parts with
// `ld -r` would leave only a debug map pointing at the parts, which are deleted.
module test.dshell.parallel_debuginfo;

import dshell;
import std.algorithm : canFind;
import std.process : execute;

int main()
{
    version (OSX) {} else return DISABLED;

    std.file.write(Vars.OUTPUT_BASE ~ "/a.d", "module a; int a(int x) { return x * 3; }\n");
    std.file.write(Vars.OUTPUT_BASE ~ "/b.d", "module b; import a; int b(int x) { return a.a(x) + 1; }\n");
    run("$DMD -m$MODEL -j=2 -g -c -I$OUTPUT_BASE -of=$OUTPUT_BASE/ab$OBJ $OUTPUT_BASE/a.d $OUTPUT_BASE/b.d");

    const sections = execute(["otool", "-l", Vars.OUTPUT_BASE ~ "/ab" ~ Vars.OBJ]);
    assert(sections.status == 0, sections.output);
    if (!sections.output.canFind("__debug_info") || !sections.output.canFind("__debug_line"))
    {
        writeln(sections.output);
        writeln("the object file has no debug information");
        return 1;
    }
    return 0;
}
