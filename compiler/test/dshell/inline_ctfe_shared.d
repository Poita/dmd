// An expression and its lowering share subexpressions declaring temporaries
// (here `a ~= v` copying a struct with a postblit); inlined, each copy refers to
// its own temporaries, so CTFE can interpret the expression afterwards.
module test.dshell.inline_ctfe_shared;

import dshell;

int main()
{
    Vars.set("SRC", "$EXTRA_FILES/inline_ctfe_shared");
    run("$DMD -m$MODEL -inline -c -I$SRC -od$OUTPUT_BASE $SRC/main.d");
    return 0;
}
