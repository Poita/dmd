/* REQUIRED_ARGS: -O -inline
PERMUTE_ARGS: -release
*/
// Loads and stores that may refer to the same memory, which removing a load,
// taking a load's value from a store or moving a load out of a loop must
// respect: the checks are explicit so that -release keeps them.

import core.atomic;

struct S { int x; int y; float f; long l; }
union U { long l; int[2] i; }
struct B { byte b; ubyte u; short s; int w; }

void check(bool c, int line = __LINE__)
{
    import core.stdc.stdio : printf;
    import core.stdc.stdlib : exit;
    if (!c)
    {
        printf("check failed at line %d\n", line);
        exit(1);
    }
}

pragma(inline, false) int twoPointers(int* p, int* q)
{
    *p = 1;
    *q = 2;
    return *p;
}

pragma(inline, false) int overlappingSlices(int[] a, int[] b)
{
    a[1] = 5;
    b[0] = 7;
    return a[1];
}

pragma(inline, false) int refAliasesField(ref S s, ref int r)
{
    s.x = 1;
    s.y = 3;
    r = 9;
    return s.x + s.y;
}

pragma(inline, false) void writeThrough(int* p) { *p = 3; }

pragma(inline, false) int calleeWritesField(S* s)
{
    const a = s.x;
    writeThrough(&s.x);
    return s.x + a;
}

__gshared int G;
pragma(inline, false) void setG() { G = 5; }

pragma(inline, false) int calleeWritesGlobal()
{
    G = 1;
    setG();
    return G;
}

pragma(inline, false) int escapedLocal(int k)
{
    int[4] loc;
    int* p = &loc[k];
    loc[1] = 2;
    *p = 7;
    return loc[1];
}

pragma(inline, false) int loopStoreAliasesLoad(S* s, int* o, int n)
{
    foreach (i; 0 .. n)
    {
        o[i & 1] = i;
        s.y += s.x;
    }
    return s.y;
}

pragma(inline, false) int rebasedPointer(S* s, S* t)
{
    s.x = 1;
    s = t;
    s.x = 2;
    return s.x;
}

pragma(inline, false) int unionOverlap(U* u)
{
    u.l = 0;
    u.i[1] = 1;
    return cast(int)(u.l >> 32);
}

pragma(inline, false) int narrowStores(B* p, int v)
{
    p.b = cast(byte)v;
    p.u = cast(ubyte)v;
    p.s = cast(short)v;
    p.w = v;
    return p.b + p.u + p.s + p.w;
}

pragma(inline, false) long narrowStoreWideLoad(S* s, int v)
{
    s.l = -1;
    *cast(int*)&s.l = v;
    return s.l;
}

pragma(inline, false) float floatForward(S* s, float v)
{
    s.f = v;
    s.x = 4;
    return s.f * 2;
}

pragma(inline, false) int storeThenAliasingStore(S* s, int* q)
{
    s.x = 1;
    *q = 2;
    return s.x;
}

pragma(inline, false) int loopSameBase(S* s, int n)
{
    s.y = 0;
    foreach (i; 0 .. n)
        s.y += s.x * i;
    return s.y;
}

pragma(inline, false) int loopUnionField(U* u, int n)
{
    int sum;
    foreach (i; 0 .. n)
    {
        u.i[1] = i;
        sum += cast(int)(u.l >> 32);
    }
    return sum;
}

pragma(inline, false) int loopCallWrites(S* s, int n)
{
    int sum;
    foreach (i; 0 .. n)
    {
        sum += s.x;
        writeThrough(&s.x);
    }
    return sum;
}

pragma(inline, false) int loopAtomic(int* p, int n)
{
    int sum;
    foreach (i; 0 .. n)
    {
        atomicStore(*cast(shared int*)p, i);
        sum += *p;
    }
    return sum;
}

class E : Exception { this() { super("e"); } }
pragma(inline, false) void thrower(S* s) { s.x = 5; throw new E; }

pragma(inline, false) int throwingCall(S* s)
{
    s.x = 1;
    try
        thrower(s);
    catch (E)
        return s.x;
    return 0;
}

pragma(inline, false) int nestedWrites()
{
    int v = 1;
    void nest() { v = 2; }
    nest();
    return v;
}

pragma(inline, false) void prefixSum(int[] a)
{
    foreach (i; 1 .. a.length)
        a[i] = a[i - 1] + a[i];
}

pragma(inline, false) int structLocal(int n)
{
    S loc;
    loc.x = 2;
    int sum;
    foreach (i; 0 .. n)
    {
        loc.y = i;
        sum += loc.x + loc.y;
        G = sum;
    }
    return sum + loc.y;
}

pragma(inline, false) int globalInLoop(int* p, int n)
{
    int sum;
    foreach (i; 0 .. n)
    {
        *p = i;
        sum += G;
    }
    return sum;
}

void main()
{
    int a;
    check(twoPointers(&a, &a) == 2);
    int b;
    check(twoPointers(&a, &b) == 1);

    auto arr = new int[4];
    check(overlappingSlices(arr, arr[1 .. $]) == 7);
    check(overlappingSlices(arr, arr[2 .. $]) == 5);

    S s;
    check(refAliasesField(s, s.x) == 12);
    check(refAliasesField(s, s.y) == 10);
    s.x = 10;
    check(calleeWritesField(&s) == 13);
    check(calleeWritesGlobal() == 5);
    check(escapedLocal(1) == 7);
    check(escapedLocal(2) == 2);

    s = S.init;
    s.x = 1;
    check(loopStoreAliasesLoad(&s, &s.x, 4) == 5);
    S t;
    check(rebasedPointer(&s, &s) == 2);
    check(rebasedPointer(&s, &t) == 2 && s.x == 1);

    U u;
    check(unionOverlap(&u) == 1);

    B bb;
    check(narrowStores(&bb, 0x1ff80) == -128 + 0x80 + cast(short)0xff80 + 0x1ff80);
    check(narrowStoreWideLoad(&s, 5) == 0xFFFF_FFFF_0000_0005);
    check(floatForward(&s, 1.5f) == 3.0f);
    check(storeThenAliasingStore(&s, &s.x) == 2);
    check(storeThenAliasingStore(&s, &s.y) == 1);

    s.x = 3;
    check(loopSameBase(&s, 4) == 18);
    check(loopUnionField(&u, 4) == 6);
    s.x = 1;
    check(loopCallWrites(&s, 3) == 1 + 3 + 3);
    int at;
    check(loopAtomic(&at, 4) == 6);
    check(throwingCall(&s) == 5);
    check(nestedWrites() == 2);

    auto ps = [1, 2, 3, 4];
    prefixSum(ps);
    check(ps == [1, 3, 6, 10]);
    check(structLocal(3) == 2 + 3 + 4 + 2);
    G = 7;
    check(globalInLoop(&G, 3) == 0 + 1 + 2);
    G = 7;
    int other;
    check(globalInLoop(&other, 3) == 21);
}
