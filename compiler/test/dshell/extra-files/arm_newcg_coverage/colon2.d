// Branches whose arms the optimizer merges into a ?: of the alternate kind, as
// the returns of either of two values and the assignments of either.
module colon2;

int pick(const(int)[] a, const(int)[] b, int x, int y)
{
    if (a is b)
        return x;
    return y;
}

float clampf(float v, float lo, float hi)
{
    if (v < lo)
        return lo;
    if (v > hi)
        return hi;
    return v;
}

long choose(long a, long b, bool c)
{
    long r;
    if (c)
        r = a * 3;
    else
        r = b;
    return r;
}

double chooseD(double a, double b, int c)
{
    double r;
    if (c > 2)
        r = a + 1;
    else
        r = b;
    return r * 2;
}

string name(int k, string a, string b)
{
    if (k & 1)
        return a;
    return b;
}

struct V2 { float x, y; }

V2 pickV(V2 a, V2 b, bool c)
{
    if (c)
        return a;
    return b;
}

int main()
{
    int[4] buf = [1, 2, 3, 4];
    assert(pick(buf[], buf[], 5, 6) == 5);
    assert(pick(buf[], buf[1 .. $], 5, 6) == 6);
    assert(clampf(5, 0, 1) == 1 && clampf(-5, 0, 1) == 0 && clampf(0.5f, 0, 1) == 0.5f);
    assert(choose(2, 7, true) == 6 && choose(2, 7, false) == 7);
    assert(chooseD(1, 7, 3) == 4 && chooseD(1, 7, 2) == 14);
    assert(name(1, "a", "b") == "a" && name(2, "a", "b") == "b");
    assert(pickV(V2(1, 2), V2(3, 4), true) == V2(1, 2) && pickV(V2(1, 2), V2(3, 4), false) == V2(3, 4));
    return 0;
}
