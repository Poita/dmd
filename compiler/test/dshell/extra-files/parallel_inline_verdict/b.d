module b;

import a;

// The compile-time evaluation makes the worker compiling this module consider inlining
// `a.f` well after the worker compiling `a` has found that it cannot be inlined.
int h()
{
    enum slow = () { long s; foreach (i; 0 .. 3_000_000) s += i; return s; }();
    return f(cast(int) (slow & 3));
}
