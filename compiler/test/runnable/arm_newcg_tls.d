/* REQUIRED_ARGS: -O
 */
// Thread local variables, reached through their TLV descriptors

import core.thread;

int counter;
long[4] totals;
struct Pair { int a; double b; }
Pair pair = Pair(3, 1.5);
int* lastSeen;

pragma(inline, false) int bump(int by)
{
    counter += by;
    return counter;
}

pragma(inline, false) long sumInto(const int[] xs)
{
    foreach (i, x; xs)
        totals[i & 3] += x;
    return totals[0] + totals[1] + totals[2] + totals[3];
}

pragma(inline, false) double pairWork(int n)
{
    foreach (i; 0 .. n)
    {
        pair.a += i;
        pair.b *= 1.5;
    }
    return pair.a + pair.b;
}

pragma(inline, false) int* addressOf()
{
    lastSeen = &counter;
    return lastSeen;
}

pragma(inline, false) int staticLocal()
{
    static int calls;       // thread local too
    return ++calls;
}

void check()
{
    counter = 0;
    totals[] = 0;
    pair = Pair(3, 1.5);
    if (bump(2) != 2 || bump(5) != 7 || counter != 7) assert(0);
    if (sumInto([1, 2, 3, 4, 5, 6]) != 21 || totals[0] != 1 + 5) assert(0);
    if (pairWork(3) != (3 + 0 + 1 + 2) + 1.5 * 1.5 * 1.5 * 1.5) assert(0);
    int* p = addressOf();
    *p = 40;
    if (counter != 40 || lastSeen !is &counter) assert(0);
    if (staticLocal() != 1 || staticLocal() != 2) assert(0);
}

void main()
{
    check();
    int* mine = &counter;
    int* theirs;
    auto t = new Thread({
        check();                // a fresh set of the variables
        theirs = &counter;
    });
    t.start();
    t.join();
    if (theirs is mine) assert(0);
    if (counter != 40) assert(0);   // untouched by the other thread
}
