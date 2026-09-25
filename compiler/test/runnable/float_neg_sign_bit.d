// Negating a float that the optimizer does as an integer sign bit flip, with
// the result wanted in a floating point register.

struct M { float[6] m; bool h; }

M ortho(float l, float r, float b, float t, float n, float f, bool h)
{
    M x;
    x.m = [l, r, b, t, n, f];
    x.h = h;
    return x;
}

M fit(const float[] ds, float z, bool h)
{
    float radius = 0;
    foreach (d; ds)
        if (d > radius)
            radius = d;
    return ortho(-radius, radius, -radius, radius, 0, 2 * radius + 2 * z, h);
}

void main()
{
    float[3] ds = [1, 3, 2];
    auto m = fit(ds[], 1, true);
    assert(m.m == [-3.0f, 3, -3, 3, 0, 8] && m.h);
}
