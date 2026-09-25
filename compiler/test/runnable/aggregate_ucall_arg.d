// An aggregate returned from a call without arguments is used directly as an
// argument, assigned, and returned.

ubyte[10] ten() { ubyte[10] a; foreach (i, ref b; a) b = cast(ubyte) i; return a; }
float[3] three() { return [1, 2, 3]; }
struct P { long a, b; }
P pair() { return P(4, 5); }

int sumBytes(ubyte[10] a) { int s; foreach (b; a) s += b; return s; }
float sumFloats(float[3] a) { return a[0] + a[1] + a[2]; }
long sumPair(P p) { return p.a + p.b; }

ubyte[10] passTen() { return ten(); }

void main()
{
    assert(sumBytes(ten()) == 45);
    assert(sumFloats(three()) == 6);
    assert(sumPair(pair()) == 9);
    ubyte[10] t = passTen();
    assert(t[9] == 9);
    float[3] f;
    f = three();
    assert(f[2] == 3);
}
