// Constants loaded into registers, some of which are AArch64 bitmask immediates.

pragma(inline, false) ulong k1() { return 0x5555_5555_5555_5555; }
pragma(inline, false) ulong k2() { return 0x00FF_00FF_00FF_00FF; }
pragma(inline, false) ulong k3() { return 0xFFFF_0000_FFFF_0000; }
pragma(inline, false) ulong k4() { return 0x7FFF_FFFF_FFFF_FFF0; }
pragma(inline, false) uint  k5() { return 0x0F0F_0F0F; }
pragma(inline, false) uint  k6() { return 0xFFF0_0FFF; }
pragma(inline, false) ulong k7() { return 0x1234_5678_9ABC_DEF0; }
pragma(inline, false) uint  k8() { return 0x8000_0001; }
pragma(inline, false) int   k9() { return 0x3333_3333; }
pragma(inline, false) ulong k10() { return 0x6161_6161_6161_6161; }   // not a bitmask immediate
pragma(inline, false) uint  k11() { return 0x6161_6161; }
pragma(inline, false) ulong k12() { return 0x0000_0000_8000_0000; }

void main()
{
    ulong one = 1;      // runtime values the optimizer can't fold into the checks
    assert(k1() == (0xAAAA_AAAA_AAAA_AAAA >> one));
    assert(k2() == 0x00FF_00FF_00FF_00FF * one);
    assert(k3() == 0xFFFF_0000_FFFF_0000 * one);
    assert(k4() == 0x7FFF_FFFF_FFFF_FFF0 * one);
    assert(k5() == 0x0F0F_0F0F * cast(uint) one);
    assert(k6() == 0xFFF0_0FFF * cast(uint) one);
    assert(k7() == 0x1234_5678_9ABC_DEF0 * one);
    assert(k8() == 0x8000_0001 * cast(uint) one);
    assert(k9() == 0x3333_3333 * cast(int) one);
    // byte by byte, as the expected constant would load the same way
    const v10 = k10();
    foreach (i; 0 .. 8)
        assert(((v10 >> (i * 8)) & 0xFF) == 0x61);
    const v11 = k11();
    foreach (i; 0 .. 4)
        assert(((v11 >> (i * 8)) & 0xFF) == 0x61);
    assert(k12() == 0x8000_0000 * one);
}
