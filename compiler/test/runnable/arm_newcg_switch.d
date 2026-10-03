// REQUIRED_ARGS: -O -release
// Switches as comparisons: few and many cases, signed, unsigned and narrow values.

pragma(inline, false) int few(int x)
{
    switch (x)
    {
        case 1: return 10;
        case 5: return 50;
        case -3: return -30;
        default: return 0;
    }
}

pragma(inline, false) int many(uint x)
{
    switch (x)
    {
        case 0: return 100;
        case 3: return 103;
        case 7: return 107;
        case 12: return 112;
        case 100: return 200;
        case 4000: return 4100;
        case 70000: return 70100;
        case 0x8000_0000: return 1;
        case 0xFFFF_FFFF: return 2;
        default: return -1;
    }
}

pragma(inline, false) long signedMany(long x)
{
    switch (x)
    {
        case -100000: return 1;
        case -5: return 2;
        case -1: return 3;
        case 0: return 4;
        case 9: return 5;
        case 4096: return 6;
        case 1L << 40: return 7;
        default: return 0;
    }
}

pragma(inline, false) int narrow(byte x)
{
    switch (x)
    {
        case -128: return 1;
        case -1: return 2;
        case 0: return 3;
        case 127: return 4;
        case 50: return 5;
        default: return 0;
    }
}

void main()
{
    if (!(few(1) == 10 && few(5) == 50 && few(-3) == -30 && few(2) == 0)) assert(0);
    foreach (v, r; [0u: 100, 3: 103, 7: 107, 12: 112, 100: 200, 4000: 4100, 70000: 70100,
                    0x8000_0000: 1, 0xFFFF_FFFF: 2, 1: -1, 99: -1, 0x7FFF_FFFF: -1])
        if (many(v) != r) assert(0);
    foreach (v, r; [-100000L: 1L, -5: 2, -1: 3, 0: 4, 9: 5, 4096: 6, 1L << 40: 7, 8: 0, -2: 0, long.min: 0])
        if (signedMany(v) != r) assert(0);
    if (!(narrow(-128) == 1 && narrow(-1) == 2 && narrow(0) == 3 && narrow(127) == 4 &&
          narrow(50) == 5 && narrow(1) == 0)) assert(0);
}
