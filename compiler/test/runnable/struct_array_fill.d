// Filling arrays of small structs, including HFAs and mixed members.
struct F2 { float x, y; }
struct D2 { double x, y; }
struct FI { float f; int i; }
struct DL { double d; long l; }
struct LD { long l; double d; }
struct L2 { long a, b; }
struct I4 { int a, b, c, d; }
struct F4 { float a, b, c, d; }

void check(T)(T v)
{
    T[5] a;
    a[] = v;
    foreach (ref e; a)
        assert(e == v);
    T[] d = new T[7];
    d[] = v;
    foreach (ref e; d)
        assert(e == v);
}

void main()
{
    check(F2(1.5f, -2));
    check(D2(3.25, 4.5));
    check(FI(1.5f, 7));
    check(DL(2.5, -9));
    check(LD(-9, 2.5));
    check(L2(0x1122334455667788, -3));
    check(I4(1, 2, 3, 4));
    check(F4(1, 2, 3, 4));
}
