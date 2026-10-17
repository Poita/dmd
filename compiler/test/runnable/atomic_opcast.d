// Atomic operations copy the bits of a struct; they never invoke its opCast.
import core.atomic;

align(16) struct Handle
{
    size_t value;
    uint counter;

    U opCast(U)() const
        if (is(U.BaseType))
    {
        return U(value + 1000, counter);
    }

    U opCast(U)() const
        if (is(U == bool))
    {
        return value != 0;
    }
}

struct Id
{
    size_t value;

    U opCast(U)() const
    {
        static assert(0, "opCast!" ~ U.stringof ~ " must not be instantiated");
    }
}

void main()
{
    shared Handle h = Handle(7, 3);
    Handle got = atomicLoad(h);
    if (got.value != 7 || got.counter != 3)
        assert(0);

    shared Id id = Id(5);
    if (atomicLoad(id).value != 5)
        assert(0);
    if (!cas(&id, Id(5), Id(6)))
        assert(0);
    if (atomicLoad(id).value != 6)
        assert(0);
}
