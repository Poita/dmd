/* PERMUTE_ARGS: -O
 */
// Compound assignment evaluated at compile time computes what the generated
// code computes, for every pair of integer types: an unsigned operand makes
// division and remainder unsigned in the width of the promoted operands.

alias Seq(A...) = A;

alias Types = Seq!(byte, ubyte, short, ushort, int, uint, long, ulong);

enum string[] ops = ["/", "%", "+", "-", "*", "&", "|", "^"];

immutable long[] lhs = [-7, -1, 0, 1, 7, 100, -100, int.min, int.max, uint.max, long.min, long.max, -2_000_000_000_001];
immutable long[] rhs = [-7, -3, -1, 1, 2, 3, 5, 7, 100, -100, int.max, uint.max, 2_000_000_000_001];

T apply(string op, T, U)(T x, U y)
{
    mixin("x " ~ op ~ "= y;");
    return x;
}

bool valid(T, U, string op)(T x, U y)
{
    static if (op == "/" || op == "%")
    {
        if (y == 0)
            return false;
        // overflow of the signed division
        alias C = typeof(x / y);
        static if (__traits(isUnsigned, C))
            return true;
        else
            return !(y == -1 && cast(C)x == C.min);
    }
    else
        return true;
}

long[] results(T, U, string op)()
{
    long[] r;
    foreach (a; lhs)
        foreach (b; rhs)
        {
            T x = cast(T)a;
            U y = cast(U)b;
            r ~= valid!(T, U, op)(x, y) ? cast(long)apply!op(x, y) : 0;
        }
    return r;
}

void main()
{
    static foreach (op; ops)
        static foreach (T; Types)
            static foreach (U; Types)
            {{
                enum ct = results!(T, U, op)();
                const rt = results!(T, U, op)();
                foreach (i; 0 .. ct.length)
                    if (ct[i] != rt[i])
                    {
                        import core.stdc.stdio;
                        printf("%s %s= %s: lhs %lld rhs %lld: ctfe %lld, run time %lld\n",
                            T.stringof.ptr, op.ptr, U.stringof.ptr, lhs[i / rhs.length],
                            rhs[i % rhs.length], ct[i], rt[i]);
                        assert(0);
                    }
            }}
}
