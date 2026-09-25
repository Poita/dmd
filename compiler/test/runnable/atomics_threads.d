// Atomic operations are atomic across threads and work on class references
// and 16 byte values.

import core.atomic;
import core.thread;

shared long counter;
shared ubyte small;

class C { int x; }

struct Pair { size_t a, b; }

void main()
{
    enum threads = 4, iterations = 100_000;
    Thread[threads] ts;
    foreach (ref t; ts)
        t = new Thread({
            foreach (_; 0 .. iterations)
            {
                atomicOp!"+="(counter, 1);
                atomicOp!"+="(small, 1);
            }
        }).start();
    foreach (t; ts)
        t.join();
    assert(atomicLoad(counter) == threads * iterations);
    assert(atomicLoad(small) == cast(ubyte)(threads * iterations));

    shared int i = 5;
    assert(atomicExchange(&i, 7) == 5);
    assert(atomicLoad(i) == 7);
    assert(cas(&i, 7, 9) && atomicLoad(i) == 9);
    assert(!cas(&i, 7, 11) && atomicLoad(i) == 9);

    auto c1 = new shared C, c2 = new shared C;
    shared C ref_ = c1;
    assert(cas(&ref_, c1, c2) && ref_ is c2);
    assert(!cas(&ref_, c1, c1) && ref_ is c2);

    shared Pair p = Pair(1, 2);
    assert(cas(&p, Pair(1, 2), Pair(3, 4)));
    assert(atomicLoad(p) == Pair(3, 4));
    assert(!cas(&p, Pair(1, 2), Pair(5, 6)));
    atomicStore(p, Pair(7, 8));
    assert(atomicLoad(p) == Pair(7, 8));

    atomicFence();
}
