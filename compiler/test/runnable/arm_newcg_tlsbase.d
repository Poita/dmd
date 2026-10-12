/* REQUIRED_ARGS: -O
 */
// Many thread local variables in one function, initialized and zero, large and
// small, of templates and function statics: each reached at its own address on
// each thread

import core.thread;

int a = 1;
long b;
ubyte[100] big;
double c = 2.5;
int[3] trio = [7, 8, 9];
struct S { int x; long y; }
S s = S(4, 5);
short z;

template T(int n) { int t = n; }

pragma(inline, false) int* staticOf()
{
    static int st = 11;
    return &st;
}

pragma(inline, false) long touchAll(int k)
{
    a += k;
    b += 2 * k;
    big[k] = cast(ubyte)(k + 1);
    c *= 2;
    trio[k % 3] += k;
    s.y += k;
    z = cast(short)(z + 1);
    T!3.t += k;
    *staticOf() += 1;
    return a + b + big[k] + cast(long)c + trio[0] + trio[1] + trio[2] + s.x + s.y + z + T!3.t;
}

pragma(inline, false) void*[10] addresses()
{
    void*[10] r = [cast(void*)&a, &b, &big, &c, &trio, &s, &z, &T!3.t, staticOf(), &big[99]];
    return r;
}

void check()
{
    a = 1; b = 0; big[] = 0; c = 2.5; trio = [7, 8, 9]; s = S(4, 5); z = 0; T!3.t = 3; *staticOf() = 11;
    long r = touchAll(2);
    // a 3, b 4, big[2] 3, c 5, trio 7 8 11, s 4 7, z 1, t 5
    if (r != 3 + 4 + 3 + 5 + 7 + 8 + 11 + 4 + 7 + 1 + 5) assert(0);
    if (*staticOf() != 12 || big[2] != 3 || big[1] != 0 || trio[2] != 11) assert(0);
    auto p = addresses();
    if (p[0] !is &a || p[1] !is &b || p[2] !is big.ptr || p[3] !is &c || p[4] !is trio.ptr ||
        p[5] !is &s || p[6] !is &z || p[7] !is &T!3.t || p[9] !is &big[99]) assert(0);
    foreach (i; 0 .. 10)
        foreach (j; i + 1 .. 10)
            if (p[i] is p[j]) assert(0);
}

void main()
{
    check();
    auto mine = addresses();
    void*[10] theirs;
    auto t = new Thread({ check(); theirs = addresses(); });
    t.start();
    t.join();
    foreach (i; 0 .. 10)
        if (mine[i] is theirs[i]) assert(0);
    if (a != 3 || z != 1) assert(0);    // untouched by the other thread
}
