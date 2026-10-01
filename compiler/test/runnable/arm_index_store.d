// Stores to a pointer plus an index register, scaled by the element size.

void sb(byte* p, size_t i, byte v) { p[i] = v; }
void ss(short* p, size_t i, short v) { p[i] = v; }
void si(int* p, size_t i, int v) { p[i] = v; }
void sl(long* p, size_t i, long v) { p[i] = v; }
void sf(float* p, size_t i, float v) { p[i] = v; }
void sd(double* p, size_t i, double v) { p[i] = v; }
void fill(int* p, size_t n) { foreach (i; 0 .. n) p[i] = cast(int)(i * 3); }
void viaint(float* p, int i, float v) { p[i] = v; }

void main()
{
    byte[4] b; short[4] s; int[8] a; long[4] l; float[4] f = 0; double[4] d = 0;
    sb(b.ptr, 2, -5); ss(s.ptr, 3, -300); si(a.ptr, 1, -70000); sl(l.ptr, 2, -(1L << 40));
    sf(f.ptr, 3, 2.5f); sd(d.ptr, 1, -2.25);
    assert(b[2] == -5 && b[1] == 0 && b[3] == 0);
    assert(s[3] == -300 && s[2] == 0);
    assert(a[1] == -70000);
    assert(l[2] == -(1L << 40) && l[1] == 0 && l[3] == 0);
    assert(f[3] == 2.5f && f[0] == 0);
    assert(d[1] == -2.25 && d[0] == 0);
    fill(a.ptr, 8);
    foreach (i; 0 .. 8) assert(a[i] == i * 3);
    viaint(f.ptr + 2, -1, 7.5f);
    assert(f[1] == 7.5f);
}
