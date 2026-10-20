/* Arguments that do not fit in the registers left go on the stack where the
 * C compiler puts and finds them: scalars and HFAs at their own size and
 * alignment, other small aggregates in 8 byte aligned slots of a multiple of 8
 * bytes, large aggregates as a pointer to a copy.
 *
 * EXTRA_CPP_SOURCES: c_stack_args_abi.cpp
 */

struct S1 { ubyte a; }
struct S4 { ubyte a; uint b; }
struct S20 { float a, b, c, d, e; }
struct V3 { float x, y, z; }
struct SS { short s; }
struct D1 { double d; }
struct C3 { char[3] c; }
struct M12 { int a; float b; short c; }

extern (C)
{
long c_stk1(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7,
    S1 a, bool b, S4 c, S20 d);
long c_stk2(double d0, double d1, double d2, double d3, double d4, double d5, double d6, double d7,
    int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7,
    bool b, V3 v, char c, SS s, char c2, C3 c3, float f, D1 dd, short sh, int i, M12 m);
long call_d_stk1();
long call_d_stk2();

long d_stk1(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7,
    S1 a, bool b, S4 c, S20 d)
{
    return a.a * 1000000L + b * 100000 + c.a * 10000 + c.b * 100 + cast(long)(d.a + d.e);
}

long d_stk2(double d0, double d1, double d2, double d3, double d4, double d5, double d6, double d7,
    int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7,
    bool b, V3 v, char c, SS s, char c2, C3 c3, float f, D1 dd, short sh, int i, M12 m)
{
    return b + cast(long)(v.x * 10 + v.y * 100 + v.z * 1000) + c * 10000L + s.s * 100000L
        + c2 * 1000000L + c3.c[0] * 10000000L + c3.c[2] * 100000000L + cast(long)(f * 1e9)
        + cast(long)(dd.d * 1e10) + sh * 100000000000L + i * 1000000000000L
        + m.a * 10000000000000L + cast(long)(m.b * 1e14) + m.c * 1000000000000000L;
}
}

enum long expect1 = 7 * 1000000L + 100000 + 3 * 10000 + 21 * 100 + 6;
enum long expect2 = 1 + 3210 + 5 * 10000L + 4 * 100000L + 6 * 1000000L + 1 * 10000000L + 2 * 100000000L
    + 250000000L + 5000000000L + 7 * 100000000000L + 8 * 1000000000000L
    + 3 * 10000000000000L + 50000000000000L + 4 * 1000000000000000L;

void main()
{
    if (c_stk1(1, 2, 3, 4, 5, 6, 7, 8, S1(7), true, S4(3, 21), S20(1, 2, 3, 4, 5)) != expect1)
        assert(0, "D calling C 1");
    if (call_d_stk1() != expect1)
        assert(0, "C calling D 1");
    if (c_stk2(1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8, true, V3(1, 2, 3), 5, SS(4), 6,
            C3([1, 0, 2]), 0.25f, D1(0.5), 7, 8, M12(3, 0.5f, 4)) != expect2)
        assert(0, "D calling C 2");
    if (call_d_stk2() != expect2)
        assert(0, "C calling D 2");
}
