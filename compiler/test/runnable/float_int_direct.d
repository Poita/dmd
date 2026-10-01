// Conversions between float and integers, which AArch64 can do directly
// without going through double.

int ftoi(float x) { return cast(int) x; }
uint ftou(float x) { return cast(uint) x; }
long ftol(float x) { return cast(long) x; }
short ftos(float x) { return cast(short) x; }
float itof(int i) { return cast(float) i; }
float utof(uint i) { return cast(float) i; }
float stof(short i) { return cast(float) i; }
float ltof(long i) { return cast(float) i; }

int floorish(float x)
{
    const i = cast(int) x;
    return x < i ? i - 1 : i;
}

void main()
{
    assert(ftoi(2.75f) == 2);
    assert(ftoi(-2.75f) == -2);
    assert(ftou(3e9f) == 3_000_000_000u);
    assert(ftol(-1_099_511_627_776.0f) == -1_099_511_627_776L);
    assert(ftos(-300.5f) == -300);
    assert(itof(16_777_217) == 16_777_216.0f);
    assert(itof(-7) == -7.0f);
    assert(utof(4_294_967_295u) == 4_294_967_296.0f);
    assert(stof(-32768) == -32768.0f);
    assert(ltof(1L << 40) == 1_099_511_627_776.0f);
    assert(floorish(-0.5f) == -1);
    assert(floorish(3.0f) == 3);
}
