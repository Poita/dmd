// Functions whose arguments run out of registers, so the rest go on the stack,
// and callers of the same functions written in D
struct S1 { unsigned char a; };
struct S4 { unsigned char a; unsigned b; };
struct S20 { float a, b, c, d, e; };
struct V3 { float x, y, z; };
struct SS { short s; };
struct D1 { double d; };
struct C3 { char c[3]; };
struct M12 { int a; float b; short c; };

extern "C" {

long long c_stk1(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7,
    S1 a, bool b, S4 c, S20 d)
{
    return a.a * 1000000LL + b * 100000 + c.a * 10000 + c.b * 100 + (long long)(d.a + d.e);
}

long long c_stk2(double d0, double d1, double d2, double d3, double d4, double d5, double d6, double d7,
    int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7,
    bool b, V3 v, char c, SS s, char c2, C3 c3, float f, D1 dd, short sh, int i, M12 m)
{
    return b + (long long)(v.x * 10 + v.y * 100 + v.z * 1000) + c * 10000LL + s.s * 100000LL
        + c2 * 1000000LL + c3.c[0] * 10000000LL + c3.c[2] * 100000000LL + (long long)(f * 1e9)
        + (long long)(dd.d * 1e10) + sh * 100000000000LL + i * 1000000000000LL
        + m.a * 10000000000000LL + (long long)(m.b * 1e14) + m.c * 1000000000000000LL;
}

long long d_stk1(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7,
    S1 a, bool b, S4 c, S20 d);
long long d_stk2(double d0, double d1, double d2, double d3, double d4, double d5, double d6, double d7,
    int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7,
    bool b, V3 v, char c, SS s, char c2, C3 c3, float f, D1 dd, short sh, int i, M12 m);

long long call_d_stk1()
{
    S1 a = {7}; S4 c = {3, 21}; S20 d = {1, 2, 3, 4, 5};
    return d_stk1(1, 2, 3, 4, 5, 6, 7, 8, a, true, c, d);
}

long long call_d_stk2()
{
    V3 v = {1, 2, 3}; SS s = {4}; C3 c3 = {{1, 0, 2}}; D1 dd = {0.5}; M12 m = {3, 0.5f, 4};
    return d_stk2(1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8,
        true, v, 5, s, 6, c3, 0.25f, dd, 7, 8, m);
}

}
