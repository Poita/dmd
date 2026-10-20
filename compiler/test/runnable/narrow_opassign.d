/* PERMUTE_ARGS: -O -inline
 */
// Compound assignment to narrow integers through every kind of lvalue
// computes what constant folding computes, for every operator and for
// right operands of several types.

import core.stdc.stdio;

struct W(T) { T pad; T f; }

template globalSlot(T) { __gshared T[2] globalSlot; }

alias Seq(A...) = A;

enum string[] ops = ["+=", "-=", "*=", "/=", "%=", "<<=", ">>=", ">>>=", "&=", "|=", "^="];

alias Types = Seq!(byte, ubyte, short, ushort, char, wchar, int, uint);

long[] values(T)()
{
    static if (is(T == byte)) return [-128, -77, -1, 0, 1, 5, 127];
    else static if (is(T == ubyte) || is(T == char)) return [0, 1, 5, 128, 200, 255];
    else static if (is(T == short)) return [-32768, -12345, -1, 0, 7, 32767];
    else static if (is(T == ushort) || is(T == wchar)) return [0, 1, 300, 32768, 65535];
    else static if (is(T == int)) return [int.min, -100, -5, 0, 3, int.max];
    else return [0, 1, 7, 0x8000_0000, uint.max];
}

int failures;

immutable long[] shiftCounts = [1, 2, 3, 7, 15];

/* Results of `x op= b` for each value and count, where `x` is a local, an
 * array element, a struct field, a dereferenced pointer and, at run time, a
 * global, followed by the value of the expression itself
 */
pragma(inline, false)
long[] run(T, string op, R)(bool global)
{
    long[] res;
    foreach (a; values!T())
        foreach (c; shiftCounts)
        {
            R b = cast(R) c;
            static if (op == "/=" || op == "%=")
                if (b == 0 || (is(T == int) && a == int.min && b == -1))
                    continue;
            T x = cast(T) a;
            mixin("x " ~ op ~ " b;");
            T[3] arr = cast(T) a;
            mixin("arr[1] " ~ op ~ " b;");
            W!T w;
            w.f = cast(T) a;
            mixin("w.f " ~ op ~ " b;");
            T* p = &arr[2];
            mixin("*p " ~ op ~ " b;");
            T y = cast(T) a;
            T r = mixin("(y " ~ op ~ " b)");
            res ~= [x, arr[0], arr[1], w.f, arr[2], y, r];
            if (global)
            {
                globalSlot!T[1] = cast(T) a;
                mixin("globalSlot!T[1] " ~ op ~ " b;");
                if (globalSlot!T[1] != x)
                {
                    printf("%s %s %s global: %lld %lld\n", T.stringof.ptr, op.ptr, R.stringof.ptr, a, c);
                    ++failures;
                }
            }
        }
    return res;
}

void check(T, string op, R)()
{
    static immutable expected = run!(T, op, R)(false);
    const actual = run!(T, op, R)(true);
    if (actual != expected)
    {
        printf("%s %s %s\n", T.stringof.ptr, op.ptr, R.stringof.ptr);
        ++failures;
    }
}

// A signed left operand converted to an unsigned right operand's type
pragma(inline, false) T divUnsigned(T)(T a, uint b) { a /= b; return a; }
pragma(inline, false) T modUnsigned(T)(T a, uint b) { a %= b; return a; }

void main()
{
    static foreach (T; Types)
        static foreach (op; ops)
            static foreach (R; Seq!(int, long, uint, ubyte, T))
                static if (!((op == "/=" || op == "%=") && is(R == uint) && T.min < 0))
                    check!(T, op, R)();
    if (divUnsigned!byte(-128, 3) != 42 || modUnsigned!byte(-128, 3) != 2 ||
        divUnsigned!short(-100, 7) != 18710 || modUnsigned!short(-100, 7) != 2 ||
        divUnsigned!int(-100, 7) != 613566742 || modUnsigned!int(-100, 7) != 2)
        ++failures;
    if (failures)
        assert(0);
}
