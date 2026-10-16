/* REQUIRED_ARGS: -O -inline
 */
// A null object passed to code that never calls through it on the paths taken is
// valid, however much of that code is inlined where the null is known

interface Runner
{
    void wait();
}

class Counter : Runner
{
    int waits;
    void wait() { ++waits; }
}

struct Pipeline
{
    int waited, steps, kicked;

    pragma(inline, true) void join(Runner runner)
    {
        if (kicked - steps < 2)
            return;
        publish(runner);
    }

    pragma(inline, true) void drain(Runner runner)
    {
        while (kicked > steps)
            publish(runner);
    }

    pragma(inline, true) private void publish(Runner runner)
    {
        while (waited <= steps)
        {
            runner.wait();
            ++waited;
        }
        ++steps;
    }
}

void main()
{
    Pipeline p;
    p.waited = 100;         // ahead of the steps, so the runner is never used
    foreach (i; 0 .. 5)
    {
        p.join(null);
        ++p.kicked;
    }
    p.drain(null);
    assert(p.steps == 5);

    auto r = new Counter;
    Pipeline q;
    q.kicked = 2;
    q.drain(r);
    assert(q.steps == 2 && r.waits == 2);
}
