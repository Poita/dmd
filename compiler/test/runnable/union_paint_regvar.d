/* REQUIRED_ARGS: -O
 */

// A floating point variable that is also accessed as an integer can be put
// in a general purpose register. Reduced from std.math.operations.cmp.

int cmp(const(double) x, const(double) y)
{
    union Repainter { double number; ulong bits; }
    enum msb = ~(ulong.max >>> 1);
    struct Vars { Repainter a, b; }
    Vars vars = void;
    vars.a.number = x;
    vars.b.number = y;
    static foreach (m; ["a", "b"])
    {{
        ref var = __traits(getMember, vars, m);
        if (var.bits & msb)
            var.bits = ~var.bits;
        else
            var.bits |= msb;
    }}
    if (vars.a.bits < vars.b.bits)
        return -1;
    else if (vars.a.bits > vars.b.bits)
        return 1;
    else
        return 0;
}

void main()
{
    assert(cmp(1.0, 2.0) == -1);
    assert(cmp(2.0, 1.0) == 1);
    assert(cmp(-1.0, 1.0) == -1);
    assert(cmp(-0.0, 0.0) == -1);
    assert(cmp(3.5, 3.5) == 0);
}
