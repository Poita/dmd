// A function that spills no register of a class has the registers otherwise kept for
// loading and storing spilled values allocated too: x14 and x15, and v29 to v31.

// 21 general purpose values live through a loop without calls, with the pointer,
// the length and the index: more than the 24 general purpose registers allocated
// to functions that spill
ulong loads0_mixMore(const(ulong)[] a, ulong k0, ulong k1, ulong k2, ulong k3, ulong k4, ulong k5)
{
    ulong s0 = k0, s1 = k1, s2 = k2, s3 = k3, s4 = k4, s5 = k5;
    ulong s6 = k0 ^ k1, s7 = k1 ^ k2, s8 = k2 ^ k3, s9 = k3 ^ k4, s10 = k4 ^ k5;
    ulong s11 = k0 + k5, s12 = k1 + k4, s13 = k2 + k3, s14 = k0 * 3, s15 = k1 * 5;
    ulong s16 = k2 * 7, s17 = k3 * 9, s18 = k4 * 11, s19 = k5 * 13, s20 = k0 * 17;
    foreach (x; a)
    {
        s0 += x ^ s1; s1 += x ^ s2; s2 += x ^ s3; s3 += x ^ s4; s4 += x ^ s5;
        s5 += x ^ s6; s6 += x ^ s7; s7 += x ^ s8; s8 += x ^ s9; s9 += x ^ s10;
        s10 += x ^ s11; s11 += x ^ s12; s12 += x ^ s13; s13 += x ^ s14; s14 += x ^ s15;
        s15 += x ^ s16; s16 += x ^ s17; s17 += x ^ s18; s18 += x ^ s19; s19 += x ^ s20;
        s20 += x ^ s0;
    }
    return s0 + s1 + s2 + s3 + s4 + s5 + s6 + s7 + s8 + s9 + s10 + s11 + s12 + s13 + s14 +
        s15 + s16 + s17 + s18 + s19 + s20;
}

ulong mixReference(const(ulong)[] a, ulong k0, ulong k1, ulong k2, ulong k3, ulong k4, ulong k5)
{
    ulong[21] s = [k0, k1, k2, k3, k4, k5, k0 ^ k1, k1 ^ k2, k2 ^ k3, k3 ^ k4, k4 ^ k5,
        k0 + k5, k1 + k4, k2 + k3, k0 * 3, k1 * 5, k2 * 7, k3 * 9, k4 * 11, k5 * 13, k0 * 17];
    foreach (x; a)
        foreach (j; 0 .. 21)
            s[j] += x ^ s[(j + 1) % 21];
    ulong t;
    foreach (v; s)
        t += v;
    return t;
}

// 28 floating point values live through a loop without calls, with what each step
// reads and makes, each other one subtracting so they are not made vector operations:
// more than the 29
// floating point registers allocated to functions that spill
float loads0_blend(const(float)[] a, float k)
{
    float s0 = k, s1 = k + 1, s2 = k + 2, s3 = k + 3, s4 = k + 4, s5 = k + 5, s6 = k + 6;
    float s7 = k + 7, s8 = k + 8, s9 = k + 9, s10 = k + 10, s11 = k + 11, s12 = k + 12;
    float s13 = k + 13, s14 = k + 14, s15 = k + 15, s16 = k + 16, s17 = k + 17, s18 = k + 18;
    float s19 = k + 19, s20 = k + 20, s21 = k + 21, s22 = k + 22, s23 = k + 23, s24 = k + 24;
    float s25 = k + 25, s26 = k + 26, s27 = k + 27;
    foreach (x; a)
    {
        s0 += x * s1; s1 -= x * s2; s2 += x * s3; s3 -= x * s4;
        s4 += x * s5; s5 -= x * s6; s6 += x * s7; s7 -= x * s8;
        s8 += x * s9; s9 -= x * s10; s10 += x * s11; s11 -= x * s12;
        s12 += x * s13; s13 -= x * s14; s14 += x * s15; s15 -= x * s16;
        s16 += x * s17; s17 -= x * s18; s18 += x * s19; s19 -= x * s20;
        s20 += x * s21; s21 -= x * s22; s22 += x * s23; s23 -= x * s24;
        s24 += x * s25; s25 -= x * s26; s26 += x * s27; s27 -= x * s0;
    }
    return s0 + s1 + s2 + s3 + s4 + s5 + s6 + s7 + s8 + s9 + s10 + s11 + s12 + s13 + s14 +
        s15 + s16 + s17 + s18 + s19 + s20 + s21 + s22 + s23 + s24 + s25 + s26 + s27;
}

float blendReference(const(float)[] a, float k)
{
    float[28] s;
    foreach (j, ref v; s)
        v = k + j;
    foreach (x; a)
        foreach (j; 0 .. 28)
            s[j] += (j & 1 ? -x : x) * s[(j + 1) % 28];
    float t = 0;
    foreach (v; s)
        t += v;
    return t;
}

void main()
{
    ulong[7] a = [1, 22, 333, 4444, 55555, 666666, 7777777];
    assert(loads0_mixMore(a[], 1, 2, 3, 4, 5, 6) == mixReference(a[], 1, 2, 3, 4, 5, 6));
    float[3] f = [0.5, 0.25, 0.125];
    assert(loads0_blend(f[], 1) == blendReference(f[], 1));
}
