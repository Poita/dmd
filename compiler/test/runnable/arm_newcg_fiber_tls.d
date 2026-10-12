/* REQUIRED_ARGS: -O
 */
// Fibers resumed by different threads, switching where Fiber.yield is inlined:
// the thread local variables after a switch are those of the thread it resumes on

import core.atomic;
import core.thread;

class TestFiber : Fiber
{
    this() { super(&run); }

    void run()
    {
        foreach (i; 0 .. 1000)
        {
            sum += i;
            Fiber.yield();
        }
    }

    size_t sum;
}

void main()
{
    shared bool[10] locks;
    __gshared TestFiber[10] fibs;
    foreach (ref fib; fibs)
        fib = new TestFiber();

    void runShared()
    {
        bool cont;
        do
        {
            cont = false;
            foreach (idx; 0 .. 10)
            {
                auto lock = cast(shared(bool)*) &locks[idx];
                if (cas(lock, false, true))
                {
                    if (fibs[idx].state == Fiber.State.HOLD)
                    {
                        fibs[idx].call();
                        cont |= fibs[idx].state != Fiber.State.TERM;
                    }
                    atomicStore(*lock, false);
                }
                else
                    cont = true;
            }
        } while (cont);
    }

    auto group = new ThreadGroup();
    foreach (_; 0 .. 4)
        group.create(&runShared);
    group.joinAll();
    foreach (fib; fibs)
        assert(fib.sum == 1000 * 999 / 2);
}
