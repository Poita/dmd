/* REQUIRED_ARGS: -O
 */

// Variables written through a pointer of another type can be kept in a
// register of the other kind, and are then moved with FMOV. Reduced from
// std.math.operations.NaN.

double fromBits(ulong payload)
{
    ulong v = payload;
    double x;
    *cast(ulong*) &x = v;
    return x;
}

ulong toBits(double d)
{
    ulong u;
    *cast(double*) &u = d;
    return u;
}

float fromBits32(uint payload)
{
    float x;
    *cast(uint*) &x = payload;
    return x;
}

void main()
{
    assert(fromBits(0x3FF0_0000_0000_0000) == 1.0);
    assert(fromBits(0xC000_0000_0000_0000) == -2.0);
    assert(toBits(1.0) == 0x3FF0_0000_0000_0000);
    assert(toBits(-0.5) == 0xBFE0_0000_0000_0000);
    assert(fromBits32(0x3F80_0000) == 1.0f);
}
