// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Local dynamic arrays, delegates and 16 byte structs of two integers or
 * pointers split into a variable per element.
 */

struct P { long a; size_t b; }
struct G { uint n; int[] h; }

pragma(inline, false) int[] make(int n) { auto r = new int[](n); foreach (i, ref x; r) x = cast(int) i * 2; return r; }
pragma(inline, false) size_t total(const(int)[] a) { size_t s; foreach (x; a) s += x; return s; }
pragma(inline, false) P makeP(long a) { return P(a, a + 1); }

size_t slices(ref const G g, int n)
{
    const h = g.h;                      // load from memory
    const(int)[] t = h[1 .. $];         // pair from a slice expression
    size_t s = t.length + h[0];
    const(int)[] u = make(n);           // whole write from a call
    s += total(u);                      // whole read as an argument
    u = t;                              // copy
    s += u[0] + u.length;
    u = null;                           // constant
    s += u.length;
    return s;
}

int[] reslice(int[] a)
{
    int[] b = a;
    while (b.length > 2)
        b = b[1 .. $];
    return b;                           // whole read as the return value
}

long pairs(long x)
{
    P p = makeP(x);
    P q = p;
    q.a += 10;
    p.b *= 2;
    return p.a + p.b + q.a + q.b;
}

int delegates(int k)
{
    int base = k;
    int delegate(int) dg = (int x) => x + base;
    auto d2 = dg;
    return d2(5) + dg(1);
}

int main()
{
    int[4] arr = [7, 8, 9, 10];
    G g = G(4, arr[]);
    // t = [8,9,10] -> 3 + 7 = 10; make(3) = [0,2,4] -> 6; u = t -> 8 + 3; null -> 0
    assert(slices(g, 3) == 10 + 6 + 11);
    int[5] a = [1, 2, 3, 4, 5];
    assert(reslice(a[]) == [4, 5]);
    // p = (5, 6) -> b = 12; q = (15, 6)
    assert(pairs(5) == 5 + 12 + 15 + 6);
    assert(delegates(3) == 8 + 4);
    return 0;
}
