/* REQUIRED_ARGS: -inline -release
 */

// A common subexpression first evaluated as a condition must still set the
// condition codes, not only load its value into a register.

struct Array
{
    size_t* ptr;
    size_t length;
    size_t visited;

    void shrink(size_t n)
    {
        if (length)
            foreach (v; ptr[n .. length])
                visited += v;
    }
}

void main()
{
    size_t[4] buf = [1, 2, 3, 4];
    Array a;
    a.ptr = buf.ptr;
    foreach (n; 0 .. 3)
        if (n != 7)                 // leaves "not equal" in the flags
            a.shrink(n + 1);        // length is 0, so the loop must not run
    assert(a.visited == 0);

    a.length = 4;
    a.shrink(2);
    assert(a.visited == 7);
}
