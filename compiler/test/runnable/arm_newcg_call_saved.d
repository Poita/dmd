/* REQUIRED_ARGS: -O
 */
// More values live across a call than callee saved registers: some are kept in caller saved
// registers and saved around the call
__gshared int calls;
pragma(inline, false) int rare(int x) { ++calls; return x * 3; }
long f(int n, float x)
{
    int a0 = 1;
    int a1 = 2;
    int a2 = 3;
    int a3 = 4;
    int a4 = 5;
    int a5 = 6;
    int a6 = 7;
    int a7 = 8;
    int a8 = 9;
    int a9 = 10;
    int a10 = 11;
    int a11 = 12;
    int a12 = 13;
    int a13 = 14;
    float b0 = 0.5f;
    float b1 = 1.5f;
    float b2 = 2.5f;
    float b3 = 3.5f;
    float b4 = 4.5f;
    float b5 = 5.5f;
    float b6 = 6.5f;
    float b7 = 7.5f;
    float b8 = 8.5f;
    float b9 = 9.5f;
    float b10 = 10.5f;
    float b11 = 11.5f;
    foreach (k; 0 .. n)
    {
        a0 = a0 * 3 + k;
        a1 = a1 * 5 + k;
        a2 = a2 * 7 + k;
        a3 = a3 * 9 + k;
        a4 = a4 * 11 + k;
        a5 = a5 * 13 + k;
        a6 = a6 * 15 + k;
        a7 = a7 * 17 + k;
        a8 = a8 * 19 + k;
        a9 = a9 * 21 + k;
        a10 = a10 * 23 + k;
        a11 = a11 * 25 + k;
        a12 = a12 * 27 + k;
        a13 = a13 * 29 + k;
        b0 = b0 * 0.5f + x;
        b1 = b1 * 0.5f + x;
        b2 = b2 * 0.5f + x;
        b3 = b3 * 0.5f + x;
        b4 = b4 * 0.5f + x;
        b5 = b5 * 0.5f + x;
        b6 = b6 * 0.5f + x;
        b7 = b7 * 0.5f + x;
        b8 = b8 * 0.5f + x;
        b9 = b9 * 0.5f + x;
        b10 = b10 * 0.5f + x;
        b11 = b11 * 0.5f + x;
        if (k % 7 == 3)
            a0 += rare(a1 + a13);
    }
    long r = 0;
    r = r * 3 + a0;
    r = r * 3 + a1;
    r = r * 3 + a2;
    r = r * 3 + a3;
    r = r * 3 + a4;
    r = r * 3 + a5;
    r = r * 3 + a6;
    r = r * 3 + a7;
    r = r * 3 + a8;
    r = r * 3 + a9;
    r = r * 3 + a10;
    r = r * 3 + a11;
    r = r * 3 + a12;
    r = r * 3 + a13;
    r = r * 3 + cast(long)(b0 * 16);
    r = r * 3 + cast(long)(b1 * 16);
    r = r * 3 + cast(long)(b2 * 16);
    r = r * 3 + cast(long)(b3 * 16);
    r = r * 3 + cast(long)(b4 * 16);
    r = r * 3 + cast(long)(b5 * 16);
    r = r * 3 + cast(long)(b6 * 16);
    r = r * 3 + cast(long)(b7 * 16);
    r = r * 3 + cast(long)(b8 * 16);
    r = r * 3 + cast(long)(b9 * 16);
    r = r * 3 + cast(long)(b10 * 16);
    r = r * 3 + cast(long)(b11 * 16);
    return r;
}
void main()
{
    if (f(20, 1.5f) != 5610009479234758296L || calls != 3) assert(0);
}
