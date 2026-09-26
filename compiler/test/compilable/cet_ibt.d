// REQUIRED_ARGS: -fIBT
// DISABLED: aarch64

// Test for Intel CET IBT (branch) protection

static assert(__traits(getTargetInfo, "CET") == 1);
