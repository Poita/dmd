// Aggregates are passed and returned according to the platform calling convention.

struct F2 { float a, b; } struct F3 { float a, b, c; } struct F4 { float a, b, c, d; }
struct D2 { double a, b; } struct D3 { double a, b, c; } struct D4 { double a, b, c, d; }
struct Mix { double a; long b; } struct Big { long a, b, c; } struct I3 { int a, b, c; }
struct P1 { void* p; } struct P2 { void* p; size_t n; }
void check(bool ok, string what) { assert(ok, what); }
F2 rf2(float x) { return F2(x, x+1); }
F3 rf3(float x) { return F3(x, x+1, x+2); }
F4 rf4(float x) { return F4(x, x+1, x+2, x+3); }
D2 rd2(double x) { return D2(x, x+1); }
D4 rd4(double x) { return D4(x, x+1, x+2, x+3); }
Mix rmix(double x) { return Mix(x, 7); }
Big rbig(long x) { return Big(x, x+1, x+2); }
I3 ri3(int x) { return I3(x, x+1, x+2); }
P1 rp1(void* p) { return P1(p); }
P2 rp2(void* p) { return P2(p, 5); }
double af4(F4 v) { return v.a + v.b + v.c + v.d; }
double ad4d3(D4 v, D3 w) { return v.a + v.b + v.c + v.d + w.a + w.b + w.c; }
double aif3d(int i, F3 v, double d) { return i + v.a + v.b + v.c + d; }
long abigi3(Big b, I3 i) { return b.a + b.b + b.c + i.a + i.b + i.c; }
size_t ap1p2(P1 a, P2 b, int c) { return cast(size_t)a.p + cast(size_t)b.p + b.n + c; }
struct S { int x; size_t get(P1 k) const { return x + cast(size_t) k.p; } size_t get2(in P2 k) const { return x + k.n; } }
class C { long base = 100; Big vbig(long x) { return Big(base + x, x, x); } final D4 fd4(double x) { return D4(x, x, x, base); } }
struct T { long base; Big big(long x) const { return Big(base + x, x, x); } }
extern (C) F4 crf4(float x) { return F4(x, x+1, x+2, x+3); }
extern (C) double caf4(F4 v, I3 i) { return v.a + v.b + v.c + v.d + i.a + i.b + i.c; }
void main()
{
    auto f2 = rf2(1); check(f2.a == 1 && f2.b == 2, "ret F2");
    auto f3 = rf3(1); check(f3.a == 1 && f3.c == 3, "ret F3");
    auto f4 = rf4(1); check(f4.a == 1 && f4.d == 4, "ret F4");
    auto d2 = rd2(1); check(d2.a == 1 && d2.b == 2, "ret D2");
    auto d4 = rd4(1); check(d4.a == 1 && d4.d == 4, "ret D4");
    auto m = rmix(1.5); check(m.a == 1.5 && m.b == 7, "ret Mix");
    auto b = rbig(10); check(b.a == 10 && b.c == 12, "ret Big");
    auto i3 = ri3(5); check(i3.a == 5 && i3.c == 7, "ret I3");
    int z; auto p1 = rp1(&z); check(p1.p == &z, "ret P1");
    auto p2 = rp2(&z); check(p2.p == &z && p2.n == 5, "ret P2");
    check(af4(F4(1, 2, 3, 4)) == 10, "arg F4");
    check(ad4d3(D4(1, 2, 3, 4), D3(5, 6, 7)) == 28, "arg D4,D3");
    check(aif3d(1, F3(2, 3, 4), 5) == 15, "arg int,F3,double");
    check(abigi3(Big(1, 2, 3), I3(4, 5, 6)) == 21, "arg Big,I3");
    check(ap1p2(P1(cast(void*)1), P2(cast(void*)2, 3), 4) == 10, "arg P1,P2,int");
    S s = S(100);
    check(s.get(P1(cast(void*)5)) == 105, "method P1");
    check(s.get2(P2(null, 7)) == 107, "method in P2");
    auto cf4 = crf4(1); check(cf4.a == 1 && cf4.d == 4, "C ret F4");
    check(caf4(F4(1, 2, 3, 4), I3(1, 1, 1)) == 13, "C arg F4,I3");
    auto c = new C;
    auto vb = c.vbig(5); check(vb.a == 105 && vb.b == 5 && vb.c == 5, "virtual ret Big");
    auto fd = c.fd4(2); check(fd.a == 2 && fd.d == 100, "final ret D4");
    auto t = T(7);
    auto tb = t.big(3); check(tb.a == 10 && tb.c == 3, "method ret Big");
}
