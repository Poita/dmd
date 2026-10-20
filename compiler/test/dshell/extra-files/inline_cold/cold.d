module cold;

class BadValue : Exception
{
    int value;
    this(int value) { super("bad value"); this.value = value; }
}

int mix(int x)
{
    int y = x * 31 + 7;
    y ^= y >> 3;
    y += x * x - (x >> 2);
    y ^= y << 5;
    return y + (x & 0xFF) * 3;
}

string name(int x)
{
    return x > 50 ? "huge" : x > 20 ? "big" : x > 5 ? "mid" : x > 0 ? "small" : "none";
}

// the call in the loop body runs every iteration; the one before the throw runs at most once
int hotLoop(const int[] a)
{
    int s;
    foreach (v; a)
    {
        if (v < 0)
            throw new BadValue(mix(v));
        s += mix(v);
    }
    return s;
}

int throwBranch(int x)
{
    if (x < 0)
    {
        const m = mix(x);
        throw new BadValue(m);
    }
    return x + 1;
}

int assertMessage(int x)
{
    assert(x != 3, name(x));
    return x * 2;
}

int caught(int x)
{
    try
        return throwBranch(x);
    catch (BadValue e)
        return mix(e.value);
}

void fail(int x)
{
    throw new BadValue(x);
}

int noReturnElse(int x)
{
    if (x >= 0)
        return x + 2;
    else
    {
        fail(mix(x));
        assert(0);
    }
}

int hot(int x)
{
    return mix(x) + cast(int) name(x).length;
}
