// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* Allocating a scratch register while most registers hold register
 * variables. Also has float register variables.
 */

uint mix(const(uint)[] a, float f)
{
    uint v0 = 1, v1 = 2, v2 = 3, v3 = 4, v4 = 5, v5 = 6, v6 = 7, v7 = 8;
    uint v8 = 9, v9 = 10, v10 = 11, v11 = 12, v12 = 13, v13 = 14, v14 = 15, v15 = 16;
    uint v16 = 17, v17 = 18, v18 = 19, v19 = 20, v20 = 21, v21 = 22, v22 = 23, v23 = 24;
    float g = f, h = f * 2;
    foreach (i, x; a)
    {
        v0 += x;  v1 ^= v0; v2 += v1; v3 ^= v2; v4 += v3; v5 ^= v4; v6 += v5; v7 ^= v6;
        v8 += v7; v9 ^= v8; v10 += v9; v11 ^= v10; v12 += v11; v13 ^= v12; v14 += v13; v15 ^= v14;
        v16 += v15; v17 ^= v16; v18 += v17; v19 ^= v18; v20 += v19; v21 ^= v20; v22 += v21; v23 ^= v22;
        g += h;
        h *= 0.5f;
        bool b = !(x & 1);
        v0 += b;
        v1 += !(v2 & 2);
    }
    return v0 + v1 + v2 + v3 + v4 + v5 + v6 + v7 + v8 + v9 + v10 + v11 + v12 + v13 + v14 + v15
         + v16 + v17 + v18 + v19 + v20 + v21 + v22 + v23 + cast(uint) g;
}

uint mixRef(const(uint)[] a, float f)
{
    uint v0 = 1, v1 = 2, v2 = 3, v3 = 4, v4 = 5, v5 = 6, v6 = 7, v7 = 8;
    uint v8 = 9, v9 = 10, v10 = 11, v11 = 12, v12 = 13, v13 = 14, v14 = 15, v15 = 16;
    uint v16 = 17, v17 = 18, v18 = 19, v19 = 20, v20 = 21, v21 = 22, v22 = 23, v23 = 24;
    float g = f, h = f * 2;
    foreach (i, x; a)
    {
        v0 += x;  v1 ^= v0; v2 += v1; v3 ^= v2; v4 += v3; v5 ^= v4; v6 += v5; v7 ^= v6;
        v8 += v7; v9 ^= v8; v10 += v9; v11 ^= v10; v12 += v11; v13 ^= v12; v14 += v13; v15 ^= v14;
        v16 += v15; v17 ^= v16; v18 += v17; v19 ^= v18; v20 += v19; v21 ^= v20; v22 += v21; v23 ^= v22;
        g += h;
        h *= 0.5f;
        bool b = !(x & 1);
        v0 += b;
        v1 += !(v2 & 2);
    }
    return v0 + v1 + v2 + v3 + v4 + v5 + v6 + v7 + v8 + v9 + v10 + v11 + v12 + v13 + v14 + v15
         + v16 + v17 + v18 + v19 + v20 + v21 + v22 + v23 + cast(uint) g;
}

int main()
{
    uint[5] a = [3, 8, 1, 6, 9];
    assert(mix(a[], 1.5f) == mixRef(a[], 1.5f));
    return 0;
}
