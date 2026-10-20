/* REQUIRED_ARGS: -O -inline
PERMUTE_ARGS: -release
*/
// A load moved before a loop runs even when the loop would not have made it.
// That is safe only for bytes known to be there: a load of other bytes through
// the same pointer may reach an inaccessible page. The page used lies between
// two inaccessible ones.

import core.sys.posix.sys.mman;
import core.sys.posix.unistd : sysconf, _SC_PAGESIZE;

ubyte* guardedPage()
{
    const page = cast(size_t) sysconf(_SC_PAGESIZE);
    auto m = cast(ubyte*) mmap(null, 3 * page, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (m is cast(ubyte*) MAP_FAILED)
        assert(0);
    if (mprotect(m, page, PROT_NONE) != 0 || mprotect(m + 2 * page, page, PROT_NONE) != 0)
        assert(0);
    return m + page;
}

// a load in a loop with no stores, of other bytes than the one read before it
pragma(inline, false) int readFar(int* p, int n, int len)
{
    int s = p[0];
    for (int i = 0; i < n; i++)
        if (len > 1000)
            s += p[1000];
    return s;
}

// the same in a loop that runs at least once
pragma(inline, false) int readFarDo(int* p, int n, int len)
{
    int s = p[0];
    int i = 0;
    do
    {
        if (len > 1000)
            s += p[1000];
    } while (++i < n);
    return s;
}

// memory a loop reads and writes, of other bytes than the one read before it
pragma(inline, false) int updateFar(int* p, int n, int len)
{
    int s = p[0];
    for (int i = 0; i < n; i++)
        if (len > 1000)
            p[1000] += i;
    return s;
}

// a store before the loop, of other bytes
pragma(inline, false) int storeThenReadFar(int* p, int n, int len)
{
    p[0] = 9;
    int s;
    for (int i = 0; i < n; i++)
    {
        p[0] = i;
        if (len > 1000)
            s += p[-2000];
    }
    return s;
}

// memory read before the loop, released by a call before the loop
pragma(inline, false) void release(void* m)
{
    if (munmap(m, cast(size_t) sysconf(_SC_PAGESIZE)) != 0)
        assert(0);
}

pragma(inline, false) int readAfterRelease(int* p, int n, int len)
{
    int s = p[0];
    release(p);
    for (int i = 0; i < n; i++)
        if (len > 1000)
            s += p[0];
    return s;
}

pragma(inline, false) int readAfterReleaseJoin(int* p, int n, int len)
{
    int s = p[0];
    if (len < 0)
        s = 7;
    release(p);
    for (int i = 0; i < n; i++)
        if (len > 1000)
            s += p[0];
    return s;
}

pragma(inline, false) int updateAfterRelease(int* p, int n, int len)
{
    int s = p[0];
    release(p);
    for (int i = 0; i < n; i++)
        if (len > 1000)
            p[0] += i;
    return s;
}

void main()
{
    const page = cast(size_t) sysconf(_SC_PAGESIZE);
    ubyte* m = guardedPage();
    int* p = cast(int*)(m + page - int.sizeof);    // the last int of the page
    *p = 3;
    if (readFar(p, 5, 0) != 3)
        assert(0);
    if (readFarDo(p, 5, 0) != 3)
        assert(0);
    if (updateFar(p, 5, 0) != 3)
        assert(0);
    int* q = cast(int*) m;                          // the first int of the page
    if (storeThenReadFar(q, 5, 0) != 0)
        assert(0);

    foreach (f; [&readAfterRelease, &readAfterReleaseJoin, &updateAfterRelease])
    {
        int* r = cast(int*) guardedPage();
        *r = 4;
        if (f(r, 5, 0) != 4)
            assert(0);
    }
}
