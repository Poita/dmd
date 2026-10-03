// REQUIRED_ARGS: -O -release
// A nested function reads and writes the variables of its enclosing function
// through the static link, at negative offsets from it.

pragma(inline, false) float outer(uint n, float r)
{
    uint count = n;
    float scale = r;
    float total = 0;
    pragma(inline, false) void splat(float x)
    {
        total += x * scale + count * 0.25f;
        ++count;
    }
    splat(1);
    splat(2);
    return total + count;
}

void main()
{
    if (!(outer(4, 2.0f) == 14.25f)) assert(0);
}
