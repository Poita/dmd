// An aggregate argument built in place (an array literal) that is passed on the
// stack because the floating point registers are used up.

void g(float[3] p, float p3, float p4, float p5, float p6, float p7, float p8, float p9, float p10)
{
    assert(p == [1, 2, 3]);
    assert(p3 == 4 && p10 == 11);
}

struct S { float a, b, c; }

void h(S s, double d1, double d2, double d3, double d4, double d5, double d6, double d7)
{
    assert(s == S(1, 2, 3));
    assert(d1 == 4 && d7 == 10);
}

float[12] v = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

void main()
{
    g([v[0], v[1], v[2]], v[3], v[4], v[5], v[6], v[7], v[8], v[9], v[10]);
    h(S(v[0], v[1], v[2]), v[3], v[4], v[5], v[6], v[7], v[8], v[9]);
}
