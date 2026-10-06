/* REQUIRED_ARGS: -O
 */
// Copies of variables read before and after the variables change

pragma(inline, false) float worst(const float[] xs)
{
    float w = 0;
    foreach (x; xs)
    {
        const s = x * x;
        if (s > w)
            w = s;
    }
    return w;
}

pragma(inline, false) int swapSum(int a, int b, int n)
{
    foreach (i; 0 .. n)
    {
        const t = a;
        a = b;
        b = t + i;
    }
    return a * 3 + b;
}

pragma(inline, false) long fib(int n)
{
    long x = 0, y = 1;
    foreach (_; 0 .. n)
    {
        const old = x;
        x = y;
        y = old + y;
    }
    return x;
}

void main()
{
    if (worst([1.5f, -3, 2]) != 9) assert(0);
    if (swapSum(1, 2, 5) != 25) assert(0);    // a, b = 6, 7
    if (fib(50) != 12586269025) assert(0);
}
