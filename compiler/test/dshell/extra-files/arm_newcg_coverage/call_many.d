// A call of 80 arguments, as std.getopt makes of many options.
module call_many;

string params()
{
    string s;
    foreach (i; 0 .. 80)
        s ~= (i ? ", " : "") ~ (i % 3 == 1 ? "double a" : i % 3 == 2 ? "string a" : "int a") ~ cast(char)('0' + i / 10) ~
            cast(char)('0' + i % 10);
    return s;
}

string args()
{
    string s;
    foreach (i; 0 .. 80)
    {
        import std.conv : to;
        s ~= (i ? ", " : "") ~ (i % 3 == 1 ? "x * " ~ i.to!string ~ ".0" : i % 3 == 2 ? "names[" ~ (i % 4).to!string ~ "]" :
            "x + " ~ i.to!string);
    }
    return s;
}

string sum()
{
    string s = "double t = 0;";
    foreach (i; 0 .. 80)
    {
        const n = "a" ~ cast(char)('0' + i / 10) ~ cast(char)('0' + i % 10);
        s ~= i % 3 == 2 ? "t += " ~ n ~ ".length * " ~ cast(char)('1' + i % 7) ~ ";" : "t += " ~ n ~ ";";
    }
    return s ~ "return t;";
}

mixin("pragma(inline, false) double calleeMany(" ~ params() ~ ") {" ~ sum() ~ "}");

double many(int x)
{
    static immutable string[4] names = ["a", "bb", "ccc", "dddd"];
    return mixin("calleeMany(" ~ args() ~ ")");
}

int main()
{
    double want(int x)
    {
        double t = 0;
        foreach (i; 0 .. 80)
            t += i % 3 == 1 ? x * cast(double)i : i % 3 == 2 ? (i % 4 + 1) * (1 + i % 7) : x + i;
        return t;
    }
    assert(many(3) == want(3));
    assert(many(-5) == want(-5));
    return 0;
}
