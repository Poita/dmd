// Thread local variables read and written in loops, in branches, next to calls
// and comparisons, each thread seeing its own
import core.thread;

int counter;
long total;
int[] stack;
ubyte flag;

int sumTo(int n)
{
    foreach (i; 0 .. n)
    {
        counter += i;
        if (counter > 100)
            counter -= cast(int)stack.length;
    }
    return counter;
}

int pick(int a, int b, int c)
{
    // a value in x0 kept across the read of a thread local
    const r = a > counter ? b : c;
    return r + counter;
}

int guarded(int n)
{
    // the loop guard compares before the loop the read is hoisted from
    int s;
    for (int i = 0; i < n; ++i)
        s += counter + flag;
    return s;
}

long spread(int n, bool which)
{
    if (which)
        total += n;
    else
        total -= n;
    foreach (i; 0 .. n)
        if (i & 1)
            total += i;
    return total;
}

void check(int base)
{
    counter = base;
    stack = new int[](base % 7);
    flag = cast(ubyte)(base & 3);
    total = 0;
    int expect = base;
    foreach (i; 0 .. 50)
    {
        expect += i;
        if (expect > 100)
            expect -= base % 7;
    }
    assert(sumTo(50) == expect);
    assert(counter == expect);
    assert(pick(counter - 1, 10, 20) == 20 + counter);
    assert(pick(counter + 1, 10, 20) == 10 + counter);
    assert(guarded(0) == 0);
    assert(guarded(9) == 9 * (counter + flag));
    long t = 5;
    foreach (i; 0 .. 5)
        if (i & 1)
            t += i;
    assert(spread(5, true) == t);
}

void main()
{
    check(3);
    Thread[] ts;
    foreach (k; 0 .. 4)
        ts ~= new Thread({ foreach (r; 0 .. 100) check(r * 10 + 7); });
    foreach (t; ts)
        t.start();
    check(1000);
    foreach (t; ts)
        t.join();
    assert(counter > 0);
}
