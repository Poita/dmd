// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Loads and stores indexed by a 32 bit integer, which the addressing mode
 * extends: zero extension for unsigned, sign extension for signed indices.
 */

int loadSigned(const(int)* p, int i) { return p[i]; }
int loadUnsigned(const(int)* p, uint i) { return p[i]; }
ubyte loadByteSigned(const(ubyte)* p, int i) { return p[i]; }
double loadDouble(const(double)* p, int i) { return p[i]; }
float loadFloatUnsigned(const(float)* p, uint i) { return p[i]; }
long loadLongSigned(const(long)* p, int i) { return p[i]; }

void storeSigned(int* p, int i, int v) { p[i] = v; }
void storeUnsigned(int* p, uint i, int v) { p[i] = v; }
void storeShortSigned(short* p, int i, short v) { p[i] = v; }
void storeDouble(double* p, int i, double v) { p[i] = v; }

uint sumRange(const(uint)[] a, uint lo, uint hi)
{
    uint r;
    foreach (s; lo .. hi)
        r += a[s];
    return r;
}

int main()
{
    int[8] a = [10, 11, 12, 13, 14, 15, 16, 17];
    int* mid = &a[4];
    assert(loadSigned(mid, -3) == 11);
    assert(loadSigned(mid, 2) == 16);
    assert(loadUnsigned(a.ptr, 7) == 17);

    ubyte[4] b = [1, 2, 3, 4];
    assert(loadByteSigned(&b[2], -2) == 1);

    double[4] d = [0.5, 1.5, 2.5, 3.5];
    assert(loadDouble(&d[3], -2) == 1.5);
    float[3] f = [0.25f, 0.75f, 1.25f];
    assert(loadFloatUnsigned(f.ptr, 2) == 1.25f);
    long[3] l = [-1, -2, -3];
    assert(loadLongSigned(&l[2], -1) == -2);

    storeSigned(mid, -4, 99);
    assert(a[0] == 99);
    storeUnsigned(a.ptr, 5, 77);
    assert(a[5] == 77);
    short[3] s = [1, 2, 3];
    storeShortSigned(&s[2], -2, -5);
    assert(s[0] == -5);
    storeDouble(&d[1], -1, 9.0);
    assert(d[0] == 9.0);

    uint[6] u = [1, 2, 4, 8, 16, 32];
    assert(sumRange(u[], 1, 5) == 30);
    return 0;
}
