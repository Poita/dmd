// A 16-byte aggregate returned in x0:x1 and passed straight on in x1:x2.

struct UUID
{
    ubyte[16] data;

    this(const ubyte[16] d) { data = d; }

    bool empty() const
    {
        foreach (b; data)
            if (b)
                return false;
        return true;
    }
}

ubyte[16] getData(size_t i)
{
    ubyte[16] data;
    data[i] = 1;
    return data;
}

struct S { long a, b; }

S make(long a, long b) { return S(a, b); }

pragma(inline, false)
long second(int x, S s) { return s.b * 10 + s.a + x; }

void main()
{
    foreach (i; 0 .. 16)
        assert(!UUID(getData(i)).empty);
    assert(second(0, make(1, 2)) == 21);
}
