// An assignment lowered to a runtime hook (here `a.length = n`) and inlined into a
// function that CTFE later interprets is still interpreted as the assignment, not
// by running the hook.
module test.dshell.inline_ctfe_lowered;

import dshell;

int main()
{
    Vars.set("SRC", "$EXTRA_FILES/inline_ctfe_lowered");
    run("$DMD -m$MODEL -inline -c -I$SRC -od$OUTPUT_BASE $SRC/main.d");
    return 0;
}
