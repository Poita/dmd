// CTFE of std.uni code inlined before a static initializer in an imported
// function is interpreted: the generated opAssign of a struct, inlined with
// `this` replaced by a `ref` parameter, assigns through the reference.
module test.dshell.inline_ctfe_ref;

import dshell;

int main()
{
    Vars.set("SRC", "$EXTRA_FILES/inline_ctfe_ref");
    run("$DMD -m$MODEL -inline -c -I$SRC -od$OUTPUT_BASE $SRC/main.d");
    return 0;
}
