// All the general purpose registers not reserved are allocated, x8 among them, so
// a loop of as many values as there are such registers keeps them all in registers.

// 23 values live through a loop without calls
ulong loads0_mix(const(ulong)[] a, ulong k0, ulong k1, ulong k2, ulong k3, ulong k4, ulong k5)
{
    ulong s0 = k0, s1 = k1, s2 = k2, s3 = k3, s4 = k4, s5 = k5;
    ulong s6 = k0 ^ k1, s7 = k1 ^ k2, s8 = k2 ^ k3, s9 = k3 ^ k4, s10 = k4 ^ k5;
    ulong s11 = k0 + k5, s12 = k1 + k4, s13 = k2 + k3, s14 = k0 * 3, s15 = k1 * 5;
    ulong s16 = k2 * 7, s17 = k3 * 9, s18 = k4 * 11;
    foreach (x; a)
    {
        s0 += x ^ s1; s1 += x ^ s2; s2 += x ^ s3; s3 += x ^ s4; s4 += x ^ s5;
        s5 += x ^ s6; s6 += x ^ s7; s7 += x ^ s8; s8 += x ^ s9; s9 += x ^ s10;
        s10 += x ^ s11; s11 += x ^ s12; s12 += x ^ s13; s13 += x ^ s14; s14 += x ^ s15;
        s15 += x ^ s16; s16 += x ^ s17; s17 += x ^ s18; s18 += x ^ s0;
    }
    return s0 + s1 + s2 + s3 + s4 + s5 + s6 + s7 + s8 + s9 + s10 + s11 + s12 + s13 + s14 +
        s15 + s16 + s17 + s18;
}

ulong reference(const(ulong)[] a, ulong k0, ulong k1, ulong k2, ulong k3, ulong k4, ulong k5)
{
    ulong[19] s = [k0, k1, k2, k3, k4, k5, k0 ^ k1, k1 ^ k2, k2 ^ k3, k3 ^ k4, k4 ^ k5,
        k0 + k5, k1 + k4, k2 + k3, k0 * 3, k1 * 5, k2 * 7, k3 * 9, k4 * 11];
    foreach (x; a)
        foreach (j; 0 .. 19)
            s[j] += x ^ s[(j + 1) % 19];
    ulong t;
    foreach (v; s)
        t += v;
    return t;
}

void main()
{
    ulong[7] a = [1, 22, 333, 4444, 55555, 666666, 7777777];
    assert(loads0_mix(a[], 1, 2, 3, 4, 5, 6) == reference(a[], 1, 2, 3, 4, 5, 6));
}
