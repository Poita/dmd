// PERMUTE_ARGS: -inline -O -property

// Test operator overloading

extern (C) int printf(const(char*) fmt, ...);

template Seq(T...){ alias T Seq; }

bool thrown(E, T)(lazy T val)
{
    try { val(); return false; }
    catch (E e) { return true; }
}

/**************************************/

class A
{
    string opUnary(string s)()
    {
        printf("A.opUnary!(%.*s)\n", s.length, s.ptr);
        return s;
    }
}

void test1()
{
    auto a = new A();

    +a;
    -a;
    ~a;
    *a;
    ++a;
    --a;

    auto x = a++;
    assert(x == a);
    auto y = a--;
    assert(y == a);
}

/**************************************/

class A2
{
    T opCast(T)()
    {
        auto s = T.stringof;
        printf("A.opCast!(%.*s)\n", s.length, s.ptr);
        return T.init;
    }
}


void test2()
{
    auto a = new A2();

    auto x = cast(int)a;
    assert(x == 0);

    auto y = cast(char)a;
    assert(y == char.init);
}

/**************************************/

struct A3
{
    int opBinary(string s)(int i)
    {
        printf("A.opBinary!(%.*s)\n", s.length, s.ptr);
        return 0;
    }

    int opBinaryRight(string s)(int i) if (s == "/" || s == "*")
    {
        printf("A.opBinaryRight!(%.*s)\n", s.length, s.ptr);
        return 0;
    }

    T opCast(T)()
    {
        auto s = T.stringof;
        printf("A.opCast!(%.*s)\n", s.length, s.ptr);
        return T.init;
    }
}


void test3()
{
    A3 a;

    a + 3;
    4 * a;
    4 / a;
    a & 5;
}

/**************************************/

struct A4
{
    int opUnary(string s)()
    {
        printf("A.opUnary!(%.*s)\n", s.length, s.ptr);
        return 0;
    }

    T opCast(T)()
    {
        auto s = T.stringof;
        printf("A.opCast!(%.*s)\n", s.length, s.ptr);
        return T.init;
    }
}


void test4()
{
    A4 a;

    if (a)
        int x = 3;
    if (!a)
        int x = 3;
    if (!!a)
        int x = 3;
}

/**************************************/

class A5
{
    override bool opEquals(Object o)
    {
        printf("A.opEquals!(%p)\n", o);
        return 1;
    }

    int opUnary(string s)()
    {
        printf("A.opUnary!(%.*s)\n", s.length, s.ptr);
        return 0;
    }

    T opCast(T)()
    {
        auto s = T.stringof;
        printf("A.opCast!(%.*s)\n", s.length, s.ptr);
        return T.init;
    }
}

class B5 : A5
{
    override bool opEquals(Object o)
    {
        printf("B.opEquals!(%p)\n", o);
        return 1;
    }
}


void test5()
{
    A5 a = new A5();
    A5 a2 = new A5();
    B5 b = new B5();
    A n = null;

    if (a == a)
        int x = 3;
    if (a == a2)
        int x = 3;
    if (a == b)
        int x = 3;
    if (a == n)
        int x = 3;
    if (n == a)
        int x = 3;
    if (n == n)
        int x = 3;
}

/**************************************/

struct S6
{
    const bool opEquals(ref const S6 b)
    {
        printf("S.opEquals(S %p)\n", &b);
        return true;
    }

    const bool opEquals(ref const T6 b)
    {
        printf("S.opEquals(T %p)\n", &b);
        return true;
    }
}

struct T6
{
    const bool opEquals(ref const T6 b)
    {
        printf("T.opEquals(T %p)\n", &b);
        return true;
    }
/+
    const bool opEquals(ref const S6 b)
    {
        printf("T.opEquals(S %p)\n", &b);
        return true;
    }
+/
}


void test6()
{
    S6 s1;
    S6 s2;

    if (s1 == s2)
        int x = 3;

    T6 t;

    if (s1 == t)
        int x = 3;

    if (t == s2)
        int x = 3;
}

/**************************************/

