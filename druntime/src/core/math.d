// Written in the D programming language.

/**
 * Builtin mathematical intrinsics
 *
 * Source: $(DRUNTIMESRC core/_math.d)
 * Macros:
 *      TABLE_SV = <table border="1" cellpadding="4" cellspacing="0">
 *              <caption>Special Values</caption>
 *              $0</table>
 *
 *      NAN = $(RED NAN)
 *      SUP = <span style="vertical-align:super;font-size:smaller">$0</span>
 *      POWER = $1<sup>$2</sup>
 *      PLUSMN = &plusmn;
 *      INFIN = &infin;
 *      PLUSMNINF = &plusmn;&infin;
 *      LT = &lt;
 *      GT = &gt;
 *
 * Copyright: Copyright Digital Mars 2000 - 2011.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   $(HTTP digitalmars.com, Walter Bright),
 *                        Don Clugston
 */
module core.math;

public:
@nogc:
nothrow:
@safe:

pure:

// DMD has no AArch64 instructions for these intrinsics, so they call the C library
version (DigitalMars) version (AArch64) version = LibmFallback;

version (LibmFallback)
private extern (C) @trusted
{
    pragma(mangle, "cosf")    float  c_cosf(float x);
    pragma(mangle, "cos")     double c_cos(double x);
    pragma(mangle, "cosl")    real   c_cosl(real x);
    pragma(mangle, "sinf")    float  c_sinf(float x);
    pragma(mangle, "sin")     double c_sin(double x);
    pragma(mangle, "sinl")    real   c_sinl(real x);
    pragma(mangle, "llrintf") long   c_llrintf(float x);
    pragma(mangle, "llrint")  long   c_llrint(double x);
    pragma(mangle, "llrintl") long   c_llrintl(real x);
    pragma(mangle, "ldexpf")  float  c_ldexpf(float n, int exp);
    pragma(mangle, "ldexp")   double c_ldexp(double n, int exp);
    pragma(mangle, "ldexpl")  real   c_ldexpl(real n, int exp);
    pragma(mangle, "rintf")   float  c_rintf(float x);
    pragma(mangle, "rint")    double c_rint(double x);
    pragma(mangle, "rintl")   real   c_rintl(real x);
    pragma(mangle, "log2f")   float  c_log2f(float x);
    pragma(mangle, "log2")    double c_log2(double x);
    pragma(mangle, "log2l")   real   c_log2l(real x);
    pragma(mangle, "log1pf")  float  c_log1pf(float x);
    pragma(mangle, "log1p")   double c_log1p(double x);
    pragma(mangle, "log1pl")  real   c_log1pl(real x);
}

/***********************************
 * Returns cosine of x. x is in radians.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH cos(x)) $(TH invalid?))
 *      $(TR $(TD $(NAN))            $(TD $(NAN)) $(TD yes)     )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(NAN)) $(TD yes)     )
 *      )
 * Bugs:
 *      Results are undefined if |x| >= $(POWER 2,64).
 */

version (LibmFallback)
{
float cos(float x) { return c_cosf(x); }
double cos(double x) { return c_cos(x); }
real cos(real x) { return c_cosl(x); }
}
else
{
float cos(float x);     /* intrinsic */
double cos(double x);   /* intrinsic */ /// ditto
real cos(real x);       /* intrinsic */ /// ditto
}

/***********************************
 * Returns sine of x. x is in radians.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)               $(TH sin(x))      $(TH invalid?))
 *      $(TR $(TD $(NAN))          $(TD $(NAN))      $(TD yes))
 *      $(TR $(TD $(PLUSMN)0.0)    $(TD $(PLUSMN)0.0) $(TD no))
 *      $(TR $(TD $(PLUSMNINF))    $(TD $(NAN))      $(TD yes))
 *      )
 * Bugs:
 *      Results are undefined if |x| >= $(POWER 2,64).
 */

version (LibmFallback)
{
float sin(float x) { return c_sinf(x); }
double sin(double x) { return c_sin(x); }
real sin(real x) { return c_sinl(x); }
}
else
{
float sin(float x);     /* intrinsic */
double sin(double x);   /* intrinsic */ /// ditto
real sin(real x);       /* intrinsic */ /// ditto
}

