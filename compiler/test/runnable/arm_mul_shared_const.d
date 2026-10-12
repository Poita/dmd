/* REQUIRED_ARGS: -O
 */
// A constant multiplied by a 32 bit value and divided by, shared as one
// expression: the division stays signed

struct TOD
{
    ubyte h, m, s;

    pragma(inline, false)
    void roll(long hours)
    {
        long seconds = hours * 36_000_000_000L / 10_000_000L;
        long hnsecs = seconds * 10_000_000L;
        hnsecs += 36_000_000_000L * cast(long) h;
        hnsecs += 600_000_000L * cast(long) m;
        hnsecs += 10_000_000L * cast(long) s;
        hnsecs %= 864_000_000_000L;
        if (hnsecs < 0)
            hnsecs += 864_000_000_000L;
        immutable newH = hnsecs / 36_000_000_000L;
        hnsecs -= newH * 36_000_000_000L;
        immutable newM = hnsecs / 600_000_000L;
        hnsecs -= newM * 600_000_000L;
        immutable newS = hnsecs / 10_000_000L;
        h = cast(ubyte) newH;
        m = cast(ubyte) newM;
        s = cast(ubyte) newS;
    }
}

void main()
{
    auto t = TOD(12, 30, 33);
    t.roll(-1);
    assert(t == TOD(11, 30, 33));
}
