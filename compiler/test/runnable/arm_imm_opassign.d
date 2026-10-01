// Adding and subtracting constants in place, which AArch64 can encode as
// immediates.

int counter(int n) { int c; foreach (i; 0 .. n) c += 3; return c; }
long down(long x) { x -= 4096; x += -5; x -= -7; return x; }
uint wrap(uint x) { x += 0xFFFF_FFFF; return x; }
void bump(int* p) { *p += 100; p[1] -= 1; }
bool hitsZero(int x) { x -= 5; return x == 0; }
ulong big(ulong x) { x += 0x12345; return x; }

void main()
{
    assert(counter(10) == 30);
    assert(down(10) == 10 - 4096 - 5 + 7);
    assert(wrap(5) == 4);
    int[2] a = [1, 2];
    bump(a.ptr);
    assert(a[0] == 101 && a[1] == 1);
    assert(hitsZero(5) && !hitsZero(6));
    assert(big(1) == 0x12346);
}