/*****************************************
 * Returns x rounded to a long value using the current rounding mode.
 * If the integer value of x is
 * greater than long.max, the result is
 * indeterminate.
 */

version (LibmFallback)
{
long rndtol(float x) { return c_llrintf(x); }
long rndtol(double x) { return c_llrint(x); }
long rndtol(real x) { return c_llrintl(x); }
}
else
{
long rndtol(float x);   /* intrinsic */
long rndtol(double x);  /* intrinsic */ /// ditto
long rndtol(real x);    /* intrinsic */ /// ditto
}

/***************************************
 * Compute square root of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)         $(TH sqrt(x))   $(TH invalid?))
 *      $(TR $(TD -0.0)      $(TD -0.0)      $(TD no))
 *      $(TR $(TD $(LT)0.0)  $(TD $(NAN))    $(TD yes))
 *      $(TR $(TD +$(INFIN)) $(TD +$(INFIN)) $(TD no))
 *      )
 */

float sqrt(float x);    /* intrinsic */
double sqrt(double x);  /* intrinsic */ /// ditto
real sqrt(real x);      /* intrinsic */ /// ditto

/*******************************************
 * Compute n * 2$(SUPERSCRIPT exp)
 * References: frexp
 */

version (LibmFallback)
{
float ldexp(float n, int exp) { return c_ldexpf(n, exp); }
double ldexp(double n, int exp) { return c_ldexp(n, exp); }
real ldexp(real n, int exp) { return c_ldexpl(n, exp); }
}
else
{
float ldexp(float n, int exp);   /* intrinsic */
double ldexp(double n, int exp); /* intrinsic */ /// ditto
real ldexp(real n, int exp);     /* intrinsic */ /// ditto
}

unittest {
    static if (real.mant_dig == 113)
    {
        assert(ldexp(1.0L, -16384) == 0x1p-16384L);
        assert(ldexp(1.0L, -16382) == 0x1p-16382L);
    }
    else static if (real.mant_dig == 106)
    {
        assert(ldexp(1.0L,  1023) == 0x1p1023L);
        assert(ldexp(1.0L, -1022) == 0x1p-1022L);
        assert(ldexp(1.0L, -1021) == 0x1p-1021L);
    }
    else static if (real.mant_dig == 64)
    {
        assert(ldexp(1.0L, -16384) == 0x1p-16384L);
        assert(ldexp(1.0L, -16382) == 0x1p-16382L);
    }
    else static if (real.mant_dig == 53)
    {
        assert(ldexp(1.0L,  1023) == 0x1p1023L);
        assert(ldexp(1.0L, -1022) == 0x1p-1022L);
        assert(ldexp(1.0L, -1021) == 0x1p-1021L);
    }
    else
        assert(false, "Only 128bit, 80bit and 64bit reals expected here");
}

/*******************************
 * Compute the absolute value.
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH fabs(x)))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD +0.0) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD +$(INFIN)) )
 *      )
 * It is implemented as a compiler intrinsic.
 * Params:
 *      x = floating point value
 * Returns: |x|
 * References: equivalent to `std.math.fabs`
 */
@safe pure nothrow @nogc
{
    float  fabs(float  x);
    double fabs(double x); /// ditto
    real   fabs(real   x); /// ditto
}

/**********************************
 * Rounds x to the nearest integer value, using the current rounding
 * mode.
 * If the return value is not equal to x, the FE_INEXACT
 * exception is raised.
 * $(B nearbyint) performs
 * the same operation, but does not set the FE_INEXACT exception.
 */
version (LibmFallback)
{
float rint(float x) { return c_rintf(x); }
double rint(double x) { return c_rint(x); }
real rint(real x) { return c_rintl(x); }
}
else
{
float rint(float x);    /* intrinsic */
double rint(double x);  /* intrinsic */ /// ditto
real rint(real x);      /* intrinsic */ /// ditto
}

/***********************************
 * Building block functions, they
 * translate to a single x87 instruction.
 */
