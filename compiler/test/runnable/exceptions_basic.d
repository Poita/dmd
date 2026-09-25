// Exceptions thrown locally and from called functions are caught, and
// finally blocks run while unwinding.

int finallies;

void thrower(int depth)
{
    scope(exit) ++finallies;
    if (depth == 0)
        throw new Exception("deep");
    thrower(depth - 1);
}

int catchLocal()
{
    try
        throw new Exception("local");
    catch (Exception e)
        return cast(int) e.msg.length;
}

void main()
{
    assert(catchLocal() == 5);

    try
        thrower(3);
    catch (Exception e)
        assert(e.msg == "deep");
    assert(finallies == 4);

    bool caught;
    try
    {
        try
            throw new Exception("inner");
        finally
            ++finallies;
    }
    catch (Exception e)
        caught = e.msg == "inner";
    assert(caught);
    assert(finallies == 5);
}
