// A function literal at aggregate scope is emitted by its own module even
// when every call to it there is inlined: a template instance compiled
// elsewhere without inlining still calls it.
module test.dshell.inline_literal_emit;

import dshell;

int main()
{
    Vars.set("SRC", "$EXTRA_FILES/inline_literal_emit");
    Vars.set("LIB", "$OUTPUT_BASE/digits$LIBEXT");
    Vars.set("EXE_FILE", "$OUTPUT_BASE/main$EXE");
    run("$DMD -m$MODEL -O -inline -release -lib -of=$LIB $SRC/digits.d");
    run("$DMD -m$MODEL -I$SRC -of=$EXE_FILE $SRC/main.d $LIB");
    run("$EXE_FILE");
    return 0;
}
