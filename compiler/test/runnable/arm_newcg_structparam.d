/* REQUIRED_ARGS: -O
 */
// Struct parameters passed in one or two integer registers, read and written by
// field and whole, in loops, passed on, and with their address taken

struct Range { int* lo; int* hi; }
struct Small { uint a; ushort b; ubyte c; }
struct Word { long w; }

long sum(Range r)
{
    long s;
    Range[4] stack;
    size_t pos;
    for (;;)
    {
        while (r.lo < r.hi)
        {
            if (*r.lo < 0 && pos < stack.length)
            {
                stack[pos++] = Range(r.lo + 1, r.hi);     // the rest, later
                r = Range(r.lo + 1, r.lo + 1);
                continue;
            }
            s += *r.lo;
            ++r.lo;
        }
        if (!pos)
            break;
        r = stack[--pos];
    }
    return s;
}

int small(Small x, int k)
{
    foreach (i; 0 .. k)
    {
        x.a += i;
        x.c ^= cast(ubyte)i;
    }
    return x.a + x.b + x.c;
}

Word twice(Word w) { w.w *= 2; return w; }

long chain(Word w, int n)
{
    foreach (i; 0 .. n)
        w = twice(w);
    return w.w;
}

int* where(Range r) { return &r.hi is null ? null : r.lo; }

void main()
{
    int[] a = [1, 2, -3, 4, 5];
    assert(sum(Range(a.ptr, a.ptr + a.length)) == 1 + 2 + 4 + 5 + 0);
    assert(sum(Range(a.ptr, a.ptr)) == 0);
    assert(small(Small(10, 20, 30), 4) == 10 + 6 + 20 + (30 ^ 0 ^ 1 ^ 2 ^ 3));
    assert(chain(Word(3), 5) == 96);
    assert(where(Range(a.ptr, a.ptr + 1)) is a.ptr);
}
