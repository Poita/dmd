// Absolute value of integers, which the optimizer recognizes.

long absl(long x) { return x >= 0 ? x : -x; }
int absi(int x) { return x < 0 ? -x : x; }

void main()
{
    assert(absl(-50_000) == 50_000 && absl(7) == 7 && absl(0) == 0);
    assert(absi(-3) == 3 && absi(4) == 4);
    assert(absl(long.min + 1) == long.max);
}