struct S7
{
    const int opCmp(ref const S7 b)
    {
        printf("S.opCmp(S %p)\n", &b);
        return -1;
    }

    const int opCmp(ref const T7 b)
    {
        printf("S.opCmp(T %p)\n", &b);
        return -1;
    }
}

struct T7
{
    const int opCmp(ref const T7 b)
    {
        printf("T.opCmp(T %p)\n", &b);
        return -1;
    }
/+
    const int opCmp(ref const S7 b)
    {
        printf("T.opCmp(S %p)\n", &b);
        return -1;
    }
+/
}


void test7()
{
    S7 s1;
    S7 s2;

    if (s1 < s2)
        int x = 3;

    T7 t;

    if (s1 < t)
        int x = 3;

    if (t < s2)
        int x = 3;
}

/**************************************/

struct A8
{
    int opUnary(string s)()
    {
        printf("A.opUnary!(%.*s)\n", s.length, s.ptr);
        return 0;
    }

    int opIndexUnary(string s, T)(T i)
    {
        printf("A.opIndexUnary!(%.*s)(%d)\n", s.length, s.ptr, i);
        return 0;
    }

    int opIndexUnary(string s, T)(T i, T j)
    {
        printf("A.opIndexUnary!(%.*s)(%d, %d)\n", s.length, s.ptr, i, j);
        return 0;
    }

    int opSliceUnary(string s)()
    {
        printf("A.opSliceUnary!(%.*s)()\n", s.length, s.ptr);
        return 0;
    }

    int opSliceUnary(string s, T)(T i, T j)
    {
        printf("A.opSliceUnary!(%.*s)(%d, %d)\n", s.length, s.ptr, i, j);
        return 0;
    }
}


void test8()
{
    A8 a;

    -a;
    -a[3];
    -a[3, 4];
    -a[];
    -a[5 .. 6];
    --a[3];
}

/**************************************/

struct A9
{
    int opOpAssign(string s)(int i)
    {
        printf("A.opOpAssign!(%.*s)\n", s.length, s.ptr);
        return 0;
    }

    int opIndexOpAssign(string s, T)(int v, T i)
    {
        printf("A.opIndexOpAssign!(%.*s)(%d, %d)\n", s.length, s.ptr, v, i);
        return 0;
    }

    int opIndexOpAssign(string s, T)(int v, T i, T j)
    {
        printf("A.opIndexOpAssign!(%.*s)(%d, %d, %d)\n", s.length, s.ptr, v, i, j);
        return 0;
    }

    int opSliceOpAssign(string s)(int v)
    {
        printf("A.opSliceOpAssign!(%.*s)(%d)\n", s.length, s.ptr, v);
        return 0;
    }

    int opSliceOpAssign(string s, T)(int v, T i, T j)
    {
        printf("A.opSliceOpAssign!(%.*s)(%d, %d, %d)\n", s.length, s.ptr, v, i, j);
        return 0;
    }
}


void test9()
{
    A9 a;

    a += 8;
    a -= 8;
    a *= 8;
    a /= 8;
    a %= 8;
    a &= 8;
    a |= 8;
    a ^= 8;
    a <<= 8;
    a >>= 8;
    a >>>= 8;
    a ~= 8;
    a ^^= 8;

    a[3] += 8;
    a[3] -= 8;
    a[3] *= 8;
    a[3] /= 8;
    a[3] %= 8;
    a[3] &= 8;
    a[3] |= 8;
    a[3] ^= 8;
    a[3] <<= 8;
    a[3] >>= 8;
    a[3] >>>= 8;
    a[3] ~= 8;
    a[3] ^^= 8;

    a[3, 4] += 8;
    a[] += 8;
    a[5 .. 6] += 8;
}

/**************************************/

struct BigInt
{
    int opEquals(T)(T n) const
    {
        return 1;
    }

    int opEquals(T:int)(T n) const
    {
        return 1;
    }

    int opEquals(T:const(BigInt))(T n) const
    {
        return 1;
    }

}

int decimal(BigInt b, const BigInt c)
{
    while (b != c) {
    }
    return 1;
}

