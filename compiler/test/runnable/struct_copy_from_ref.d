// A struct copied from the result of a function returning it by reference.

struct S { long a, b, c; }

__gshared S g = S(1, 2, 3);

ref S get() { return g; }

void main()
{
    S s = get();
    assert(s.a == 1 && s.b == 2 && s.c == 3);
    s = get();
    s.a = 9;
    assert(g.a == 1 && s.c == 3);
}
