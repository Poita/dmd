// Exception handling with calls that do not return: a value set just before a throw
// is the catch handler's, functions returning noreturn, and scope guards.
module eh_noreturn;

// asserts are compiled out with -release
void check(bool ok, int line = __LINE__)
{
    import core.stdc.stdio : fprintf, stderr;
    import core.stdc.stdlib : exit;
    if (!ok)
    {
        fprintf(stderr, "check failed at line %d\n", line);
        exit(1);
    }
}

__gshared Exception preMade;
__gshared long sink;

pragma(inline, false) noreturn bail(long code)
{
    throw new Exception(code < 0 ? "negative" : "positive");
}

pragma(inline, false) long setBeforeThrow(long a)
{
    long x = a;
    try
    {
        sink += a;
        x = a * 7 + 3;          // live only across the throw
        if (a > 2)
            throw preMade;
        x += 1;
    }
    catch (Exception e)
        return x * 2;
    return x;
}

pragma(inline, false) long finallyAfterThrow(long a, ref long seen)
{
    long x = a;
    try
    {
        sink += a;
        x = a * 9 + 2;          // live only across the throw, into the finally block
        if (a > 2)
            throw preMade;
        x += 1;
    }
    finally
        seen = x;
    return x;
}

// leaves values of its own in the caller saved registers
pragma(inline, false) long scramble(long s)
{
    long a0 = s * 3, a1 = s * 5, a2 = s ^ 7, a3 = s + 9, a4 = s * 11, a5 = s - 13, a6 = s * 15;
    long a7 = s + 17, a8 = s * 19, a9 = s ^ 21, a10 = s - 23, a11 = s * 25, a12 = s + 27;
    foreach (i; 0 .. 3)
    {
        a0 += a1 * a2; a1 += a2 * a3; a2 += a3 * a4; a3 += a4 * a5; a4 += a5 * a6;
        a5 += a6 * a7; a6 += a7 * a8; a7 += a8 * a9; a8 += a9 * a10; a9 += a10 * a11;
        a10 += a11 * a12; a11 += a12 * a0; a12 += a0 * a1;
    }
    return a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + a9 + a10 + a11 + a12;
}

pragma(inline, false) void maybeThrow(long a)
{
    if (a > 2)
    {
        sink += scramble(a);
        throw preMade;
    }
    sink += a;
}

// a value set again after a call that may throw is the one before in the finally block
pragma(inline, false) long setAfterCall(long a, ref long seen)
{
    long x = a * 3;
    try
    {
        maybeThrow(a);
        x = a * 11;
        maybeThrow(a - 10);
    }
    finally
        seen = x;
    return x;
}

// more values live across the call into the finally block than callee saved registers
pragma(inline, false) long manyIntoFinally(long a, ref long seen)
{
    long v0 = a + 1, v1 = a * 2, v2 = a * 3 + 1, v3 = a ^ 5, v4 = a - 7, v5 = a * a;
    long v6 = a + 11, v7 = a * 13, v8 = a - 17, v9 = a * 19 + 1, v10 = a + 23, v11 = a * 29;
    long v12 = a - 31, v13 = a * 37, v14 = a + 41, v15 = a * 43 - 1;
    try
        maybeThrow(a);
    finally
        seen = v0 + v1 + v2 + v3 + v4 + v5 + v6 + v7 + v8 + v9 + v10 + v11 + v12 + v13 + v14 + v15;
    return v0 * v15 + v7;
}

long manySum(long a)
{
    return (a + 1) + (a * 2) + (a * 3 + 1) + (a ^ 5) + (a - 7) + (a * a) + (a + 11) + (a * 13) +
        (a - 17) + (a * 19 + 1) + (a + 23) + (a * 29) + (a - 31) + (a * 37) + (a + 41) + (a * 43 - 1);
}

pragma(inline, false) long viaNoreturn(long a)
{
    long x = a;
    try
    {
        sink += a;
        x = a * 5 - 1;
        if (a != 0)
            bail(a);
    }
    catch (Exception e)
        return x + 100;
    return x;
}

pragma(inline, false) long guards(long a, ref long log)
{
    scope (exit) log = log * 10 + 1;
    scope (failure) log = log * 10 + 2;
    scope (success) log = log * 10 + 3;
    if (a < 0)
        bail(a);
    return a * 2;
}

void main()
{
    preMade = new Exception("premade");
    check(setBeforeThrow(1) == 11);
    check(setBeforeThrow(5) == 38 * 2);
    long seen;
    check(finallyAfterThrow(1, seen) == 12 && seen == 12);
    bool thrown;
    try
        finallyAfterThrow(4, seen);
    catch (Exception e)
        thrown = true;
    check(thrown && seen == 38);
    check(setAfterCall(1, seen) == 11 && seen == 11);
    thrown = false;
    try
        setAfterCall(4, seen);
    catch (Exception e)
        thrown = true;
    check(thrown && seen == 12);
    thrown = false;
    try
        setAfterCall(13, seen);
    catch (Exception e)
        thrown = true;
    check(thrown && seen == 39);
    check(manyIntoFinally(1, seen) == 2 * 42 + 13 && seen == manySum(1));
    thrown = false;
    try
        manyIntoFinally(5, seen);
    catch (Exception e)
        thrown = true;
    check(thrown && seen == manySum(5));
    check(viaNoreturn(0) == -1);
    check(viaNoreturn(3) == 14 + 100);
    long log;
    check(guards(4, log) == 8 && log == 31);
    log = 0;
    bool caught;
    try
        guards(-1, log);
    catch (Exception e)
        caught = true;
    check(caught && log == 21);
}