version (LibmFallback)
{
private enum real LOG2E = 0x1.71547652b82fe1777d0ffda0d23a8p+0L; // 1 / ln(2)
float yl2x(float x, float y) { return y * c_log2f(x); }
double yl2x(double x, double y) { return y * c_log2(x); }
real yl2x(real x, real y) { return y * c_log2l(x); }
float yl2xp1(float x, float y) { return y * c_log1pf(x) * cast(float) LOG2E; }
double yl2xp1(double x, double y) { return y * c_log1p(x) * cast(double) LOG2E; }
real yl2xp1(real x, real y) { return y * c_log1pl(x) * LOG2E; }
}
else
{
// y * log2(x)
float yl2x(float x, float y);    /* intrinsic */
double yl2x(double x, double y);  /* intrinsic */ /// ditto
real yl2x(real x, real y);      /* intrinsic */ /// ditto
// y * log2(x +1)
float yl2xp1(float x, float y);    /* intrinsic */
double yl2xp1(double x, double y);  /* intrinsic */ /// ditto
real yl2xp1(real x, real y);      /* intrinsic */ /// ditto
}

unittest
{
    version (INLINE_YL2X)
    {
        assert(yl2x(1024.0L, 1) == 10);
        assert(yl2xp1(1023.0L, 1) == 10);
    }
}

/*************************************
 * Round argument to a specific precision.
 *
 * D language types specify only a minimum precision, not a maximum. The
 * `toPrec()` function forces rounding of the argument `f` to the precision
 * of the specified floating point type `T`.
 * The rounding mode used is inevitably target-dependent, but will be done in
 * a way to maximize accuracy. In most cases, the default is round-to-nearest.
 *
 * Params:
 *      T = precision type to round to
 *      f = value to convert
 * Returns:
 *      f in precision of type `T`
 */
T toPrec(T:float)(float f) { pragma(inline, false); return f; }
/// ditto
T toPrec(T:float)(double f) { pragma(inline, false); return cast(T) f; }
/// ditto
T toPrec(T:float)(real f)  { pragma(inline, false); return cast(T) f; }
/// ditto
T toPrec(T:double)(float f) { pragma(inline, false); return f; }
/// ditto
T toPrec(T:double)(double f) { pragma(inline, false); return f; }
/// ditto
T toPrec(T:double)(real f)  { pragma(inline, false); return cast(T) f; }
/// ditto
T toPrec(T:real)(float f) { pragma(inline, false); return f; }
/// ditto
T toPrec(T:real)(double f) { pragma(inline, false); return f; }
/// ditto
T toPrec(T:real)(real f)  { pragma(inline, false); return f; }

@safe unittest
{
    // Test all instantiations work with all combinations of float.
    float f = 1.1f;
    double d = 1.1;
    real r = 1.1L;
    f = toPrec!float(f + f);
    f = toPrec!float(d + d);
    f = toPrec!float(r + r);
    d = toPrec!double(f + f);
    d = toPrec!double(d + d);
    d = toPrec!double(r + r);
    r = toPrec!real(f + f);
    r = toPrec!real(d + d);
    r = toPrec!real(r + r);

    // Comparison tests.
    bool approxEqual(T)(T lhs, T rhs)
    {
        return fabs((lhs - rhs) / rhs) <= 1e-2 || fabs(lhs - rhs) <= 1e-5;
    }

    enum real PIR = 0xc.90fdaa22168c235p-2;
    enum double PID = 0x1.921fb54442d18p+1;
    enum float PIF = 0x1.921fb6p+1;
    static assert(approxEqual(toPrec!float(PIR), PIF));
    static assert(approxEqual(toPrec!double(PIR), PID));
    static assert(approxEqual(toPrec!real(PIR), PIR));
    static assert(approxEqual(toPrec!float(PID), PIF));
    static assert(approxEqual(toPrec!double(PID), PID));
    static assert(approxEqual(toPrec!real(PID), PID));
    static assert(approxEqual(toPrec!float(PIF), PIF));
    static assert(approxEqual(toPrec!double(PIF), PIF));
    static assert(approxEqual(toPrec!real(PIF), PIF));

    assert(approxEqual(toPrec!float(PIR), PIF));
    assert(approxEqual(toPrec!double(PIR), PID));
    assert(approxEqual(toPrec!real(PIR), PIR));
    assert(approxEqual(toPrec!float(PID), PIF));
    assert(approxEqual(toPrec!double(PID), PID));
    assert(approxEqual(toPrec!real(PID), PID));
    assert(approxEqual(toPrec!float(PIF), PIF));
    assert(approxEqual(toPrec!double(PIF), PIF));
    assert(approxEqual(toPrec!real(PIF), PIF));
}
