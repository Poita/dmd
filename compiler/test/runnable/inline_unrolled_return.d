/* REQUIRED_ARGS: -O -inline
 */
// Functions returning from a foreach over a tuple that is left by continue or
// break, inlined as statements with the iterations after the return kept

alias AliasSeq(T...) = T;

// the position of the needle the end of h matches, as std.algorithm.endsWith
uint endsWith(Needles...)(dchar[] h, Needles needles)
{
    for (; h.length; h = h[0 .. $ - 1])
    {
        foreach (i, Unused; Needles)
        {
            if (h[$ - 1] == needles[i])
                continue;
            static if (Needles.length > 1)
            {
                uint result = endsWith(h, needles[0 .. i], needles[i + 1 .. $]);
                if (result > i)
                    ++result;
                return result;
            }
            else
                return 0;
        }
        foreach (i, Unused; Needles)
            return i + 1;
    }
    return 0;
}

// the position of the needle h starts with, as std.algorithm.startsWith
uint startsWith(Needles...)(dchar[] h, Needles needles)
{
    foreach (i, Unused; Needles)
        if (needles[i].length == 0)
            return i + 1;

    for (; h.length; h = h[1 .. $])
    {
        foreach (i, Unused; Needles)
        {
            if (h[0] == needles[i][0])
                continue;
            static if (Needles.length > 1)
            {
                uint result = startsWith(h, needles[0 .. i], needles[i + 1 .. $]);
                if (result > i)
                    ++result;
                return result;
            }
            else
                return 0;
        }
        foreach (i, Unused; Needles)
        {
            needles[i] = needles[i][1 .. $];
            if (needles[i].length == 0)
                return i + 1;
        }
    }
    return 0;
}

// the first of the values that is positive, or 0
int firstPositive(int a, int b, int c)
{
    foreach (v; AliasSeq!(a, b, c))
    {
        if (v <= 0)
            continue;
        return v;
    }
    return 0;
}

// the index of the first of the values that is not positive, or 3
int firstNotPositive(int a, int b, int c)
{
    int k;
    foreach (v; AliasSeq!(a, b, c))
    {
        if (v > 0)
        {
            ++k;
            continue;
        }
        break;
    }
    return k;
}

void main()
{
    dchar[] s = "abc"d.dup;
    assert(endsWith(s, 'a', 'c') == 2);
    assert(endsWith(s, 'x', 'n', 'c') == 3);
    assert(endsWith(s, 'c', 'x', 'y') == 1);
    assert(endsWith(s, 'x', 'y', 'z') == 0);

    assert(startsWith(s, "bc", "abcd", "xyz") == 0);
    assert(startsWith(s, "b", "bc", "abcd", "xyz") == 0);
    assert(startsWith(s, "x", "ab") == 2);

    for (int i = 0; i < 1; ++i)
    {
        assert(firstPositive(-1, 0, 5) == 5);
        assert(firstPositive(-1, 0, -5) == 0);
        assert(firstNotPositive(1, 2, -3) == 2);
        assert(firstNotPositive(1, 2, 3) == 3);
    }
}
