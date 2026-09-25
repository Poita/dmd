// Negated float locals reused in later float arithmetic.
struct Vec3
{
    float x = 0, y = 0, z = 0;
    Vec3 opBinary(string op)(const Vec3 r) const if (op == "+")
    {
        return Vec3(x + r.x, y + r.y, z + r.z);
    }
}

Vec3[8] corners;

void wedge(Vec3 c, Vec3 size, float noseFrac) @safe
{
    const hx = size.x * 0.5f, hy = size.y * 0.5f, hz = size.z * 0.5f;
    const tz = hz - size.z * noseFrac;
    const b00 = c + Vec3(-hx, -hy, -hz), b10 = c + Vec3(hx, -hy, -hz);
    const b01 = c + Vec3(-hx, -hy, hz), b11 = c + Vec3(hx, -hy, hz);
    const t00 = c + Vec3(-hx, hy, -hz), t10 = c + Vec3(hx, hy, -hz);
    const t01 = c + Vec3(-hx, hy, tz), t11 = c + Vec3(hx, hy, tz);
    () @trusted { corners = [b00, b10, b01, b11, t00, t10, t01, t11]; }();
}

void main()
{
    wedge(Vec3(1, 2, 3), Vec3(2, 4, 6), 0.5f);
    assert(corners[0] == Vec3(0, 0, 0));
    assert(corners[1] == Vec3(2, 0, 0));
    assert(corners[3] == Vec3(2, 0, 6));
    assert(corners[6] == Vec3(0, 4, 3));
    assert(corners[7] == Vec3(2, 4, 3));
}
