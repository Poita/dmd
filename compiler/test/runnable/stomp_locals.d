// REQUIRED_ARGS: -gx
// Stomping the stack frame on function exit leaves callers working.

int sum(int n)
{
    int[16] a;
    foreach (i, ref x; a)
        x = cast(int) i;
    int s = n;
    foreach (x; a)
        s += x;
    return s;
}

long deep(long n) { return n ? deep(n - 1) + n : 0; }

void main()
{
    assert(sum(1) == 121);
    assert(deep(100) == 5050);
    try
        throw new Exception("x");
    catch (Exception e)
        assert(e.msg == "x");
}
