// REQUIRED_ARGS: -O
// Floating-point addition is not associative, so ((x + c) + y) must not be
// regrouped as ((x + y) + c).

float addF(float x, float y)
{
    return (x + 25.0f) + y;
}

double addD(double x, double y)
{
    return (x + 1.0) + y;
}

void main()
{
    // 22.5 + 25 is exact; adding y then rounds once.
    if (addF(22.5f, -0x1.f579dcp+0f) != 0x1.6c5432p+5f)
        assert(0);

    // 1e16 + 1 rounds back to 1e16, so the sum is 0, not 1.
    if (addD(1e16, -1e16) != 0.0)
        assert(0);
}
