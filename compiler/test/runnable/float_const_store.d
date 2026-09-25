// Floating point constants stored directly to memory keep their value.

struct F2 { float a, b; }
struct D2 { double a, b; }

void main()
{
    F2 f = F2(1.5f, 2.0f);
    assert(f.a + f.b == 3.5f);

    float[3] a = [3.0f, 4.0f, 0.5f];
    assert(a[0] + a[1] + a[2] == 7.5f);

    D2 d = D2(1.5, 0.25);
    assert(d.a + d.b == 1.75);

    double[2] b = [5.0, 0.75];
    assert(b[0] + b[1] == 5.75);
}
