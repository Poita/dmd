/* REQUIRED_ARGS: -O
 */
// druntime's atomic or, expanded where it is called: the value before, the bits
// of each size or'ed in, and no update lost to threads or'ing other bits

import core.thread;

extern (C) nothrow @nogc
{
    ubyte  _d_aarch64_fetchor1(void* p, ubyte value);
    ushort _d_aarch64_fetchor2(void* p, ushort value);
    uint   _d_aarch64_fetchor4(void* p, uint value);
    ulong  _d_aarch64_fetchor8(void* p, ulong value);
}

shared ulong word;

void main()
{
    ubyte b = 0x81;
    assert(_d_aarch64_fetchor1(&b, 0x10) == 0x81 && b == 0x91);
    ushort h = 0x8001;
    assert(_d_aarch64_fetchor2(&h, 0x0100) == 0x8001 && h == 0x8101);
    uint w = 0x8000_0001;
    assert(_d_aarch64_fetchor4(&w, 0x10) == 0x8000_0001 && w == 0x8000_0011);
    ulong d = 1UL << 63;
    assert(_d_aarch64_fetchor8(&d, 2) == 1UL << 63 && d == (1UL << 63 | 2));

    Thread[8] ts;
    foreach (t; 0 .. 8)
    {
        ts[t] = new Thread({
            const k = cast(int)(Thread.getThis().name[0] - 'a');
            foreach (i; 0 .. 8)
                _d_aarch64_fetchor8(cast(void*)&word, 1UL << (k * 8 + i));
        });
        ts[t].name = [cast(char)('a' + t)];
        ts[t].start();
    }
    foreach (t; ts)
        t.join();
    assert(word == ulong.max);
}
