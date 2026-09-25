// D-style variadic functions: the hidden _arguments and `this`/context
// parameters are named parameters, only the `...` arguments are variadic.

import core.vararg;

size_t count(...) { return _arguments.length; }

int sum(int first, ...)
{
    int s = first;
    foreach (t; _arguments)
    {
        assert(t is typeid(int));
        s += va_arg!int(_argptr);
    }
    return s;
}

struct S { int[] arr; }

S make(...)
{
    S r;
    r.arr.length = _arguments.length;
    return r;
}

class C
{
    int base = 100;
    int add(...)
    {
        int s = base;
        foreach (t; _arguments)
            s += va_arg!int(_argptr);
        return s;
    }
}

void main()
{
    assert(count() == 0);
    assert(count(1, 2) == 2);
    assert(count(1, "a", 3.0) == 3);
    assert(sum(1, 2, 3) == 6);
    assert(make(1, 2).arr.length == 2);
    assert(new C().add(1, 2, 3) == 106);

    int local = 7;
    int nested(...) { return local + cast(int) _arguments.length; }
    assert(nested(1, 2) == 9);
}
