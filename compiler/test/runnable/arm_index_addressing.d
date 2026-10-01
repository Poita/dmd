// Loads indexed by a register, scaled by the element size, which AArch64 can
// encode in the addressing mode.

byte  ib(const byte*  p, size_t i) { return p[i]; }
ubyte iub(const ubyte* p, size_t i) { return p[i]; }
short ish(const short* p, size_t i) { return p[i]; }
int   ii(const int*   p, size_t i) { return p[i]; }
long  il(const long*  p, size_t i) { return p[i]; }
float iff(const float* p, size_t i) { return p[i]; }
double id(const double* p, size_t i) { return p[i]; }
long  sumsigned(const int* p, size_t n) { long s; foreach (i; 0 .. n) s += p[i]; return s; }
int   viaint(const int* p, int i) { return p[i]; }
int   twice(const int* p, size_t i) { return p[2 * i]; }

void main()
{
    byte[4] b = [1, -2, 3, -4];
    ubyte[4] ub = [1, 254, 3, 4];
    short[4] s = [1, -300, 3, 4];
    int[4] a = [1, -70000, 3, 4];
    long[4] l = [1, -(1L << 40), 3, 4];
    float[4] f = [1, 2.5f, 3, 4];
    double[4] d = [1, -2.25, 3, 4];
    assert(ib(b.ptr, 1) == -2 && ib(b.ptr, 3) == -4);
    assert(iub(ub.ptr, 1) == 254);
    assert(ish(s.ptr, 1) == -300);
    assert(ii(a.ptr, 1) == -70000);
    assert(il(l.ptr, 1) == -(1L << 40));
    assert(iff(f.ptr, 1) == 2.5f);
    assert(id(d.ptr, 1) == -2.25);
    assert(sumsigned(a.ptr, 4) == 1 - 70000 + 3 + 4);
    assert(viaint(a.ptr + 2, -1) == -70000);
    assert(twice(a.ptr, 1) == 3);
}
