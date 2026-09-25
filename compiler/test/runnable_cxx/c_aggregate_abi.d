/* Aggregates are passed to and returned from C functions according to the
 * platform calling convention.
 *
 * EXTRA_CPP_SOURCES: c_aggregate_abi.cpp
 */

struct F1 { float a; } struct F2 { float a, b; } struct F3 { float a, b, c; } struct F4 { float a, b, c, d; }
struct D1 { double a; } struct D2 { double a, b; } struct D3 { double a, b, c; } struct D4 { double a, b, c, d; }
struct Mix { double a; long b; } struct Big { long a, b, c; } struct I3 { int a, b, c; }
extern (C) {
F1 c_f1(float); F2 c_f2(float); F3 c_f3(float); F4 c_f4(float);
D1 c_d1(double); D2 c_d2(double); D3 c_d3(double); D4 c_d4(double);
Mix c_mix(double); Big c_big(long); I3 c_i3(int);
double c_sum_f4(F4); double c_sum_d4(D4, D3); double c_sum_f3(int, F3, double); long c_sum_big(Big, I3);
double c_many(double, double, double, double, double, double, double, double, double, float);
long c_manyi(long, long, long, long, long, long, long, long, long, int);
}
void check(bool ok, string what) { assert(ok, what); }
void main()
{
    check(c_f1(1).a == 1, "ret F1");
    auto f2 = c_f2(1); check(f2.a == 1 && f2.b == 2, "ret F2");
    auto f3 = c_f3(1); check(f3.a == 1 && f3.b == 2 && f3.c == 3, "ret F3");
    auto f4 = c_f4(1); check(f4.a == 1 && f4.b == 2 && f4.c == 3 && f4.d == 4, "ret F4");
    check(c_d1(1).a == 1, "ret D1");
    auto d2 = c_d2(1); check(d2.a == 1 && d2.b == 2, "ret D2");
    auto d3 = c_d3(1); check(d3.a == 1 && d3.b == 2 && d3.c == 3, "ret D3");
    auto d4 = c_d4(1); check(d4.a == 1 && d4.b == 2 && d4.c == 3 && d4.d == 4, "ret D4");
    auto m = c_mix(1.5); check(m.a == 1.5 && m.b == 7, "ret Mix");
    auto b = c_big(10); check(b.a == 10 && b.b == 11 && b.c == 12, "ret Big");
    auto i3 = c_i3(5); check(i3.a == 5 && i3.b == 6 && i3.c == 7, "ret I3");
    check(c_sum_f4(F4(1, 2, 3, 4)) == 10, "arg F4");
    check(c_sum_d4(D4(1, 2, 3, 4), D3(5, 6, 7)) == 28, "arg D4,D3");
    check(c_sum_f3(1, F3(2, 3, 4), 5) == 15, "arg int,F3,double");
    check(c_sum_big(Big(1, 2, 3), I3(4, 5, 6)) == 21, "arg Big,I3");
    check(c_many(1, 2, 3, 4, 5, 6, 7, 8, 9, 10) == 55, "arg 10 floats");
    check(c_manyi(1, 2, 3, 4, 5, 6, 7, 8, 9, 10) == 55, "arg 10 ints");
}
