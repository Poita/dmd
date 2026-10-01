// PERMUTE_ARGS: -O -inline -release

// Calls through the address of a function, called directly

pragma(inline, false) ulong twice(ulong x) { return x * 2; }
pragma(inline, false) float half(float x) { return x / 2; }
pragma(inline, false) noreturn fail(int x) { throw new Exception("fail"); }

pragma(inline, false) ulong repeated(ulong a)
{
    ulong s;
    foreach (i; 0 .. 4)
        s += (*&twice)(a + i) + (*&twice)(i);
    return s;
}

void main()
{
    assert((*&twice)(21) == 42);
    assert((*&half)(3) == 1.5f);
    assert(repeated(1) == 2 * (1 + 2 + 3 + 4) + 2 * (0 + 1 + 2 + 3));
    bool caught;
    try
        (*&fail)(1);
    catch (Exception)
        caught = true;
    assert(caught);
}
