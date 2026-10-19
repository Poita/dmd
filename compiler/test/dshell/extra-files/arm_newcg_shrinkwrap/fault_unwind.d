// Unwinding from a fault in code running without the frame, before the prolog's block
// and laid out after it: the call frame information there says the CFA is SP and the
// return address is in x30, so the unwinder, started from the faulting instruction,
// finds the caller next.
module fault_unwind;

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

import core.stdc.stdlib : _Exit;
import core.stdc.string : strstr;
import core.sys.darwin.dlfcn : dladdr, Dl_info;
import core.sys.posix.signal;
import core.sys.posix.ucontext : ucontext_t;

extern (C) nothrow @nogc
{
    struct unw_context_t { ulong[66] data; }
    struct unw_cursor_t { ulong[78] data; }
    int unw_init_local(unw_cursor_t* cursor, unw_context_t* context);
    int unw_step(unw_cursor_t* cursor);
    int unw_get_reg(unw_cursor_t* cursor, int reg, ulong* value);
}
enum UNW_REG_IP = -1;

__gshared long sink;

pragma(inline, false) void heavy(long x) { sink += x; }

// the path without the frame laid out after the one with it
pragma(inline, false) long wrapped_after(const(long)* p, long k)
{
    if (k > 0)
    {
        heavy(k);
        heavy(k + 1);
        return k;
    }
    // the load is not the first instruction, whose row the unwinder takes as the
    // one before, as for a return address
    return *(p - k) * 3;
}

// the path without the frame laid out before the one with it
pragma(inline, false) long wrapped_before(const(long)* p, long k)
{
    if (k <= 0)
        return *(p - k) * 5;
    heavy(k);
    heavy(k + 1);
    return k;
}

pragma(inline, false) long caller(const(long)* p, long k, bool before)
{
    const r = before ? wrapped_before(p, k) : wrapped_after(p, k);
    heavy(r);
    return r + 1;
}

// whether the function the frame of the cursor is in has a name containing s
bool inFunction(unw_cursor_t* cursor, const(char)* s, bool first) nothrow @nogc
{
    ulong ip;
    unw_get_reg(cursor, UNW_REG_IP, &ip);
    Dl_info info;
    return dladdr(cast(void*)(first ? ip : ip - 1), &info) && info.dli_sname && strstr(info.dli_sname, s);
}

extern (C) void onFault(int sig, siginfo_t* info, void* context) nothrow @nogc
{
    // the registers of the faulting code: the thread state follows the exception state
    auto mc = cast(const(ulong)*)(cast(ucontext_t*)context).uc_mcontext;
    unw_context_t uc;
    uc.data[0 .. 34] = mc[2 .. 36];         // x0 .. x28, fp, lr, sp, pc
    unw_cursor_t cursor;
    const ok = unw_init_local(&cursor, &uc) == 0 &&
        inFunction(&cursor, before ? "wrapped_before" : "wrapped_after", true) &&
        unw_step(&cursor) > 0 && inFunction(&cursor, "caller", false) &&
        unw_step(&cursor) > 0 && inFunction(&cursor, "_Dmain", false);
    _Exit(ok ? 0 : 1);
}

__gshared bool before;          // whether the fault is in wrapped_before

void main()
{
    import core.sys.posix.sys.wait : waitpid, WIFEXITED, WEXITSTATUS;
    import core.sys.posix.unistd : fork;

    long x = 4;
    check(caller(&x, 0, false) == 13);
    check(caller(&x, 0, true) == 21);
    check(caller(null, 2, false) == 3);
    check(caller(null, 2, true) == 3);

    foreach (b; [false, true])
    {
        const pid = fork();
        if (pid == 0)
        {
            before = b;
            sigaction_t sa;
            sa.sa_flags = SA_SIGINFO;
            sa.sa_sigaction = &onFault;
            sigaction(SIGSEGV, &sa, null);
            sigaction(SIGBUS, &sa, null);
            caller(null, 0, b);
            _Exit(3);
        }
        int status;
        waitpid(pid, &status, 0);
        check(WIFEXITED(status) && WEXITSTATUS(status) == 0);
    }
}
