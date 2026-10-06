// New arrays of types whose initial values are not zero, of many lengths

struct Pair { short a = -2; short b = 7; }

void check(T)(size_t n)
{
    auto a = new T[](n);
    if (a.length != n) assert(0);
    foreach (ref x; a)
    {
        static if (is(T == float) || is(T == double))
        {
            if (x == x) assert(0);      // NaN
        }
        else if (x != T.init) assert(0);
    }
}

void main()
{
    foreach (n; [0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 100, 1001])
    {
        check!float(n);
        check!double(n);
        check!char(n);
        check!wchar(n);
        check!dchar(n);
        check!Pair(n);
    }
}
