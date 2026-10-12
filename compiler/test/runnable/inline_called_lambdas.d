/* REQUIRED_ARGS: -inline -O
 */
// Functions whose function literals, called where they are made, refer to their
// variables, inlined once those calls are, next to ones whose literals escape

struct Buf
{
    int[] data;
    size_t used;

    void put(int x)
    {
        immutable len = used;
        auto slot = (() @trusted => data.ptr + len)();
        auto value = (() => x * 2)();
        *slot = value;
        used = len + 1;
    }
}

int twice(int a)
{
    int b = a;
    return (() => b + b)();
}

// the literal outlives the call, so the variable it refers to must too
int delegate() keep(int a)
{
    int b = a + 1;
    return () => b * 3;
}

// a nested function called but not inlined still sees the variables
int viaNested(int a)
{
    int b = a;
    int bump(int k) { foreach (i; 0 .. k) b += i; return b; }
    return bump(4) + b;
}

int user(int n)
{
    Buf b;
    b.data = new int[](n);
    foreach (i; 0 .. n)
        b.put(i);
    int s;
    foreach (x; b.data)
        s += x;
    return twice(cast(int)b.used) + s;
}

void main()
{
    assert(user(4) == 8 + 2 * (0 + 1 + 2 + 3));
    auto d1 = keep(1), d2 = keep(10);
    assert(d1() == 6 && d2() == 33);
    assert(viaNested(5) == 2 * (5 + 6));
}
