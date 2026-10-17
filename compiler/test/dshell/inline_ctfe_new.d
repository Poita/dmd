// A `new` expression inlined into a function that CTFE later interprets (here a
// static initializer in an imported function the inliner analyzes) refers to the
// inlined copies of the callee's parameters, not to the parameters themselves.
module test.dshell.inline_ctfe_new;

import dshell;

int main()
{
    Vars.set("SRC", "$EXTRA_FILES/inline_ctfe_new");
    run("$DMD -m$MODEL -inline -c -I$SRC -od$OUTPUT_BASE $SRC/main.d");
    return 0;
}
