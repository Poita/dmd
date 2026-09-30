// Appending to strings at compile time leaves other references to the same data
// unchanged.

string build(int n)
{
    string s;
    foreach (i; 0 .. n)
        s ~= cast(char)('a' + i % 26);
    return s;
}
static assert(build(3) == "abc");
static assert(build(100).length == 100);
static assert(build(100)[26 .. 29] == "abc");

bool aliases()
{
    string s = "ab";
    s ~= "c";
    string t = s;           // t and s share data
    s ~= "d";
    t ~= "e";               // must not overwrite s's "d"
    assert(s == "abcd");
    assert(t == "abce");

    string u = s[0 .. 2];
    u ~= "x";               // u is a prefix of s: must not overwrite s
    assert(s == "abcd");
    assert(u == "abx");

    s ~= s;                 // appending a string to itself
    assert(s == "abcdabcd");
    return true;
}
static assert(aliases());

bool wide()
{
    wstring w = "ab"w;
    w ~= "cd"w;
    dstring d = "x"d;
    d ~= "yz"d;
    assert(w == "abcd"w && d == "xyz"d);
    return true;
}
static assert(wide());

bool nested()
{
    string outer;
    foreach (i; 0 .. 3)
    {
        string inner = "(";
        foreach (j; 0 .. 3)
            inner ~= "x";
        inner ~= ")";
        outer ~= inner;
    }
    assert(outer == "(xxx)(xxx)(xxx)");
    return true;
}
static assert(nested());
