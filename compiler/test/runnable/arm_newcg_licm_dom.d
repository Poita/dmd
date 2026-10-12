/* REQUIRED_ARGS: -O
 */
// Loops entered from more than one place, as rotated loops with continue and
// labeled break are, reading thread local variables and what is set on the way in

import core.thread;

int[] chosen;
size_t pendLen;
int seen;

pragma(inline, false) void note(int x) { seen += x; }

int search(int n)
{
    int s;
    search: for (;;)
    {
        if (pendLen == 0)
            break;
        s += chosen[pendLen & 7];
        if (s > n)
        {
            pendLen--;
            continue;
        }
        for (;;)
        {
            if (s == 0)
                break search;
            note(s);
            s--;
            if (s & 1)
                break;
        }
        pendLen--;
    }
    return s;
}

// a value set on one way into the loop and stored to on the other
int twoWays(int n, bool flag)
{
    int base = 3;
    if (flag)
    {
        base = n;
        pendLen = 5;
    }
    else
        chosen[0] = 40;
    int s;
    while (pendLen)
    {
        s += base + chosen[0];
        note(1);
        pendLen--;
        if (s > 1000)
            continue;
    }
    return s;
}

void check()
{
    chosen = [1, 2, 3, 4, 5, 6, 7, 8];
    pendLen = 20;
    seen = 0;
    const r = search(10);
    if (pendLen != 0 || r != 78 || seen != 55) assert(0);

    pendLen = 3;
    seen = 0;
    if (twoWays(7, false) != 3 * (3 + 40) || seen != 3) assert(0);
    if (twoWays(7, true) != 5 * (7 + 40) || seen != 8) assert(0);
}

void main()
{
    check();
    auto t = new Thread(&check);
    t.start();
    t.join();
}
