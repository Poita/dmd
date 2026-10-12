/* REQUIRED_ARGS: -O -inline -release
 */
// A thread local address needed by a loop whose test is reached from more than
// one place, moved above the test's compare at the start of its block: as with
// the append cache read in the loop of toDouble, it is set on every way in

import std.conv : to;

bool isWs(char c) pure nothrow @safe @nogc
{
    return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f';
}

private bool isDigit(char c) pure nothrow @safe @nogc
{
    return c >= '0' && c <= '9';
}

struct Scanner
{
    string s;
    size_t i;

    bool atEnd() const
    {
        return i >= s.length;
    }

    /// Skips whitespace.
    void skipWs()
    {
        while (i < s.length && isWs(s[i]))
            ++i;
    }

    /// Skips whitespace and commas.
    void skipSep()
    {
        while (i < s.length && (isWs(s[i]) || s[i] == ','))
            ++i;
    }

    /// True when the next character can begin a number.
    bool atNumberStart() const
    {
        if (i >= s.length)
            return false;
        char c = s[i];
        return isDigit(c) || c == '.' || c == '+' || c == '-';
    }

    /// Reads a number at the cursor; leaves the cursor unchanged on failure.
    bool number(out double value)
    {
        size_t p = i;
        if (p < s.length && (s[p] == '+' || s[p] == '-'))
            ++p;
        size_t intStart = p;
        while (p < s.length && isDigit(s[p]))
            ++p;
        size_t intDigits = p - intStart;
        size_t fracDigits = 0;
        if (p < s.length && s[p] == '.')
        {
            size_t q = p + 1;
            while (q < s.length && isDigit(s[q]))
                ++q;
            fracDigits = q - p - 1;
            if (intDigits > 0 || fracDigits > 0)
                p = q;
        }
        if (intDigits == 0 && fracDigits == 0)
            return false;
        if (p < s.length && (s[p] == 'e' || s[p] == 'E'))
        {
            size_t q = p + 1;
            if (q < s.length && (s[q] == '+' || s[q] == '-'))
                ++q;
            if (q < s.length && isDigit(s[q]))
            {
                while (q < s.length && isDigit(s[q]))
                    ++q;
                p = q;
            }
        }
        value = toDouble(s[i .. p]);
        i = p;
        return true;
    }
}

private double toDouble(string t) @safe
{
    // Normalise forms like ".5", "5." and "-.5e3" for std.conv.
    char[] b;
    size_t k = 0;
    if (k < t.length && (t[k] == '+' || t[k] == '-'))
        b ~= t[k++];
    if (k < t.length && t[k] == '.')
        b ~= '0';
    while (k < t.length)
    {
        char c = t[k];
        b ~= c;
        if (c == '.' && (k + 1 >= t.length || !isDigit(t[k + 1])))
            b ~= '0';
        ++k;
    }
    try
        return to!double(b.idup);
    catch (Exception)
        return 0;
}

double[] parseNumberList(string t)
{
    double[] r;
    auto sc = Scanner(t, 0);
    while (true)
    {
        sc.skipSep();
        double v;
        if (!sc.number(v))
            break;
        r ~= v;
    }
    return r;
}

void main()
{
    auto v = parseNumberList("0 0 8 4".idup);
    assert(v == [0.0, 0, 8, 4]);
    assert(parseNumberList(".5 -.5e3 5.".idup) == [0.5, -500, 5]);
}
