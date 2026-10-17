// The old AArch64 code generator widens a parameter it reads from its incoming
// register by the parameter's type; begin() is kept from the new code generator.
module test.dshell.arm_param_widen;

import dshell;

int main()
{
    version (AArch64) {} else return DISABLED;

    Vars.set("SRC", "$EXTRA_FILES/arm_param_widen/widen.d");
    Vars.set("EXE_FILE", "$OUTPUT_BASE/widen$EXE");
    run("$DMD -m$MODEL -inline -of$EXE_FILE $SRC", stdout, stderr,
        ["DMD_NEWCG": "1", "DMD_NEWCG_NAME": "-Pipeline5begin"]);
    run("$EXE_FILE");
    return 0;
}
