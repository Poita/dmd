/* REQUIRED_ARGS: -O -inline -release
 */
// A variable read shared by two blocks, as when an inlined Appender.put's argument
// is the variable compared before the call: the later block reads it again
// rather than taking the copy the other block made

import std.array, core.stdc.stdio, core.stdc.stdlib;
string[] lexStrings(string src)
{
    string[] toks;
    size_t p = 0;
    while (p < src.length)
    {
        char c = src[p];
        if (c == '"' || c == '\'')
        {
            char q = c;
            p++;
            auto b = appender!string();
            bool closed = false;
            while (p < src.length)
            {
                char d = src[p];
                if (d == q)
                {
                    p++;
                    closed = true;
                    break;
                }
                b.put(d);
                p++;
            }
            toks ~= b.data;
        }
        else
            p++;
    }
    return toks;
}
void main()
{
    int bad;
    foreach (n; 1 .. 3000)
    {
        string s;
        foreach (k; 0 .. n % 37)
            s ~= cast(char)('a' + (k * 7 + n) % 26);
        auto src = "x \"" ~ s ~ "\" y '" ~ s ~ s ~ "' z";
        auto t = lexStrings(src);
        if (t.length != 2 || t[0] != s || t[1] != s ~ s)
        {
            if (bad < 3) printf("n=%d got [%.*s] [%.*s]\n", n, cast(int)t[0].length, t[0].ptr, cast(int)(t.length > 1 ? t[1].length : 0), t.length > 1 ? t[1].ptr : null);
            ++bad;
        }
    }
    if (bad)
        abort();        // not assert, which -release takes away
}
