// The remainder of floating point division.

T mod(T)(T a, T b) { return a % b; }
T modass(T)(T a, T b) { a %= b; return a; }

void main()
{
    assert(mod(8.0, 6.0) == 2 && mod(8.0f, 6.0f) == 2 && mod(8.0L, 6.0L) == 2);
    assert(mod(-7.5, 2.0) == -1.5);
    assert(modass(8.0, 6.0) == 2 && modass(-7.5f, 2.0f) == -1.5f);
    float[4] a = 8, r;
    r[] = a[] % 6.0f;
    assert(r[3] == 2);
}
