// Floating point comparisons, including unordered operands and operands that
// are common subexpressions.

int c3(T)(T a, T b) { return (a > b) - (a < b); }

bool lt(double a, double b) { return a < b; }
bool le(double a, double b) { return a <= b; }
bool gt(double a, double b) { return a > b; }
bool ge(double a, double b) { return a >= b; }
bool eq(double a, double b) { return a == b; }
bool ne(double a, double b) { return a != b; }

void main()
{
    assert(c3(2.0, 1.0) == 1 && c3(1.0, 2.0) == -1 && c3(1.0, 1.0) == 0);
    assert(c3(2.0f, 1.0f) == 1 && c3(1L, 2L) == -1 && c3(3, 3) == 0);
    assert(c3(double.max, double.min_normal) == 1);

    double n = double.nan;
    assert(!lt(n, 1) && !le(n, 1) && !gt(n, 1) && !ge(n, 1) && !eq(n, 1) && ne(n, 1));
    assert(!lt(1, n) && !le(1, n) && !gt(1, n) && !ge(1, n));
    assert(lt(1, 2) && le(2, 2) && gt(3, 2) && ge(2, 2) && eq(2, 2) && !ne(2, 2));
    int count;
    foreach (x; [n, 1.0, 2.0])
        if (x < 1.5)
            ++count;
    assert(count == 1);
}
