// A small struct parameter whose fields are updated through its address must
// not be returned from the register it arrived in.

struct SS { short a, b; }
struct FI { float a; int b; }
struct ISS { int a; short b, c; }

T bump(T)(T t)
{
    foreach (i, ref e; t.tupleof)
        e += 10;
    return t;
}

void setVia(int* p) { *p = 42; }

int viaPointer(int x)
{
    setVia(&x);
    return x;
}

void main()
{
    assert(bump(SS(1, 2)) == SS(11, 12));
    assert(bump(FI(1, 2)) == FI(11, 12));
    assert(bump(ISS(1, 2, 3)) == ISS(11, 12, 13));
    assert(viaPointer(1) == 42);
}
