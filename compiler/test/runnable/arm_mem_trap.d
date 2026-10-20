/* REQUIRED_ARGS: -O -inline
PERMUTE_ARGS: -release
*/
// Loads that a loop makes only under a condition that is false, of memory that
// is not accessible. A load moved before the loop must not fault: an access of
// the same bytes made before the loop shows them accessible only when it is
// made on every way to the loop, covers the bytes, and no call that may release
// them comes between.

import core.sys.posix.sys.mman;
import core.sys.posix.unistd : sysconf, _SC_PAGESIZE;

size_t pageSize() { return cast(size_t) sysconf(_SC_PAGESIZE); }

// an accessible page between two inaccessible ones
ubyte* guardedPage()
{
    const page = pageSize();
    auto m = cast(ubyte*) mmap(null, 3 * page, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (m is cast(ubyte*) MAP_FAILED)
        assert(0);
    if (mprotect(m, page, PROT_NONE) != 0 || mprotect(m + 2 * page, page, PROT_NONE) != 0)
        assert(0);
    return m + page;
}

// an inaccessible page
int* noAccess()
{
    return cast(int*)(guardedPage() - pageSize());
}

pragma(inline, false) void release(void* m)
{
    if (munmap(m, pageSize()) != 0)
        assert(0);
}

// the access before the loop is made only under a condition
pragma(inline, false) int conditionalWitness(int* p, bool c, int n, int len)
{
    int s;
    if (c)
        s = p[0];
    for (int i = 0; i < n; i++)
        if (len > 1000)
            s += p[0];
    return s;
}

// the access before the loop is in a loop that may not run
pragma(inline, false) int loopWitness(int* p, int m, int n, int len)
{
    int s;
    for (int j = 0; j < m; j++)
        s += p[0];
    for (int i = 0; i < n; i++)
        if (len > 1000)
            s += p[0];
    return s;
}

// a null pointer is read only when it is not null
pragma(inline, false) int nullGuarded(int* p, int n)
{
    int s;
    if (p !is null)
        s = p[0];
    for (int i = 0; i < n; i++)
        if (p !is null)
            s += p[1];
    return s;
}

// a byte read before the loop does not show the int at it is accessible
pragma(inline, false) int narrowWitness(int* p, int n, int len)
{
    int s = *cast(ubyte*) p;
    for (int i = 0; i < n; i++)
        if (len > 1000)
            s += p[0];
    return s;
}

// the memory read before the loop may be released on one way to it
pragma(inline, false) int releaseOnOneWay(int* p, bool c, int n, int len)
{
    int s = p[0];
    if (c)
        release(p);
    for (int i = 0; i < n; i++)
        if (len > 1000)
            s += p[0];
    return s;
}

// the same, where the loop keeps the memory in a register
pragma(inline, false) int updateAfterReleaseOnOneWay(int* p, bool c, int n, int len)
{
    int s = p[0];
    if (c)
        release(p);
    for (int i = 0; i < n; i++)
        if (len > 1000)
            p[0] += i;
    return s;
}

// a store before the loop only under a condition, then the loop updates the memory
pragma(inline, false) int conditionalStoreWitness(int* p, bool c, int n, int len)
{
    if (c)
        p[0] = 1;
    for (int i = 0; i < n; i++)
        if (len > 1000)
            p[0] += i;
    return n;
}

// the loop releases the memory before it would read it
pragma(inline, false) int releaseInLoop(int* p, int n, int len)
{
    int s = p[0];
    for (int i = 0; i < n; i++)
    {
        if (i == 0)
            release(p);
        else if (len > 1000)
            s += p[0];
    }
    return s;
}

// the access before the loop is through a pointer that changes after it
pragma(inline, false) int rebasedWitness(int* p, int* q, bool c, int n, int len)
{
    int s = p[0];
    if (c)
        p = q;
    for (int i = 0; i < n; i++)
        if (len > 1000)
            s += p[0];
    return s;
}

// a field read through a pointer loaded before the loop, of other bytes
pragma(inline, false) int otherField(int** pp, int n, int len)
{
    int* p = *pp;
    int s;
    for (int i = 0; i < n; i++)
        if (len > 1000)
            s += p[0];
    return s;
}

// the loop runs zero times
pragma(inline, false) int zeroTrip(int* p, int n)
{
    int s;
    for (int i = 0; i < n; i++)
        s += p[0];
    return s;
}

// the loop updates memory only in one arm, and runs zero times
pragma(inline, false) int zeroTripUpdate(int* p, int n)
{
    for (int i = 0; i < n; i++)
        p[0] += i;
    return n;
}

void main()
{
    if (conditionalWitness(noAccess(), false, 5, 0) != 0)
        assert(0);
    if (loopWitness(noAccess(), 0, 5, 0) != 0)
        assert(0);
    if (nullGuarded(null, 5) != 0)
        assert(0);
    {
        // the last byte of a page
        int* p = cast(int*)(guardedPage() + pageSize() - 1);
        *cast(ubyte*) p = 6;
        if (narrowWitness(p, 5, 0) != 6)
            assert(0);
    }
    foreach (f; [&releaseOnOneWay, &updateAfterReleaseOnOneWay])
    {
        int* p = cast(int*) guardedPage();
        *p = 4;
        if (f(p, true, 5, 0) != 4)
            assert(0);
    }
    if (conditionalStoreWitness(noAccess(), false, 5, 0) != 5)
        assert(0);
    {
        int* p = cast(int*) guardedPage();
        *p = 2;
        if (releaseInLoop(p, 5, 0) != 2)
            assert(0);
    }
    {
        int* p = cast(int*) guardedPage();
        *p = 3;
        if (rebasedWitness(p, noAccess(), true, 5, 0) != 3)
            assert(0);
    }
    {
        int* p = noAccess();
        if (otherField(&p, 5, 0) != 0)
            assert(0);
    }
    if (zeroTrip(noAccess(), 0) != 0)
        assert(0);
    if (zeroTripUpdate(noAccess(), 0) != 0)
        assert(0);
}
