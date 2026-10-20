// A struct of one scalar returned straight from a call returning the scalar.
module ret_wrapped;

import core.stdc.stdlib : malloc, free;
import core.stdc.math : sqrtf;

struct Ptr { void* p; }
struct Box { float f; }
struct Small { int v; }

extern (C) int abs(int);

Ptr make(size_t n) { return Ptr(malloc(n)); }
Box root(float x) { return Box(sqrtf(x)); }
Small magnitude(int x) { return Small(abs(x)); }

int main()
{
    auto p = make(16);
    if (p.p is null)
        assert(0);
    free(p.p);
    if (root(16.0f).f != 4.0f)
        assert(0);
    if (magnitude(-9).v != 9)
        assert(0);
    return 0;
}
