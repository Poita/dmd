/* REQUIRED_ARGS: -O
 */
// Exceptions caught and passed on where values of the function, changed in the
// try, are read by the catch or the finally: integers and floats, in loops,
// nested, with scope guards and destructors

int depth;
void thrower(int k)
{
    if (k % 3 == 0)
        throw new Exception("k");
    if (k % 7 == 0)
        throw new Error("e");
}

int[] log;
struct Guard
{
    int id;
    ~this() { log ~= id; }
}

int catchInLoop(int n)
{
    int caught, total;
    double f = 0.5;
    foreach (i; 0 .. n)
    {
        int before = total;
        try
        {
            total += i;
            f *= 1.5;
            thrower(i);
            total += 100;
        }
        catch (Exception e)
        {
            caught += 1;
            assert(total == before + i);    // the change made before the throw is seen
            f -= 0.25;
        }
        catch (Error e)
        {
            caught += 1000;
        }
    }
    return caught + total + cast(int)(f * 0);
}

int withFinally(int a, ref int finallyRan)
{
    int x = a * 2;
    try
    {
        x += 1;
        thrower(a);
        x += 10;
    }
    finally
    {
        finallyRan += x;
    }
    return x;
}

int scopes(int a)
{
    log = null;
    int r;
    {
        auto g1 = Guard(1);
        scope(exit) log ~= 2;
        scope(success) log ~= 3;
        scope(failure) log ~= 4;
        auto g2 = Guard(5);
        thrower(a);
        r = a + g1.id + g2.id;
    }
    return r;
}

int nested(int a)
{
    int r;
    try
    {
        try
        {
            r = 1;
            thrower(a);
            r = 2;
        }
        catch (Exception e)
        {
            r += 10;
            throw new Exception("again");
        }
        finally
        {
            r += 100;
        }
    }
    catch (Exception e)
    {
        r += 1000;
    }
    return r;
}

int finallyReturns(int a)
{
    int r = a;
    try
    {
        if (a > 5)
            return r * 2;
        r += 1;
    }
    finally
    {
        r += 50;
    }
    return r;
}

void main()
{
    // 0..20: throws on multiples of 3 (Exception) and of 7 not 3 (Error)
    int caught, total;
    foreach (i; 0 .. 20)
    {
        total += i;
        if (i % 3 == 0) caught += 1;
        else if (i % 7 == 0) caught += 1000;
        else total += 100;
    }
    assert(catchInLoop(20) == caught + total);

    int ran;
    assert(withFinally(1, ran) == 13 && ran == 13);
    try { withFinally(3, ran); assert(0); } catch (Exception e) { assert(ran == 13 + 7); }

    assert(scopes(1) == 7 && log == [5, 3, 2, 1]);
    try { scopes(3); assert(0); } catch (Exception e) { assert(log == [5, 4, 2, 1]); }

    assert(nested(1) == 102);
    assert(nested(3) == 1111);
    assert(finallyReturns(1) == 52);      // the finally runs before the r returned is read
    assert(finallyReturns(9) == 18);      // r * 2 is taken before the finally changes r
}
