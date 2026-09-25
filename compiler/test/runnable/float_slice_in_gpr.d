// A struct passed in a general register whose slices include a float.

struct S { float f; int i; }
struct D { double d; long l; }

int g(S s) { return cast(int)(s.f * 2) + s.i; }
long h(D x) { return cast(long)(x.d * 2) + x.l; }

void main()
{
    assert(g(S(1.5f, 4)) == 7);
    assert(h(D(2.5, 10)) == 15);
}
