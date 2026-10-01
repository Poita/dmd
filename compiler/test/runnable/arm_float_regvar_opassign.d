// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Floating point op= on register variables, including right operands
 * that read the variable being assigned.
 */

float accum(const(float)[] a, float k)
{
    float sum = 0, prod = 1, diff = 100, q = 1024;
    foreach (x; a)
    {
        sum += x * k;
        prod *= x;
        diff -= sum;
        q /= 2;
    }
    return sum + prod + diff + q;
}

double self(double x, int n)
{
    foreach (i; 0 .. n)
    {
        x += x;
        x -= x * 0.25;
        x *= x > 4 ? 0.5 : 1.0;
        x /= x + 1 > 0 ? 1.0 : 2.0;
    }
    return x;
}

double sumOfSquares(double a, double b)
{
    double r = 0;
    foreach (i; 0 .. 3)
    {
        r += a * a;
        r += b;
        a -= 1;
    }
    return r;
}

int main()
{
    float[3] a = [1, 2, 3];
    // sum: 2, 6, 12; prod: 6; diff: 100-2-6-12 = 80; q: 128
    assert(accum(a[], 2) == 12 + 6 + 80 + 128);
    double x = 1;
    foreach (i; 0 .. 5)
    {
        x += x;
        x -= x * 0.25;
        x *= x > 4 ? 0.5 : 1.0;
        x /= x + 1 > 0 ? 1.0 : 2.0;
    }
    assert(self(1, 5) == x);
    // a: 3, 2, 1 -> 9 + 4 + 1 + 3 * 0.5
    assert(sumOfSquares(3, 0.5) == 15.5);
    return 0;
}
