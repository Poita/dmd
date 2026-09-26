// An aggregate returned in registers and passed straight on as a stack argument
// (the first parameter is the last to get registers).

float[4] quad(float x) { return [x, x + 1, x + 2, x + 3]; }

void takesQuad(float[4] q, float a, float b, float c, float d, float e, float f, float g, float h)
{
    assert(a == 1 && h == 8);
    assert(q == [10, 11, 12, 13]);
}

struct Pair { long a, b; }

Pair pair(long x) { return Pair(x, x * 2); }

void takesPair(Pair p, long a, long b, long c, long d, long e, long f, long g, long h)
{
    assert(a == 1 && h == 8);
    assert(p == Pair(21, 42));
}

void main()
{
    takesQuad(quad(10), 1, 2, 3, 4, 5, 6, 7, 8);
    takesPair(pair(21), 1, 2, 3, 4, 5, 6, 7, 8);
}
