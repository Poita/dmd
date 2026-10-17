module pair;
struct Pair(A, B)
{
    A a;
    B b;
    bool opEquals(R)(R rhs) { return a == rhs.a && b == rhs.b; }
    bool opEquals(R)(R rhs) const { return a == rhs.a && b == rhs.b; }
}
