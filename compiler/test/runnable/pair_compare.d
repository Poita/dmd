// Comparing values held in register pairs (slices, delegates) branches
// between the two halves.

bool same(string a, string b) { return a is b; }

bool sameDg(void delegate() a, void delegate() b) { return a is b; }

struct S { void f() {} }

void main()
{
    string s = "hello";
    assert(same(s, s));
    assert(!same(s, s[0 .. 4]));
    assert(!same(s, "hellp"));

    S x, y;
    assert(sameDg(&x.f, &x.f));
    assert(!sameDg(&x.f, &y.f));
}
