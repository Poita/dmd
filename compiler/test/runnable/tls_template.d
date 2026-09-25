// Thread local variables in template instances get a TLV descriptor on Mach-O.

template T(int n)
{
    int tv = n;
    long[2] tarr;
}

struct S(U)
{
    static U cache;
    static U get() { return cache; }
}

int plain = 4;
int plainBss;

void main()
{
    T!1.tv += 1;
    T!2.tarr[1] = 7;
    assert(T!1.tv == 2 && T!2.tv == 2 && T!2.tarr[1] == 7);
    S!int.cache = 3;
    S!double.cache = 1.5;
    assert(S!int.get() == 3 && S!double.get() == 1.5);
    plainBss = plain + 1;
    assert(plainBss == 5);

    import core.thread : Thread;
    auto t = new Thread({ assert(T!1.tv == 1 && S!int.cache == 0 && plain == 4); T!1.tv = 9; });
    t.start();
    t.join();
    assert(T!1.tv == 2);
}
