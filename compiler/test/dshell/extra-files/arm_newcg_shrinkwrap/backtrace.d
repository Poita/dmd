// Backtraces through frames set up late: the unwinder, by the frames' call frame
// information, and the runtime's trace of an exception both find every caller.
module backtrace;

// asserts are compiled out with -release
void check(bool ok, int line = __LINE__)
{
    import core.stdc.stdio : fprintf, stderr;
    import core.stdc.stdlib : exit;
    if (!ok)
    {
        fprintf(stderr, "check failed at line %d\n", line);
        exit(1);
    }
}

import core.stdc.string : strstr;
import core.sys.darwin.dlfcn : dladdr, Dl_info;

extern (C) nothrow
{
    alias TraceFn = int function(void* context, void* arg);
    int _Unwind_Backtrace(TraceFn fn, void* arg);
    size_t _Unwind_GetIP(void* context);
}

__gshared const(char)*[64] names;
__gshared size_t nnames;
__gshared long sink;

extern (C) int collect(void* context, void* arg) nothrow
{
    Dl_info info;
    const ip = _Unwind_GetIP(context);
    if (nnames < names.length && dladdr(cast(void*)(ip - 1), &info) && info.dli_sname)
        names[nnames++] = info.dli_sname;
    return 0;
}

pragma(inline, false) void leaf(long k)
{
    if (k == 99)
        throw new Exception("from leaf");
    nnames = 0;
    _Unwind_Backtrace(&collect, null);
    sink += k;
}

pragma(inline, false) long wrapped_b(long a, long k)
{
    if (k < 0)
        return a;
    leaf(k);
    return a + k;
}

pragma(inline, false) long wrapped_a(long a, long k)
{
    if (a == 0)
        return k;
    const r = wrapped_b(a * 2, k);
    sink += r;
    return r + a;
}

// the position of the first of the names containing s from i on, or names.length
size_t find(const(char)* s, size_t i)
{
    for (; i < nnames; ++i)
        if (strstr(names[i], s))
            return i;
    return names.length;
}

void main()
{
    check(wrapped_a(3, 5) == 3 + 6 + 5);
    const l = find("4leaf", 0);
    const b = find("wrapped_b", l);
    const a = find("wrapped_a", b);
    const m = find("_Dmain", a);
    check(l < b && b < a && a < m && m < names.length);
    check(b == l + 1 && a == b + 1 && m == a + 1);

    try
    {
        wrapped_a(4, 99);
        check(false);
    }
    catch (Exception e)
    {
        bool sawB, sawA;
        foreach (line; e.info)
        {
            import std.algorithm : canFind;
            sawB |= line.canFind("wrapped_b");
            sawA |= line.canFind("wrapped_a");
        }
        check(sawB && sawA);
    }
}
