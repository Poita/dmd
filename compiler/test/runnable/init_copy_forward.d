/* REQUIRED_ARGS: -O
 */
// A local that is only ever a copy of a struct's .init is read from the .init itself,
// so a large one costs no stack: the reads run on a thread with a small stack

import core.thread;

struct Big
{
    float a = 1.5f;
    int b = 7;
    ubyte[600_000] pad;
    float c = 2.5f;
}

pragma(inline, false) int check(int k)
{
    const p = Big.init;
    return p.b == 7 && p.c == 2.5f && p.pad[k] == 0 ? 1 : 0;
}

// written after the copy, so it must have a place of its own
pragma(inline, false) int written(int k)
{
    Big* q = new Big;
    q.pad[k] = 3;
    return q.pad[k] + q.b;
}

void main()
{
    int r;
    auto t = new Thread({ r = check(12_345); }, 64 * 1024);
    t.start();
    t.join();
    assert(r == 1);
    assert(written(5) == 10);
}
