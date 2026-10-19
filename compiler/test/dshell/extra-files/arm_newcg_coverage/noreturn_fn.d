// Functions returning noreturn, which only throw or halt.
module noreturn_fn;

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

class Failure : Exception
{
    long code;
    this(long code) { super("failure"); this.code = code; }
}

pragma(inline, false) noreturn fail(long code)
{
    throw new Failure(code * 2);
}

pragma(inline, false) noreturn failEither(long code, bool other)
{
    if (other)
        throw new Failure(-code);
    fail(code);
}

pragma(inline, false) long caught(long code, bool other)
{
    try
        failEither(code, other);
    catch (Failure f)
        return f.code;
}

void main()
{
    check(caught(5, false) == 10);
    check(caught(5, true) == -5);
}
