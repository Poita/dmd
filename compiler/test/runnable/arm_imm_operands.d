// Integer arithmetic and shifts with constant operands, which AArch64 can
// encode as immediates.

int addi(int x) { return x + 5; }
int subi(int x) { return x - 1; }
int addneg(int x) { return x + -7; }
long addl(long x) { return x + 4095; }
long addshifted(long x) { return x + 0x5000; }
long addbig(long x) { return x + 0x12345; }
uint addu(uint x) { return x + 0xFFFF_FFFF; }
bool addzero(int x) { return (x + 5) == 0; }

int shl(int x) { return x << 3; }
uint shru(uint x) { return x >> 5; }
int sar(int x) { return x >> 5; }
long shll(long x) { return x << 40; }
ulong shrul(ulong x) { return x >> 63; }
long sarl(long x) { return x >> 33; }
uint rol(uint x) { return (x << 7) | (x >> 25); }

void main()
{
    assert(addi(10) == 15);
    assert(subi(0) == -1);
    assert(addneg(3) == -4);
    assert(addl(1) == 4096);
    assert(addshifted(1) == 0x5001);
    assert(addbig(1) == 0x12346);
    assert(addu(1) == 0);
    assert(addzero(-5));
    assert(!addzero(5));

    assert(shl(-3) == -24);
    assert(shru(0x8000_0000) == 0x0400_0000);
    assert(sar(-64) == -2);
    assert(shll(3) == 3L << 40);
    assert(shrul(0x8000_0000_0000_0000) == 1);
    assert(sarl(-(1L << 40)) == -128);
    assert(rol(0x8000_0001) == 0x0000_00C0);
}
