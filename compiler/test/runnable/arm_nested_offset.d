// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Loads and stores through members of members, whose addresses are
 * nested additions of constants folded into one offset.
 */

struct Inner { uint a; float[] h; }
struct Outer { ulong pad; Inner inner; ubyte[] scratch; }

float getH(ref Outer o, size_t i) { return o.inner.h[i]; }
size_t lenH(ref Outer o) { return o.inner.h.length; }
uint getA(ref Outer o) { return o.inner.a; }
void putScratch(ref Outer o, size_t i) { o.scratch.ptr[i] = 7; }
void setA(ref Outer o, uint v) { o.inner.a = v; }
void setPtr(ref Outer o, float* p) { *cast(float**)(cast(ubyte*)&o.inner.h + size_t.sizeof) = p; }

int main()
{
    float[3] h = [1.5f, 2.5f, 3.5f];
    ubyte[4] s;
    Outer o;
    o.inner.a = 5;
    o.inner.h = h[];
    o.scratch = s[];
    assert(getH(o, 2) == 3.5f);
    assert(lenH(o) == 3);
    assert(getA(o) == 5);
    putScratch(o, 3);
    assert(s[3] == 7);
    setA(o, 9);
    assert(o.inner.a == 9);
    float[2] g = [8.0f, 9.0f];
    setPtr(o, g.ptr);
    assert(getH(o, 1) == 9.0f);
    return 0;
}
