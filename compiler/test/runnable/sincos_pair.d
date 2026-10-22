// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* On Darwin the sine and cosine of one value, both computed in the same
 * straight-line code, come from a single __sincos_stret / __sincosf_stret
 * call, as LLVM selects them; a sine or cosine on its own is the libm call.
 * The two differ in the last bit for some arguments, so the choice decides
 * whether the results match the LLVM-built code bit for bit. A constant
 * argument is folded as LLVM folds it: in double, then rounded.
 */

import core.math : cos, sin;

version (OSX) version (AArch64) version = DarwinArm;

version (DarwinArm)
{
    struct F2 { float s, c; }
    struct D2 { double s, c; }
    extern (C) F2 __sincosf_stret(float);
    extern (C) D2 __sincos_stret(double);
    extern (C) float sinf(float);
    pragma(mangle, "sin") extern (C) double c_sin(double);
}

// Opaque to the optimizer, so nothing is folded at compile time
pragma(inline, false) T opaque(T)(T x) { return x; }

pragma(inline, false) float sinOnly(float x) { return sin(x); }

pragma(inline, false) void pairF(float x, out float s, out float c)
{
    s = sin(x);
    c = cos(x);
}

pragma(inline, false) void pairD(double x, out double s, out double c)
{
    s = sin(x);
    c = cos(x);
}

pragma(inline, false) float pairExpr(float r)
{
    const half = r * 0.5f;
    return sin(half) * 3 + cos(half);
}

struct V2 { float x, y; }

// Both calls in one expression
pragma(inline, false) V2 polar(float a, float r)
{
    return V2(cos(a) * r, sin(a) * r);
}

// Through a pointer, with a branch before and between
pragma(inline, false) float viaPointer(const(float)* p, bool b)
{
    float t = b ? 1 : 2;
    const s = sin(*p);
    t += b ? 3 : 4;
    return s * t + cos(*p);
}

// In a loop, the argument assigned in the call
pragma(inline, false) float loop(float r, int n)
{
    float acc = 0;
    float h;
    foreach (i; 0 .. n)
    {
        acc += sin(h = r * i) + cos(h);
    }
    return acc;
}

pragma(inline, false) float sinConst() { return sin(0x1.000032p-1f); }
pragma(inline, false) float cosConst() { return cos(0x1.0007b8p-1f); }
pragma(inline, false) double sinConstD() { return sin(0x1.9999ap-4); }

// The argument changes between the calls, so they stay separate
pragma(inline, false) void changed(float x, out float s, out float c)
{
    s = sin(x);
    x += 1;
    c = cos(x - 1);
}

void main()
{
    version (DarwinArm)
    {
        const float xf = opaque(0x1.9999b2p-4f);     // sinf and __sincosf_stret differ here
        const double xd = opaque(0x1.9999ap-4);      // sin and __sincos_stret differ here
        const rf = __sincosf_stret(xf);
        const rd = __sincos_stret(xd);
        assert(rf.s != sinf(xf) && rd.s != c_sin(xd));

        float s, c;
        pairF(xf, s, c);
        assert(s == rf.s && c == rf.c);

        double sd, cd;
        pairD(xd, sd, cd);
        assert(sd == rd.s && cd == rd.c);

        const r = __sincosf_stret(xf);
        assert(pairExpr(opaque(xf * 2)) == r.s * 3 + r.c);

        assert(sinOnly(xf) == sinf(xf));

        const v = polar(xf, 2);
        assert(v.x == rf.c * 2 && v.y == rf.s * 2);

        float pv = xf;
        assert(viaPointer(&pv, true) == rf.s * 4 + rf.c);

        float expect = 0;
        foreach (i; 0 .. 3)
        {
            const q = __sincosf_stret(xf * i);
            expect += q.s + q.c;
        }
        assert(loop(opaque(xf), 3) == expect);

        // sinf would give 0x1.eaeedep-2f and cosf 0x1.c14eccp-1f
        assert(sinConst() == 0x1.eaeeep-2f);
        assert(cosConst() == 0x1.c14ecep-1f);
        assert(sinConstD() == c_sin(xd));

        changed(xf, s, c);
        assert(s == sinf(xf));
    }
}
