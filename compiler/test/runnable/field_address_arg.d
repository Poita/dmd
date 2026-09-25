// The address of a field of a small aggregate is passed as a pointer,
// not as the aggregate it points into.

struct Mask { uint bits; }
struct Action { void* handler; Mask mask; int flags; }

extern (C) void fill(Mask* m) { m.bits = 0xFFFF_FFFF; }
void fillD(Mask* m) { m.bits = 0x1234; }
void setFlags(int* p, int v) { *p = v; }

void main()
{
    Action a = void;
    a.handler = null;
    fill(&a.mask);
    assert(a.mask.bits == 0xFFFF_FFFF);
    fillD(&a.mask);
    assert(a.mask.bits == 0x1234);
    setFlags(&a.flags, 0x44);
    assert(a.flags == 0x44);
}
