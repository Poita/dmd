// The absolute values of integers of each size.
module int_abs;

int absInt(int x) { return x < 0 ? -x : x; }
long absLong(long x) { return x >= 0 ? x : -x; }
int absShort(short x) { return x < 0 ? -x : x; }
int absByte(byte x) { return x < 0 ? -x : x; }

int main()
{
    if (absInt(-5) != 5 || absInt(7) != 7 || absInt(0) != 0 || absInt(int.min) != int.min)
        assert(0);
    if (absLong(-5_000_000_000) != 5_000_000_000 || absLong(3) != 3 || absLong(long.min) != long.min)
        assert(0);
    if (absShort(-300) != 300 || absShort(short.min) != 32768 || absShort(12) != 12)
        assert(0);
    if (absByte(-100) != 100 || absByte(byte.min) != 128 || absByte(5) != 5)
        assert(0);
    return 0;
}
