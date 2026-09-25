// Nested structs with over-aligned fields reach their enclosing frame through a context pointer.
void test()
{
    int i;
    struct Nested
    {
        align(32) // better still find context pointer correctly!
        int[3] stuff = [0, 1, 2];
        ~this() { ++i; }
    }

    static struct NoAssign
    {
        int value;
        @disable void opAssign(typeof(this));
    }

    static struct NotNested
    {
        int before = 42;
        align(Nested.alignof * 4) // better still find context pointer correctly!
        Nested n;
        auto after = NoAssign(43);
    }

    static struct Deep
    {
        NotNested nn;
    }

    static struct Deeper
    {
        NotNested[1] nn;
    }

    static assert(!__traits(isZeroInit, Nested));
    static assert(!__traits(isZeroInit, NotNested));
    static assert(!__traits(isZeroInit, Deep));
    static assert(!__traits(isZeroInit, Deeper));

    {
        auto a = NotNested(1, Nested([3, 4, 5]), NoAssign(2));
        auto b = move(a);
        assert(b.n.tupleof[$-1]);
        assert(a.n.tupleof[$-1] is b.n.tupleof[$-1]);
        assert(a.n.stuff == [0, 1, 2]);
        assert(a.before == 42);
        assert(a.after == NoAssign(43));

        auto c = Deep(NotNested(1, Nested([3, 4, 5]), NoAssign(2)));
        auto d = move(c);
        assert(d.nn.n.tupleof[$-1]);
        assert(c.nn.n.tupleof[$-1] is d.nn.n.tupleof[$-1]);
        assert(c.nn.n.stuff == [0, 1, 2]);
        assert(c.nn.before == 42);
        assert(c.nn.after == NoAssign(43));

        auto e = Deeper([NotNested(1, Nested([3, 4, 5]), NoAssign(2))]);
        auto f = move(e);
        assert(f.nn[0].n.tupleof[$-1]);
        assert(e.nn[0].n.tupleof[$-1] is f.nn[0].n.tupleof[$-1]);
        assert(e.nn[0].n.stuff == [0, 1, 2]);
        assert(e.nn[0].before == 42);
        assert(e.nn[0].after == NoAssign(43));
    }
    assert(i == 6);
}

void main() { test(); }
