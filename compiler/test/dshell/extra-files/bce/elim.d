// The array bounds checks of each function named elim_... are all provably
// redundant, each function named one_... needs exactly one, and each named
// keep_... keeps at least one
import core.exception : RangeError;

@safe:

int elim_foreachRange(int[] a)
{
    int s;
    foreach (i; 0 .. a.length)
        s += a[i];
    return s;
}

int elim_forLength(int[] a)
{
    int s;
    for (size_t i = 0; i < a.length; ++i)
        s += a[i];
    return s;
}

int elim_while(int[] a)
{
    int s;
    size_t i;
    while (i < a.length)
    {
        s += a[i];
        i++;
    }
    return s;
}

int elim_guard(int[] a, size_t i)
{
    if (i < a.length)
        return a[i];
    return -1;
}

int elim_guardReturn(int[] a, size_t i)
{
    if (i >= a.length)
        return -1;
    return a[i] * 3;
}

int one_repeat(int[] a, size_t i)
{
    int x = a[i];
    int y = a[i];
    return x * y + a[i];
}

void elim_copy(int[] a, int[] b)
{
    if (b.length < a.length)
        return;
    foreach (i; 0 .. a.length)
        b[i] = a[i];
}

void elim_sameLength(int[] a, int[] b)
{
    if (a.length != b.length)
        return;
    foreach (i; 0 .. a.length)
        b[i] = a[i] + 1;
}

int elim_constants(int[] a)
{
    if (a.length > 2)
        return a[0] + a[1] + a[2];
    return 0;
}

int elim_nonEmpty(int[] a)
{
    if (a.length == 0)
        return 0;
    return a[0];
}

int elim_nested(int[] a, int[] b)
{
    int s;
    foreach (i; 0 .. a.length)
        foreach (j; 0 .. b.length)
            s += a[i] * b[j];
    return s;
}

int elim_static(ref int[8] a, size_t i)
{
    if (i < 8)
        return a[i];
    return 0;
}

int keep_offByOne(int[] a)
{
    int s;
    for (size_t i = 0; i <= a.length; ++i)
        s += a[i];
    return s;
}

int keep_plusOne(int[] a)
{
    int s;
    foreach (i; 0 .. a.length)
        s += a[i + 1];
    return s;
}

int keep_otherArray(int[] a, int[] b)
{
    int s;
    foreach (i; 0 .. a.length)
        s += b[i];
    return s;
}

int keep_shrunk(int[] a)
{
    int s;
    foreach (i; 0 .. a.length)
    {
        a = a[0 .. $ - i];
        s += a[i];
    }
    return s;
}

void main() @trusted
{
    int[] a = [1, 2, 3, 4];
    int[] b = new int[4];
    int[8] sa = [1, 2, 3, 4, 5, 6, 7, 8];
    if (elim_foreachRange(a) != 10 || elim_forLength(a) != 10 || elim_while(a) != 10)
        assert(0);
    if (elim_guard(a, 3) != 4 || elim_guard(a, 4) != -1 || elim_guardReturn(a, 1) != 6)
        assert(0);
    if (one_repeat(a, 2) != 12 || elim_constants(a) != 6 || elim_nonEmpty(a) != 1 || elim_nonEmpty(null) != 0)
        assert(0);
    elim_copy(a, b);
    if (b != a)
        assert(0);
    elim_sameLength(a, b);
    if (b != [2, 3, 4, 5])
        assert(0);
    if (elim_nested(a, b) != 140 || elim_static(sa, 7) != 8)
        assert(0);
    bool thrown;
    try keep_offByOne(a); catch (RangeError) thrown = true;
    if (!thrown)
        assert(0);
}
