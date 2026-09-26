module imports.parallel_spec_b;

/* This module is the largest of the test's modules, so that a worker takes it first.
 * The template instances it needs are added to imports.parallel_spec_a, which
 * another worker takes.
 *
 * ................................................................................
 * ................................................................................
 * ................................................................................
 * ................................................................................
 * ................................................................................
 * ................................................................................
 * ................................................................................
 */

import core.stdc.stdio;

struct File
{
    struct Impl
    {
        FILE* handle;
    }
    Impl* _p;

    void closeHandles()
    {
        import imports.parallel_spec_a;
        import core.sys.posix.stdio;
        auto res = pclose(_p.handle);
        errnoEnforce(res != 1);
    }

    @property isOpen()
    {
        return _p !is null;
    }

    T[] rawRead(T)(T)
    {
        import imports.parallel_spec_a;
        enforce(isOpen);
    }

    // Instantiates enforce!bool speculatively, before the compilation is split
    static assert(!__traits(compiles, { int[] bar; rawRead(bar); }));
}
