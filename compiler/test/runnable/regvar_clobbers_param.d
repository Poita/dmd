/* REQUIRED_ARGS: -inline
 */

// Assigning a constant to a register variable must mark its register as
// modified, so a parameter that arrived in that register (`this` here) is
// not read back from it afterwards. Reduced from druntime's Array.insertBack.

import common = core.internal.container.common;

import core.exception ;

struct Array(T)
{
    @property length()     {
        return _length;
    }

    @property length(size_t nlength)
    {
        import core.checkedint ;

        bool overflow ;
        size_t reqsize = mulu(T.sizeof, nlength, overflow);
        if (!overflow)
        {
            if (_length)
                foreach (val; _ptr[nlength .. _length]) destroy(val);
            _ptr = cast(T*)common.xrealloc(_ptr, reqsize);
            if (nlength )
                foreach (val; _ptr[_length .. nlength]) common.initialize(val);
            _length = nlength;
        }
        else
            onOutOfMemoryError;

    }

inout(T) back() inout
    {
        return _ptr[_length ];
    }

    void insertBack()
    {
        import core.checkedint ;

        bool overflow ;
        size_t newlength = addu(length, 1, overflow);
        if (!overflow)
        {
            length = newlength;
            back ;
        }
        else
            onOutOfMemoryError;
    }

    T* _ptr;
    size_t _length;
}

Array!(void[]) ranges;
pragma(inline, false) void insert(ref Array!(void[]) a) { a.insertBack(); }

extern (C) int main()
{
    insert(ranges);
    assert(ranges.length == 1);
    return 0;
}
