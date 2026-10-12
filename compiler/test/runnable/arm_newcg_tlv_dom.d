/* REQUIRED_ARGS: -O
 */
// Thread local variables used in several blocks of a function: an address taken
// in a block dominating another serves it, one taken only on some paths does not

import core.thread;

int hits;
long total;
int[8] slots;

pragma(inline, false) int work(int n, bool flag)
{
    int r = flag ? hits : 0;        // taken on one path only
    if (n > 3)
        r += hits;
    foreach (i; 0 .. n)
    {
        total += i;
        if (i & 1)
            slots[i & 7] += hits;
        else
            ++hits;
    }
    return r + cast(int)total + slots[1];
}

void check()
{
    hits = 2;
    total = 0;
    slots[] = 0;
    // hits 2 then +1 at each even i of 0..6 (4 times) -> 6; slots[1] += 3, slots[3] += 4, slots[5] += 5
    const r = work(7, false);
    if (hits != 6 || total != 21 || slots[1] != 3 || slots[3] != 4 || slots[5] != 5) assert(0);
    if (r != 2 + 21 + 3) assert(0);
    hits = 1;
    if (work(0, true) != 1 + 21 + 3) assert(0);
}

void main()
{
    check();
    auto t = new Thread(&check);
    t.start();
    t.join();
    check();
}
