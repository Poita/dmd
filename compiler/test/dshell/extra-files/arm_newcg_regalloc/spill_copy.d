// A value kept in memory is loaded straight into the register it is passed in, and
// a parameter kept in memory is stored straight from the register it comes in.

pragma(inline, false) float half(float x) { return x * 0.5f; }

pragma(inline, false) float twice(float x, float y) { return x + 2 * y; }

// more values live across the calls than there are registers calls preserve
float copies15_pressure(float a, float b, float c, float d, float e, float f, float g,
    float h, float k, float m)
{
    float s = half(a);
    s += half(b);
    s += half(c);
    s += twice(d, e);
    s += twice(f, g);
    s += twice(h, k);
    s += twice(m, a);
    return s + a + b + c + d + e + f + g + h + k + m;
}

void main()
{
    const r = copies15_pressure(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    assert(r == 0.5f + 1 + 1.5f + 14 + 20 + 26 + 12 + 55);
}