/**************************************/

struct Foo10
{
    int opUnary(string op)() { return 1; }
}

void test10()
{
    Foo10 foo;
    foo++;
}

/**************************************/

struct S4913
{
    bool opCast(T : bool)() { return true; }
}

int bug4913()
{
    if (S4913 s = S4913()) { return 83; }
    return 9;
}

static assert(bug4913() == 83);

/**************************************/
// 5551

struct Foo11 {
    Foo11 opUnary(string op:"++")() {
        return this;
    }
    Foo11 opBinary(string op)(int y) {
        return this;
    }
}

void test11()
{
    auto f = Foo11();
    f++;
}

/**************************************/
// 4099

struct X4099
{
    int x;
    alias x this;

    typeof(this) opUnary (string operator) ()
    {
        printf("operator called\n");
        return this;
    }
}

void test4099()
{
    X4099 x;
    X4099 r1 = ++x; //operator called
    X4099 r2 = x++; //BUG! (alias this used. returns int)
}

/**************************************/

void test12()
{
    static int opeq;

    // xopEquals OK
    struct S1a { const bool opEquals(    const typeof(this) rhs) { ++opeq; return false; } }
    struct S1b { const bool opEquals(ref const typeof(this) rhs) { ++opeq; return false; } }
    struct S1c { const bool opEquals(          typeof(this) rhs) { ++opeq; return false; } }

    // xopEquals NG
    struct S2a {       bool opEquals(          typeof(this) rhs) { ++opeq; return false; } }

    foreach (S; Seq!(S1a, S1b, S1c))
    {
        S s;
        opeq = 0;
        assert(s != s);                     // call opEquals directly
        assert(!typeid(S).equals(&s, &s));  // -> xopEquals (-> __xopEquals) -> opEquals
        assert(opeq == 2);
    }

    foreach (S; Seq!(S2a))
    {
        S s;
        opeq = 0;
        assert(s != s);
        assert(thrown!Error(!typeid(S).equals(&s, &s)));
            // Error("notImplemented") thrown
        assert(opeq == 1);
    }
}

/**************************************/

void test13()
{
    static int opeq;

    struct X
    {
        const bool opEquals(const X){ ++opeq; return false; }
    }
    struct S
    {
        X x;
    }

    S makeS(){ return S(); }

    S s;
    opeq = 0;
    assert(s != s);
    assert(makeS() != s);
    assert(s != makeS());
    assert(makeS() != makeS());
    assert(opeq == 4);

    // built-in opEquals == const bool opEquals(const S rhs);
    assert(!s.opEquals(s));
    assert(opeq == 5);

    // xopEquals
    assert(!typeid(S).equals(&s, &s));
    assert(opeq == 6);
}

/**************************************/

void test14()
{
    static int opeq;

    struct S
    {
        const bool opEquals(T)(const T rhs) { ++opeq; return false; }
    }

    S makeS(){ return S(); }

    S s;
    opeq = 0;
    assert(s != s);
    assert(makeS() != s);
    assert(s != makeS());
    assert(makeS() != makeS());
    assert(opeq == 4);

    // xopEquals (-> __xxopEquals) -> template opEquals
    assert(!typeid(S).equals(&s, &s));
    assert(opeq == 5);
}

/**************************************/

void test15()
{
    struct S
    {
        const bool opEquals(T)(const(T) rhs)
        if (!is(T == typeof(this)))
        { return false; }
    }

    S makeS(){ return S(); }

    S s;
    static assert(!__traits(compiles, s != s));
    static assert(!__traits(compiles, makeS() != s));
    static assert(!__traits(compiles, s != makeS()));
    static assert(!__traits(compiles, makeS() != makeS()));

    // xopEquals (-> __xxopEquals) -> Error thrown
    assert(thrown!Error(!typeid(S).equals(&s, &s)));
}

/**************************************/

void test16()
{
    struct X
    {
        int n;
        const bool opEquals(T)(T t)
        {
            return false;
        }
    }
    struct S
    {
        X x;
    }

    S s1, s2;
    assert(s1 != s2);
        // field template opEquals should call
}

