pragma(inline, false) void touch(int v) { __gshared int s; s += v; }

pragma(inline, false) int keepParams(int a, int b)
{
    touch(1);
    return a * b + a;
}

pragma(inline, false) int spills(int n)
{
    int v0 = n + 1, v1 = n * 3, v2 = n ^ 5, v3 = n - 7, v4 = n * n, v5 = n + 11;
    int v6 = n * 13, v7 = n ^ 17, v8 = n - 19, v9 = n * 23, v10 = n + 29, v11 = n * 31;
    int v12 = n ^ 37, v13 = n - 41;
    touch(n);
    return v0 + v1 * v2 - v3 + v4 * v5 - v6 + v7 * v8 - v9 + v10 * v11 - v12 + v13 + n;
}

void main()
{
    keepParams(3, 4);
    spills(5);
}
