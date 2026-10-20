/*
REQUIRED_ARGS: -g -O
DISABLED: win32 win64 linux32 freebsd32 openbsd32
*/

// The line table of optimized code locates each statement, so a backtrace
// names the line of the throw and of the call, not the function's first line.

import core.stdc.stdio : printf;
import core.stdc.stdlib : exit;
import core.stdc.string : strstr;

__gshared int sink;

pragma(inline, false) int thrower(int a, int b)
{
    int x = a * 3;
    sink += x;
    int y = b + x;
    if (y > 1000)
        sink -= y;
    if (y != 13)
        return x ^ y;
    throw new Exception("thrown");
}

pragma(inline, false) int caller(int n)
{
    int r = n + 1;
    sink += r;
    r = thrower(3, 4);
    return r * 2;
}

void check(const(char)[] trace, const(char)* what)
{
    char[4096] buf;
    const n = trace.length < buf.length - 1 ? trace.length : buf.length - 1;
    buf[0 .. n] = trace[0 .. n];
    buf[n] = 0;
    if (!strstr(buf.ptr, what))
    {
        printf("missing %s in:\n%s\n", what, buf.ptr);
        exit(1);
    }
}

void main()
{
    try
    {
        caller(5);
    }
    catch (Exception e)
    {
        auto s = e.toString();
        check(s, "backtrace_lines_opt.d:24 ");
        check(s, "backtrace_lines_opt.d:31 ");
        check(s, "backtrace_lines_opt.d:52 ");
        return;
    }
    printf("not thrown\n");
    exit(1);
}