/**************************************/

void test17()
{
    static int opeq = 0;

    struct S
    {
        bool opEquals(ref S rhs) { ++opeq; return false; }
    }
    S[] sa1 = new S[3];
    S[] sa2 = new S[3];
    assert(sa1 != sa2);     // isn't used TypeInfo.equals
    assert(opeq == 1);

    const(S)[] csa = new const(S)[3];
    static assert(!__traits(compiles, csa == sa1));
    static assert(!__traits(compiles, sa1 == csa));
    static assert(!__traits(compiles, csa == csa));
}

/**************************************/
// 7641

mixin template Proxy7641(alias a)
{
    auto ref opBinaryRight(string op, B)(auto ref B b)
    {
        return mixin("b "~op~" a");
    }
}
struct Typedef7641(T)
{
    private T Typedef_payload;

    this(T init)
    {
        Typedef_payload = init;
    }

    mixin Proxy7641!Typedef_payload;
}

void test7641()
{
    class C {}
    C c1 = new C();
    auto a = Typedef7641!C(c1);
    static assert(!__traits(compiles, { C c2 = a; }));
}

/**************************************/
// 8434

void test8434()
{
    static class Vector2D(T)
    {
        T x, y;

        this(T x, T y) {
            this.x = x;
            this.y = y;
        }

        U opCast(U)() const { assert(0); }
    }

    alias Vector2D!(short) Vector2s;
    alias Vector2D!(float) Vector2f;

    Vector2s vs1 = new Vector2s(42, 23);
    Vector2s vs2 = new Vector2s(42, 23);

    assert(vs1 != vs2);
}

/**************************************/

