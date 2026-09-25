// Static arrays are passed and returned by value like aggregates of the same layout.

float  sumF3(float[3] a) { return a[0] + a[1] + a[2]; }
double sumD4(double[4] a) { return a[0] + a[1] + a[2] + a[3]; }
int    sumI3(int[3] a) { return a[0] + a[1] + a[2]; }
int    sumB5(ubyte[5] a) { return a[0] + a[1] + a[2] + a[3] + a[4]; }
long   sumL3(long[3] a) { return a[0] + a[1] + a[2]; }
double mixed(int i, float[2] f, double d, double[3] g, int[2] j)
{
    return i + f[0] + f[1] + d + g[0] + g[1] + g[2] + j[0] + j[1];
}

float[3]  retF3(float x) { return [x, x + 1, x + 2]; }
double[4] retD4(double x) { return [x, x + 1, x + 2, x + 3]; }
int[3]    retI3(int x) { return [x, x + 1, x + 2]; }
long[3]   retL3(long x) { return [x, x + 1, x + 2]; }

size_t countArgs(A...)(string fmt, A args)
{
    size_t n = fmt.length;
    foreach (a; args)
        static if (is(typeof(a[0]) == float))
            n += cast(size_t) a[2];
        else
            n += 1;
    return n;
}

void main()
{
    float[3] f3 = [1, 2, 3];
    assert(sumF3(f3) == 6);
    assert(sumD4([1.0, 2, 3, 4]) == 10);
    assert(sumI3([4, 5, 6]) == 15);
    ubyte[5] b5 = [1, 2, 3, 4, 5];
    assert(sumB5(b5) == 15);
    assert(sumL3([7, 8, 9]) == 24);
    assert(mixed(1, [2, 3], 4, [5, 6, 7], [8, 9]) == 45);

    auto r3 = retF3(1);
    assert(r3[0] == 1 && r3[2] == 3);
    auto r4 = retD4(2);
    assert(r4[0] == 2 && r4[3] == 5);
    auto i3 = retI3(3);
    assert(i3[0] == 3 && i3[2] == 5);
    auto l3 = retL3(4);
    assert(l3[0] == 4 && l3[2] == 6);

    assert(countArgs("ab", f3, 1) == 2 + 3 + 1);
}
