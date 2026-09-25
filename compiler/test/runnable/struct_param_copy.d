// A struct parameter that is only read by copying it is kept in the frame.

struct V { float x, y, z; }
struct W { V v; int n; }

W wrap(int n, V v, char c)
{
    W w;
    w.v = v;
    w.n = n + c;
    return w;
}

void main()
{
    auto w = wrap(1, V(5, 7, 9), 'a');
    assert(w.v.x == 5 && w.v.y == 7 && w.v.z == 9 && w.n == 98);
}
