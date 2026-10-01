// Loads and stores through a pointer plus a constant offset, which AArch64
// can encode in the addressing mode.

struct S
{
    byte b;
    short h;
    int i;
    long l;
    float f;
    double d;
    ubyte[4100] pad;
    int far;
}

align(1) struct P
{
    align(1):
    byte b;
    int i;      // misaligned
    long l;     // misaligned
}

int sum(const S* s) { return s.b + s.h + s.i + cast(int)s.l + cast(int)s.f + cast(int)s.d + s.far; }

void set(S* s)
{
    s.b = -1; s.h = -2; s.i = -3; s.l = -4; s.f = 5; s.d = 6; s.far = 7;
}

long packed(P* p) { p.i += 1; p.l += 2; return p.i + p.l + p.b; }

int index(const int* a) { return a[3] + a[1023] + a[2000]; }

void main()
{
    S* s = new S;
    set(s);
    assert(s.b == -1 && s.h == -2 && s.i == -3 && s.l == -4 && s.f == 5 && s.d == 6 && s.far == 7);
    assert(sum(s) == -1 - 2 - 3 - 4 + 5 + 6 + 7);

    P* p = new P;
    p.b = 3; p.i = 10; p.l = 20;
    assert(packed(p) == 11 + 22 + 3);

    int[2001] a;
    a[3] = 1; a[1023] = 2; a[2000] = 4;
    assert(index(a.ptr) == 7);
}
