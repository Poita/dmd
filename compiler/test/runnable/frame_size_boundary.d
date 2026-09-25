// Functions with frames around the reach of a paired load/store immediate
// restore the stack pointer and return address correctly.

int useFrame(size_t N)(int x)
{
    ubyte[N] buf = void;
    foreach (i, ref b; buf)
        b = cast(ubyte)(i + x);
    int sum;
    foreach (b; buf)
        sum += b;
    return sum;
}

void main()
{
    static foreach (N; [440, 456, 472, 480, 488, 496, 504, 512, 520, 536, 560])
    {{
        int expected;
        foreach (i; 0 .. N)
            expected += cast(ubyte)(i + 1);
        assert(useFrame!N(1) == expected);
    }}
}