void test18()
{
    // one dimensional indexing
    static struct IndexExp
    {
        int[] opIndex(int a)
        {
            return [a];
        }

        int[] opIndexUnary(string op)(int a)
        {
            return [a];
        }

        int[] opIndexAssign(int val, int a)
        {
            return [val, a];
        }

        int[] opIndexOpAssign(string op)(int val, int a)
        {
            return [val, a];
        }

        int opDollar()
        {
            return 8;
        }
    }

    IndexExp index;
    // opIndex
    assert(index[8]     == [8]);
    assert(index[$]     == [8]);
    assert(index[$-1]   == [7]);
    assert(index[$-$/2] == [4]);
    // opIndexUnary
    assert(-index[8]     == [8]);
    assert(-index[$]     == [8]);
    assert(-index[$-1]   == [7]);
    assert(-index[$-$/2] == [4]);
    // opIndexAssign
    assert((index[8]     = 2) == [2, 8]);
    assert((index[$]     = 2) == [2, 8]);
    assert((index[$-1]   = 2) == [2, 7]);
    assert((index[$-$/2] = 2) == [2, 4]);
    // opIndexOpAssign
    assert((index[8]     += 2) == [2, 8]);
    assert((index[$]     += 2) == [2, 8]);
    assert((index[$-1]   += 2) == [2, 7]);
    assert((index[$-$/2] += 2) == [2, 4]);

    // opDollar is only one-dimensional
    static assert(!is(typeof(index[$, $])));
    static assert(!is(typeof(-index[$, $])));
    static assert(!is(typeof(index[$, $] = 2)));
    static assert(!is(typeof(index[$, $] += 2)));

    // multi dimensional indexing
    static struct ArrayExp
    {
        int[] opIndex(int a, int b)
        {
            return [a, b];
        }

        int[] opIndexUnary(string op)(int a, int b)
        {
            return [a, b];
        }

        int[] opIndexAssign(int val, int a, int b)
        {
            return [val, a, b];
        }

        int[] opIndexOpAssign(string op)(int val, int a, int b)
        {
            return [val, a, b];
        }

        int opDollar(int dim)()
        {
            return dim;
        }
    }

    ArrayExp array;
    // opIndex
    assert(array[8, 8]     == [8, 8]);
    assert(array[$, $]     == [0, 1]);
    assert(array[$, $-1]   == [0, 0]);
    assert(array[2, $-$/2] == [2, 1]);
    // opIndexUnary
    assert(-array[8, 8]     == [8, 8]);
    assert(-array[$, $]     == [0, 1]);
    assert(-array[$, $-1]   == [0, 0]);
    assert(-array[2, $-$/2] == [2, 1]);
    // opIndexAssign
    assert((array[8, 8]      = 2) == [2, 8, 8]);
    assert((array[$, $]      = 2) == [2, 0, 1]);
    assert((array[$, $-1]    = 2) == [2, 0, 0]);
    assert((array[2, $-$/2]  = 2) == [2, 2, 1]);
    // opIndexOpAssign
    assert((array[8, 8]      += 2) == [2, 8, 8]);
    assert((array[$, $]      += 2) == [2, 0, 1]);
    assert((array[$, $-1]    += 2) == [2, 0, 0]);
    assert((array[2, $-$/2]  += 2) == [2, 2, 1]);

    // one dimensional slicing
    static struct SliceExp
    {
        int[] opSlice(int a, int b)
        {
            return [a, b];
        }

        int[] opSliceUnary(string op)(int a, int b)
        {
            return [a, b];
        }

        int[] opSliceAssign(int val, int a, int b)
        {
            return [val, a, b];
        }

        int[] opSliceOpAssign(string op)(int val, int a, int b)
        {
            return [val, a, b];
        }

        int opDollar()
        {
            return 8;
        }
    }

    SliceExp slice;
    // opSlice
    assert(slice[0 .. 8]     == [0, 8]);
    assert(slice[0 .. $]     == [0, 8]);
    assert(slice[0 .. $-1]   == [0, 7]);
    assert(slice[$-3 .. $-1] == [5, 7]);
    // opSliceUnary
    assert(-slice[0 .. 8]     == [0, 8]);
    assert(-slice[0 .. $]     == [0, 8]);
    assert(-slice[0 .. $-1]   == [0, 7]);
    assert(-slice[$-3 .. $-1] == [5, 7]);
    // opSliceAssign
    assert((slice[0 .. 8]     = 2) == [2, 0, 8]);
    assert((slice[0 .. $]     = 2) == [2, 0, 8]);
    assert((slice[0 .. $-1]   = 2) == [2, 0, 7]);
    assert((slice[$-3 .. $-1] = 2) == [2, 5, 7]);
    // opSliceOpAssign
    assert((slice[0 .. 8]     += 2) == [2, 0, 8]);
    assert((slice[0 .. $]     += 2) == [2, 0, 8]);
    assert((slice[0 .. $-1]   += 2) == [2, 0, 7]);
    assert((slice[$-3 .. $-1] += 2) == [2, 5, 7]);

    // test different kinds of opDollar
    auto dollar(string opDollar)()
    {
        static struct Dollar
        {
            size_t opIndex(size_t a) { return a; }
            mixin(opDollar);
        }
        Dollar d;
        return d[$];
    }
    assert(dollar!q{@property size_t opDollar() { return 8; }}() == 8);
    assert(dollar!q{template opDollar(size_t dim) { enum opDollar = dim; }}() == 0);
    assert(dollar!q{const size_t opDollar = 8;}() == 8);
    assert(dollar!q{enum opDollar = 8;}() == 8);
    assert(dollar!q{size_t length() { return 8; } alias length opDollar;}() == 8);
}

/**************************************/

void test19()
{
    static struct Foo
    {
        int[] opSlice(int a, int b)
        {
            return [a, b];
        }

        int opDollar(int dim)()
        {
            return dim;
        }
    }

    Foo foo;
    assert(foo[0 .. $] == [0, 0]);
}

/**************************************/

int main()
{
    test1();
    test2();
    test3();
    test4();
    test5();
    test6();
    test7();
    test8();
    test9();
    test10();
    test11();
    test4099();
    test12();
    test13();
    test14();
    test15();
    test16();
    test17();
    test7641();
    test8434();
    test18();
    test19();

    printf("Success\n");
    return 0;
}

