// Aggregates of one float or double read where the optimizer types them as that
// float or double, which is held in a V register.
module hfa_scalar;

struct W { double v; alias v this; }
struct F { float v; alias v this; }

pragma(inline, false) W calleeSum(W[] r, ref W a)
{
    foreach (W e; r)
        a = a + e;
    return a;
}

pragma(inline, false) F calleeSumF(const(F)[] r, ref F a)
{
    foreach (F e; r)
        a = a * 2 + e;
    return a;
}

pragma(inline, false) double calleeLast(const(W)* p, size_t n) { return p[n - 1] * 3; }

double total(W[] r)
{
    W s = W(0.5);
    return calleeSum(r, s) + s;
}

void main()
{
    W[] arr = [W(1), W(2), W(4)];
    assert(total(arr) == 15);
    F f = F(1);
    const fs = [F(1), F(0.5f)];
    assert(calleeSumF(fs, f) == 6.5f && f == 6.5f);
    assert(calleeLast(arr.ptr, arr.length) == 12);
}
