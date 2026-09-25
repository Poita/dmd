// Widening a computed short sign extends its 16 bits.

int widen(int a, int b) { return cast(short)(a + b); }
uint uwiden(int a, int b) { return cast(ushort)(a + b); }

void main()
{
    assert(widen(0x7FFF, 1) == -0x8000);
    assert(widen(0x1_0000, 5) == 5);
    assert(uwiden(0xFFFF, 1) == 0 && uwiden(0x1_2345, 0) == 0x2345);
}
