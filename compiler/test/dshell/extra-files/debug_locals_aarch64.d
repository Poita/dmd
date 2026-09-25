struct S { int a; long b; }
struct A64 { align(64) int[4] v; }

pragma(inline, false)
long f(int x, double y, S s, long p4, long p5, long p6, long p7, long p8, long p9, long p10)
{
    long local = x * 2;
    double half = y / 2;
    long total = local + s.b + p10;   // break here
    return total + cast(long) half;
}

pragma(inline, false)
int g(int n)
{
    A64 w;
    w.v[] = n;
    int m = n + 1;
    return w.v[3] + m;               // break here too
}

void main()
{
    f(21, 5.0, S(7, 99), 4, 5, 6, 7, 8, 9, 1010);
    g(40);
}
