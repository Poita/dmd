// Slices and pointers passed on the stack once the argument registers run out.
string[] seen;
bool*[] flags;

void impl(T...)(ref string[] args, ref int cfg, ref int r, ref Object ex,
    void[][string] a1, void[][string] a2, T opts)
{
    static if (opts.length)
    {
        seen ~= opts[0];
        flags ~= opts[1];
        impl(args, cfg, r, ex, a1, a2, opts[2 .. $]);
    }
}

void many(long a, long b, long c, long d, long e, long f, long g,
    string s1, string s2, string s3, bool* p)
{
    assert(a + b + c + d + e + f + g == 28);
    assert(s1 == "one" && s2 == "two" && s3 == "three" && *p);
}

void main()
{
    string[] args = ["x"];
    int cfg, r;
    Object ex;
    bool a, b, c, d;
    impl(args, cfg, r, ex, null, null, "one", &a, "two", &b, "three", &c, "four", &d);
    assert(seen == ["one", "two", "three", "four"]);
    assert(flags == [&a, &b, &c, &d]);

    bool t = true;
    many(1, 2, 3, 4, 5, 6, 7, "one", "two", "three", &t);
}
