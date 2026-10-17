module lib;
struct P
{
    int[] d;
    this(this) nothrow @safe { d = d.dup; }
}
void push(T)(ref T[] a, T v) { a ~= v; }
size_t make()(int n) { P[] a; P p = P([n]); push(a, p); push(a, p); return a.length + a[1].d[0]; }
