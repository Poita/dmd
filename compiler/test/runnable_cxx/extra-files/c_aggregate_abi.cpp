// Aggregates passed to and returned from C functions, see c_aggregate_abi.d

#include <stdint.h>

extern "C" {
typedef struct { float a; } F1;
typedef struct { float a, b; } F2;
typedef struct { float a, b, c; } F3;
typedef struct { float a, b, c, d; } F4;
typedef struct { double a; } D1;
typedef struct { double a, b; } D2;
typedef struct { double a, b, c; } D3;
typedef struct { double a, b, c, d; } D4;
typedef struct { double a; int64_t b; } Mix;
typedef struct { int64_t a, b, c; } Big;
typedef struct { int32_t a, b, c; } I3;
F1 c_f1(float x) { F1 r = {x}; return r; }
F2 c_f2(float x) { F2 r = {x, x+1}; return r; }
F3 c_f3(float x) { F3 r = {x, x+1, x+2}; return r; }
F4 c_f4(float x) { F4 r = {x, x+1, x+2, x+3}; return r; }
D1 c_d1(double x) { D1 r = {x}; return r; }
D2 c_d2(double x) { D2 r = {x, x+1}; return r; }
D3 c_d3(double x) { D3 r = {x, x+1, x+2}; return r; }
D4 c_d4(double x) { D4 r = {x, x+1, x+2, x+3}; return r; }
Mix c_mix(double x) { Mix r = {x, 7}; return r; }
Big c_big(int64_t x) { Big r = {x, x+1, x+2}; return r; }
I3 c_i3(int32_t x) { I3 r = {x, x+1, x+2}; return r; }
double c_sum_f4(F4 v) { return v.a + v.b + v.c + v.d; }
double c_sum_d4(D4 v, D3 w) { return v.a + v.b + v.c + v.d + w.a + w.b + w.c; }
double c_sum_f3(int i, F3 v, double d) { return i + v.a + v.b + v.c + d; }
int64_t c_sum_big(Big b, I3 i) { return b.a + b.b + b.c + i.a + i.b + i.c; }
double c_many(double a, double b, double c, double d, double e, double f, double g, double h, double i, float j) { return a+b+c+d+e+f+g+h+i+j; }
int64_t c_manyi(int64_t a, int64_t b, int64_t c, int64_t d, int64_t e, int64_t f, int64_t g, int64_t h, int64_t i, int32_t j) { return a+b+c+d+e+f+g+h+i+j; }
}
