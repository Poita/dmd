module cow;
struct P { static T[] alloc(T)(size_t size) { return new T[size]; } }
struct C(SP)
{
    uint[] data;
    void length(size_t len) { immutable total = len + 1; data = SP.alloc!uint(total); }
}
size_t make(size_t n) { C!P c; c.length = n; return c.data.length; }
