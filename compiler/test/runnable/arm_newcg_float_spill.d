// REQUIRED_ARGS: -O -release
// More live doubles than float registers forces spills through the scratch registers v29-v31.

pragma(inline, false) double many(double x)
{
    double a0 = x + 1, a1 = x * 2, a2 = x + 3, a3 = x * 4, a4 = x + 5, a5 = x * 6, a6 = x + 7, a7 = x * 8;
    double b0 = a0 * a1, b1 = a1 * a2, b2 = a2 * a3, b3 = a3 * a4, b4 = a4 * a5, b5 = a5 * a6, b6 = a6 * a7, b7 = a7 * a0;
    double c0 = b0 + a3, c1 = b1 + a4, c2 = b2 + a5, c3 = b3 + a6, c4 = b4 + a7, c5 = b5 + a0, c6 = b6 + a1, c7 = b7 + a2;
    double d0 = c0 - b4, d1 = c1 - b5, d2 = c2 - b6, d3 = c3 - b7, d4 = c4 - b0, d5 = c5 - b1, d6 = c6 - b2, d7 = c7 - b3;
    return a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7
         + b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7
         + c0 + c1 + c2 + c3 + c4 + c5 + c6 + c7
         + d0 + d1 + d2 + d3 + d4 + d5 + d6 + d7;
}

void main()
{
    if (!(many(0.5) == 280)) assert(0);
    if (!(many(-3.0) == -504)) assert(0);
    if (!(many(7.0) == 6936)) assert(0);
}
