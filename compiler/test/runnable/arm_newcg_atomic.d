/* REQUIRED_ARGS: -O
 */
// core.atomic's loads, stores, fetch-adds, exchanges and compare-and-swaps of
// every size, and a counter several threads add to

import core.atomic;
import core.thread;

shared ubyte b8;
shared ushort b16;
shared uint b32;
shared ulong b64;
shared long counter;

void sizes(T)(ref shared T v)
{
    atomicStore(v, cast(T)5);
    assert(atomicLoad(v) == 5);
    assert(atomicFetchAdd(v, cast(T)3) == 5);
    assert(atomicLoad(v) == 8);
    assert(atomicExchange(&v, cast(T)T.max) == 8);
    assert(atomicLoad(v) == T.max);
    atomicOp!"+="(v, cast(T)2);              // wraps around
    assert(atomicLoad(v) == 1);
    assert(!cas(&v, cast(T)7, cast(T)9));    // fails, leaves 1
    assert(atomicLoad(v) == 1);
    assert(cas(&v, cast(T)1, cast(T)9));
    assert(atomicLoad(v) == 9);
    T expected = 4;
    assert(!cas(&v, &expected, cast(T)6));   // fails, reports the 9 there
    assert(expected == 9);
    atomicFence();
    assert(atomicLoad!(MemoryOrder.raw)(v) == 9);
}

void main()
{
    sizes(b8);
    sizes(b16);
    sizes(b32);
    sizes(b64);

    Thread[] ts;
    foreach (k; 0 .. 4)
        ts ~= new Thread({
            foreach (i; 0 .. 100_000)
            {
                atomicFetchAdd(counter, 1);
                long old = atomicLoad(counter);
                while (!cas(&counter, old, old + 2))
                    old = atomicLoad(counter);
            }
        });
    foreach (t; ts)
        t.start();
    foreach (t; ts)
        t.join();
    assert(atomicLoad(counter) == 4 * 100_000 * 3);
}
