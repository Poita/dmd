// Shifting a 32 bit unsigned value right by 16 extracts its upper half without
// sign extension, also when the optimizer loads that half from memory.

uint get32bits(const(ubyte)* x)
{
    return ((cast(uint) x[3]) << 24) | ((cast(uint) x[2]) << 16) | ((cast(uint) x[1]) << 8) | (cast(uint) x[0]);
}

size_t murmur(const(ubyte)[] bytes, size_t seed)
{
    auto len = bytes.length;
    auto data = bytes.ptr;
    auto nblocks = len / 4;

    uint h1 = cast(uint) seed;

    enum uint c1 = 0xcc9e2d51;
    enum uint c2 = 0x1b873593;
    enum uint c3 = 0xe6546b64;

    auto end_data = data + nblocks * uint.sizeof;
    for (; data != end_data; data += uint.sizeof)
    {
        uint k1 = get32bits(data);
        k1 *= c1;
        k1 = (k1 << 15) | (k1 >> (32 - 15));
        k1 *= c2;

        h1 ^= k1;
        h1 = (h1 << 13) | (h1 >> (32 - 13));
        h1 = h1 * 5 + c3;
    }

    uint k1 = 0;
    switch (len & 3)
    {
        case 3: k1 ^= data[2] << 16; goto case;
        case 2: k1 ^= data[1] << 8;  goto case;
        case 1: k1 ^= data[0];
                k1 *= c1; k1 = (k1 << 15) | (k1 >> (32 - 15)); k1 *= c2; h1 ^= k1;
                goto default;
        default:
    }

    h1 ^= len;
    h1 = (h1 ^ (h1 >> 16)) * 0x85ebca6b;
    h1 = (h1 ^ (h1 >> 13)) * 0xc2b2ae35;
    h1 ^= h1 >> 16;
    return h1;
}

void main()
{
    const ubyte[9] a = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    assert(murmur(a[0 .. 1], 0) == 0xe45ad1ab);
    assert(murmur(a[0 .. 3], 0) == 0x80d1d204);
    assert(murmur(a[0 .. 5], 0) == 0xa291b9c8);
    assert(murmur(a[0 .. 9], 0) == 0xa198f0a8);
}
