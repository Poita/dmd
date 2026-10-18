// The addresses of homogeneous float aggregates, and pointer arithmetic on
// arrays of them, are addresses rather than the aggregates' values.
module hfa_address;

struct V2
{
    float x, y;
    V2 opBinary(string op)(V2 b) const { return mixin("V2(x " ~ op ~ " b.x, y " ~ op ~ " b.y)"); }
    V2 opBinary(string op : "*")(float s) const { return V2(x * s, y * s); }
    float length() const { import core.math : sqrt; return sqrt(x * x + y * y); }
    V2 normalized() const
    {
        const len = length;
        return len > 0 ? V2(x / len, y / len) : V2(0, 0);
    }
    V2 perp() const { return V2(-y, x); }
}

V2[4] quad(V2 a, V2 b, float t)
{
    const p = (b - a).normalized.perp * t;
    return [a + p, b + p, b - p, a - p];
}

float signedArea(const(float[2])[] poly)
{
    float s = 0;
    foreach (i; 0 .. poly.length)
    {
        const a = poly[i], b = poly[(i + 1) % poly.length];
        s += a[0] * b[1] - b[0] * a[1];
    }
    return s * 0.5f;
}

bool inside(float[2] p, const(float[2])[] poly)
{
    bool c;
    for (size_t i = 0, j = poly.length - 1; i < poly.length; j = i++)
    {
        const a = poly[i], b = poly[j];
        if ((a[1] > p[1]) != (b[1] > p[1]) && p[0] < (b[0] - a[0]) * (p[1] - a[1]) / (b[1] - a[1]) + a[0])
            c = !c;
    }
    return c;
}

int main()
{
    const q = quad(V2(0, 0), V2(10, 0), 2);
    assert(q[0] == V2(0, 2) && q[1] == V2(10, 2) && q[2] == V2(10, -2) && q[3] == V2(0, -2));
    const z = quad(V2(1, 1), V2(1, 1), 2);
    assert(z[0] == V2(1, 1));
    float[2][4] sq = [[0, 0], [2, 0], [2, 2], [0, 2]];
    assert(signedArea(sq[]) == 4);
    assert(inside([1, 1], sq[]));
    assert(!inside([3, 1], sq[]));
    return 0;
}
