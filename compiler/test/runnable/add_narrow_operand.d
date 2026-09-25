/* REQUIRED_ARGS: -O
 */

// Adding a 32 bit value to a 64 bit one sign or zero extends it according
// to its type. Reduced from druntime's cpuid_initialization.

struct CacheInfo { size_t size; ubyte assoc; uint lineSize; }

__gshared CacheInfo[5] datacache;

void fill()
{
    for (size_t i = 1; i < datacache.length; ++i)
        if (datacache[i].size == 0)
            datacache[i].lineSize = datacache[i - 1].lineSize;
}

long addInt(long a, int b) { return a + b; }
long addUint(long a, uint b) { return a + b; }
long subInt(long a, int b) { return a - b; }
long intMinusLong(int a, long b) { return a - b; }

void main()
{
    datacache[0].lineSize = 64;
    datacache[2].size = 1;
    datacache[2].lineSize = 32;
    fill();
    assert(datacache[1].lineSize == 64);
    assert(datacache[3].lineSize == 32 && datacache[4].lineSize == 32);

    assert(addInt(10, -4) == 6);
    assert(addUint(10, uint.max) == 10 + 0xFFFF_FFFFL);
    assert(subInt(10, -4) == 14);
    assert(intMinusLong(-4, 10) == -14);
}
