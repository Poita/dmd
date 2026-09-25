// A library member refers to a ClassInfo that an earlier member both defines
// and refers to; the reference has to name the ClassInfo in the later member.
import dshell;

int main()
{
    Vars.set("SRC", "$EXTRA_FILES/lib_classinfo_reference");
    Vars.set("LIB", "$OUTPUT_BASE/lib$LIBEXT");
    Vars.set("EXE_FILE", "$OUTPUT_BASE/main$EXE");
    run("$DMD -m$MODEL -O -release -lib -of=$LIB $SRC/lib.d");
    run("$DMD -m$MODEL -I$SRC -of=$EXE_FILE $SRC/main.d $LIB");
    run("$EXE_FILE");
    return 0;
}
