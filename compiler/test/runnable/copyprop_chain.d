// Copy propagation through chains of copies, copies that become self-copies,
// and assignments that become copies, under -O.

int chain(int b)
{
    int a = b;
    int c = a;
    int d = c;
    int e = d;
    int f = e;
    return f + a * 2;
}

int selfCopy(int p, int q)
{
    int a = p;
    int b = a;
    a = b;          // becomes a = a
    b = q;
    return a * 10 + b;
}

int newCopy(int p, int q)
{
    int x = p;
    int y = x;
    x = x;          // becomes x = p
    int z = y;
    if (q > 0)
        x = q;
    return x * 100 + y * 10 + z;
}

long manyArgs(long a0, long a1, long a2, long a3, long a4, long a5, long a6, long a7,
    uint i)
{
    long v0 = a0, v1 = a1, v2 = a2, v3 = a3, v4 = a4, v5 = a5, v6 = a6, v7 = a7;
    long w0 = v0, w1 = v1, w2 = v2, w3 = v3, w4 = v4, w5 = v5, w6 = v6, w7 = v7;
    switch (i)
    {
        case 0: return w0;
        case 1: return w1;
        case 2: return w2;
        case 3: return w3;
        case 4: return w4;
        case 5: return w5;
        case 6: return w6;
        default: return w7;
    }
}

void main()
{
    assert(chain(3) == 9);
    assert(selfCopy(4, 5) == 45);
    assert(newCopy(7, 0) == 777);
    assert(newCopy(7, 2) == 277);
    foreach (uint i; 0 .. 8)
        assert(manyArgs(10, 11, 12, 13, 14, 15, 16, 17, i) == 10 + i);
}
