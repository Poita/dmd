// Floating point parameters of a function with a frame too large for a scaled
// immediate offset.

double f(double a, float b, double c)
{
    ubyte[70_000] big = void;
    big[0] = 1;
    big[$ - 1] = 2;
    return a + b + c + big[0] + big[$ - 1];
}

void main()
{
    assert(f(1.5, 2.5f, 3) == 10);
}
