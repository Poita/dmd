// A register used often for a short while, as what a step of a loop makes, takes the
// register of one used little for a long while, which is kept in memory instead of it.

// 32 floating point values live through a loop without calls, more than there are
// registers, each step making a product used once
float loads15_blend32(const(float)[] a, float k)
{
    float s0 = k + 0, s1 = k + 1, s2 = k + 2, s3 = k + 3, s4 = k + 4, s5 = k + 5, s6 = k + 6, s7 = k + 7;
    float s8 = k + 8, s9 = k + 9, s10 = k + 10, s11 = k + 11, s12 = k + 12, s13 = k + 13, s14 = k + 14, s15 = k + 15;
    float s16 = k + 16, s17 = k + 17, s18 = k + 18, s19 = k + 19, s20 = k + 20, s21 = k + 21, s22 = k + 22, s23 = k + 23;
    float s24 = k + 24, s25 = k + 25, s26 = k + 26, s27 = k + 27, s28 = k + 28, s29 = k + 29, s30 = k + 30, s31 = k + 31;
    foreach (x; a)
    {
        s0 += x * s1; s1 -= x * s2; s2 += x * s3; s3 -= x * s4;
        s4 += x * s5; s5 -= x * s6; s6 += x * s7; s7 -= x * s8;
        s8 += x * s9; s9 -= x * s10; s10 += x * s11; s11 -= x * s12;
        s12 += x * s13; s13 -= x * s14; s14 += x * s15; s15 -= x * s16;
        s16 += x * s17; s17 -= x * s18; s18 += x * s19; s19 -= x * s20;
        s20 += x * s21; s21 -= x * s22; s22 += x * s23; s23 -= x * s24;
        s24 += x * s25; s25 -= x * s26; s26 += x * s27; s27 -= x * s28;
        s28 += x * s29; s29 -= x * s30; s30 += x * s31; s31 -= x * s0;
    }
    return s0 + s1 + s2 + s3 + s4 + s5 + s6 + s7 + s8 + s9 + s10 + s11 + s12 + s13 + s14 + s15 +
        s16 + s17 + s18 + s19 + s20 + s21 + s22 + s23 + s24 + s25 + s26 + s27 + s28 + s29 + s30 + s31;
}

float reference(const(float)[] a, float k)
{
    float[32] s;
    foreach (j, ref v; s)
        v = k + j;
    foreach (x; a)
        foreach (j; 0 .. 32)
            s[j] += (j & 1 ? -x : x) * s[(j + 1) % 32];
    float t = 0;
    foreach (v; s)
        t += v;
    return t;
}

void main()
{
    float[3] f = [0.5, 0.25, 0.125];
    assert(loads15_blend32(f[], 1) == reference(f[], 1));
}
