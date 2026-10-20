// Each array access here can be out of bounds, so whether the optimizer
// removes bounds checks or not, each one raises a RangeError at its line.
import core.exception : RangeError;

@safe:

size_t line;

int lengthChanged(int[] a)
{
    int s;
    foreach (i; 0 .. a.length)
    {
        a = a[0 .. $ - 1];
        line = __LINE__; s += a[i];
    }
    return s;
}

int sliceReassigned(int[] a, int[] b)
{
    int s;
    for (size_t i = 0; i < a.length; ++i)
    {
        if (i == 2)
            a = b;
        line = __LINE__; s += a[i];
    }
    return s;
}

int aliasRef(ref int[] a, ref int[] b)
{
    int s;
    foreach (i; 0 .. a.length)
    {
        b = b[0 .. 1];
        line = __LINE__; s += a[i];
    }
    return s;
}

int aliasPointer(int[]* pa, int[]* pb)
{
    int s;
    for (size_t i = 0; i < (*pa).length; ++i)
    {
        *pb = null;
        line = __LINE__; s += (*pa)[i];
    }
    return s;
}

int offByOne(int[] a)
{
    int s;
    for (size_t i = 0; i <= a.length; ++i)
    {
        line = __LINE__; s += a[i];
    }
    return s;
}

int decreasing(int[] a)
{
    int s;
    for (size_t i = a.length; i != size_t.max; --i)
    {
        line = __LINE__; s += a[i];
    }
    return s;
}

int wraparound(int[] a, size_t i)
{
    if (i < a.length)
    {
        line = __LINE__; return a[i - 1];
    }
    return 0;
}

int wrapGuard(int[] a, size_t i)
{
    if (i + 1 < a.length)
    {
        line = __LINE__; return a[i];
    }
    return 0;
}

int nested(int[] a, int[] b)
{
    int s;
    foreach (i; 0 .. a.length)
        foreach (j; 0 .. b.length)
        {
            line = __LINE__; s += a[j];
        }
    return s;
}

int plusOne(int[] a)
{
    int s;
    foreach (i; 0 .. a.length)
    {
        line = __LINE__; s += a[i + 1];
    }
    return s;
}

int[] g;

void shrink() { g = g[0 .. $ / 2]; }

int globalModified()
{
    int s;
    foreach (i; 0 .. g.length)
    {
        shrink();
        line = __LINE__; s += g[i];
    }
    return s;
}

struct S
{
    int[] arr;
    void cut() { arr = arr[0 .. 1]; }
}

int fieldModified(ref S st)
{
    int s;
    foreach (i; 0 .. st.arr.length)
    {
        st.cut();
        line = __LINE__; s += st.arr[i];
    }
    return s;
}

int jagged(int[][] m)
{
    int s;
    foreach (i; 0 .. m.length)
        foreach (j; 0 .. m[0].length)
        {
            line = __LINE__; s += m[i][j];
        }
    return s;
}

int signedIndex(int[] a)
{
    int s;
    for (int i = -1; i < cast(int) a.length; i++)
    {
        line = __LINE__; s += a[i];
    }
    return s;
}

int modifiedAfterTest(int[] a)
{
    int s;
    for (size_t i = 0; i < a.length; i++)
    {
        i += 1;
        line = __LINE__; s += a[i];
    }
    return s;
}

int afterLoop(int[] a)
{
    size_t i;
    for (i = 0; i < a.length; i++)
    {
    }
    line = __LINE__; return a[i];
}

int staticOffByOne(ref int[4] a)
{
    int s;
    for (size_t i = 0; i <= 4; i++)
    {
        line = __LINE__; s += a[i];
    }
    return s;
}

int guardWrongWay(int[] a, size_t i)
{
    if (i > a.length)
        return 0;
    line = __LINE__; return a[i];
}

int guardElse(int[] a, size_t i)
{
    if (i < a.length)
        return 0;
    line = __LINE__; return a[i];
}

int signedGuard(int[] a, long i)
{
    if (i < cast(long) a.length)
    {
        line = __LINE__; return a[cast(size_t) i];
    }
    return 0;
}

int shortLimit(int[] a, int[] b)
{
    int s;
    if (b.length < a.length - 1)
        return 0;
    foreach (i; 0 .. a.length)
    {
        line = __LINE__; s += b[i];
    }
    return s;
}

int catchesInLoop(int[] a)
{
    int s;
    size_t i = 0;
    try
    {
        for (; i < a.length; i++)
            s += a[i];
        i = a.length + 1;
        throw new Exception("");
    }
    catch (Exception)
    {
        line = __LINE__; s += a[i];
    }
    return s;
}

void expect(lazy int r, string name) @trusted
{
    line = 0;
    try
    {
        r;
    }
    catch (RangeError e)
    {
        if (e.line != line || line == 0)
            assert(0, name);
        return;
    }
    assert(0, name);
}

void main() @trusted
{
    int[] a = [1, 2, 3, 4];
    int[] b = [1, 2];
    expect(lengthChanged(a.dup), "lengthChanged");
    expect(sliceReassigned(a.dup, b), "sliceReassigned");
    int[] c = a.dup;
    expect(aliasRef(c, c), "aliasRef");
    c = a.dup;
    expect(aliasPointer(&c, &c), "aliasPointer");
    expect(offByOne(a), "offByOne");
    expect(decreasing(a), "decreasing");
    expect(wraparound(a, 0), "wraparound");
    expect(wrapGuard(a, size_t.max), "wrapGuard");
    expect(nested(b, a), "nested");
    expect(plusOne(a), "plusOne");
    g = a.dup;
    expect(globalModified(), "globalModified");
    S st = S(a.dup);
    expect(fieldModified(st), "fieldModified");
    expect(jagged([[1, 2, 3], [1]]), "jagged");
    expect(signedIndex(a), "signedIndex");
    expect(modifiedAfterTest([1, 2, 3]), "modifiedAfterTest");
    expect(afterLoop(a), "afterLoop");
    int[4] sa;
    expect(staticOffByOne(sa), "staticOffByOne");
    expect(guardWrongWay(a, 4), "guardWrongWay");
    expect(guardElse(a, 4), "guardElse");
    expect(signedGuard(a, -1), "signedGuard");
    expect(shortLimit(a, [1, 2, 3]), "shortLimit");
    expect(catchesInLoop(a), "catchesInLoop");
}
