/* REQUIRED_ARGS: -O
 */
// A call whose result is returned replaces the caller's frame when no local of the
// caller can still be referred to: mutual recursion far deeper than the stack, a
// local whose address is taken on another path, and a local whose address is passed
// along, which keeps its frame

pragma(inline, false) bool isEven(long n)
{
    if (n == 0)
        return true;
    return isOdd(n - 1);
}

pragma(inline, false) bool isOdd(long n)
{
    if (n == 0)
        return false;
    return isEven(n - 1);
}

pragma(inline, false) double halve(double x, long n)
{
    if (n == 0)
        return x;
    return halveAgain(x * 0.5, n - 1);
}

pragma(inline, false) double halveAgain(double x, long n)
{
    if (n == 0)
        return x;
    return halve(x, n);
}

pragma(inline, false) void fill(int* p, int v) { *p = v; }

// the address of x is taken only on the path that returns x
pragma(inline, false) long steps(long n, long acc)
{
    if (n < 0)
    {
        int x;
        fill(&x, 42);
        return x;
    }
    if (n == 0)
        return acc;
    return stepsAgain(n - 1, acc + 1);
}

pragma(inline, false) long stepsAgain(long n, long acc)
{
    return steps(n, acc);
}

// returns that are conditional expressions, one of them taking an address
pragma(inline, false) long ping(long n, long acc)
{
    return n == 0 ? acc : pong(n - 1, acc + 2);
}

pragma(inline, false) long filled(int* p)
{
    fill(p, 5);
    return *p;
}

// the call given the address of x keeps the frame x is in
pragma(inline, false) long pong(long n, long acc)
{
    int x;
    return n < 0 ? filled(&x) : n == 0 ? acc : ping(n - 1, acc + 1);
}

// returns the optimizer merges into one block
pragma(inline, false) long left(long n, int k)
{
    if (n == 0)
        return k;
    if (k & 1)
        return right(n - 1, k + 3);
    return right(n - 1, k + 1);
}

pragma(inline, false) long right(long n, int k)
{
    if (n == 0)
        return -k;
    if (k & 2)
        return left(n - 1, k ^ 1);
    return left(n - 1, k + 2);
}

// a returned call the code generator expands in place, which is no call to make
shared ubyte level = 3;
pragma(inline, false) ubyte loadLevel()
{
    import core.atomic : atomicLoad, MemoryOrder;
    return atomicLoad!(MemoryOrder.acq)(level);
}

// reads what p points to after using a frame of its own
pragma(inline, false) int peek(int* p, int k)
{
    int[64] junk = 7;
    fill(&junk[k], 9);
    return *p + junk[k];
}

// x must outlive the call that is given its address
pragma(inline, false) int keep(int n)
{
    int x = n * 3;
    return peek(&x, n & 63);
}

void main()
{
    assert(isEven(10_000_000));
    assert(!isOdd(10_000_000));
    assert(halve(1024.0, 10_000_000) == 0);
    assert(halve(1024.0, 4) == 64);
    assert(steps(10_000_000, 0) == 10_000_000);
    assert(steps(-1, 0) == 42);
    assert(ping(10_000_000, 0) == 15_000_000);
    assert(pong(-1, 0) == 5);
    assert(left(10_000_000, 0) != 0);
    assert(loadLevel() == 3);
    foreach (n; 0 .. 100)
        assert(keep(n) == n * 3 + 9);
}
