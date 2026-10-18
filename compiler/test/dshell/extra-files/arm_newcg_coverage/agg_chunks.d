// Small aggregates of sizes that are not powers of 2, passed and returned in
// integer registers, loaded and stored as pieces of 4, 2 and 1 bytes.
module agg_chunks;

struct B3 { ubyte r, g, b; }
struct B5 { ubyte[5] a; }
struct S6 { short a, b, c; }
struct B7 { ubyte[7] a; }
struct B11 { ubyte[11] a; }
struct S14 { short[7] a; }
struct B15 { ubyte[15] a; }

pragma(inline, false) int calleeB3(B3 x) { return x.r + 2 * x.g + 3 * x.b; }
pragma(inline, false) int calleeB5(B5 x) { int s; foreach (i, v; x.a) s += cast(int)(i + 1) * v; return s; }
pragma(inline, false) int calleeS6(S6 x) { return x.a + 2 * x.b + 3 * x.c; }
pragma(inline, false) int calleeB7(B7 x) { int s; foreach (i, v; x.a) s += cast(int)(i + 1) * v; return s; }
pragma(inline, false) int calleeB11(B11 x) { int s; foreach (i, v; x.a) s += cast(int)(i + 1) * v; return s; }
pragma(inline, false) int calleeS14(S14 x) { int s; foreach (i, v; x.a) s += cast(int)(i + 1) * v; return s; }
pragma(inline, false) int calleeB15(B15 x) { int s; foreach (i, v; x.a) s += cast(int)(i + 1) * v; return s; }

pragma(inline, false) B3 calleeMake3(ubyte k) { return B3(k, cast(ubyte)(k + 1), cast(ubyte)(k + 2)); }

int pass(const(B3)* b3, const(B5)* b5, const(S6)* s6, const(B7)* b7, const(B11)* b11, const(S14)* s14,
    const(B15)* b15)
{
    return calleeB3(*b3) + calleeB5(*b5) + calleeS6(*s6) + calleeB7(*b7) + calleeB11(*b11) +
        calleeS14(*s14) + calleeB15(*b15);
}

B3 load3(const(B3)[] a, size_t i) { return a[i]; }
S6 load6(const(S6)[] a, size_t i) { return a[i]; }
B7 load7(const(B7)* p) { return *p; }
B11 load11(const(B11)* p) { return *p; }
void store3(B3[] a, size_t i, ubyte k) { a[i] = calleeMake3(k); }
void copy7(B7* d, const(B7)* s) { *d = *s; }

int main()
{
    B3 b3 = B3(1, 2, 3);
    B5 b5;
    B7 b7;
    B11 b11;
    B15 b15;
    S14 s14;
    foreach (i, ref v; b5.a) v = cast(ubyte)(i + 10);
    foreach (i, ref v; b7.a) v = cast(ubyte)(i + 20);
    foreach (i, ref v; b11.a) v = cast(ubyte)(i + 30);
    foreach (i, ref v; b15.a) v = cast(ubyte)(i + 40);
    foreach (i, ref v; s14.a) v = cast(short)(i * 1000 - 3000);
    S6 s6 = S6(-1, 300, -30000);
    int want = calleeB3(b3) + calleeB5(b5) + calleeS6(s6) + calleeB7(b7) + calleeB11(b11) + calleeS14(s14) +
        calleeB15(b15);
    assert(want == (1 + 4 + 9) + (10 + 22 + 36 + 52 + 70) + (-1 + 600 - 90000) +
        (20 + 42 + 66 + 92 + 120 + 150 + 182) + calleeB11(b11) + calleeS14(s14) + calleeB15(b15));
    assert(pass(&b3, &b5, &s6, &b7, &b11, &s14, &b15) == want);

    B3[3] a3 = [B3(1, 2, 3), B3(4, 5, 6), B3(7, 8, 9)];
    assert(load3(a3[], 1) == B3(4, 5, 6));
    store3(a3[], 2, 50);
    assert(a3[2] == B3(50, 51, 52) && a3[1] == B3(4, 5, 6));
    S6[2] a6 = [S6(1, 2, 3), s6];
    assert(load6(a6[], 1) == s6);
    assert(load7(&b7) == b7);
    assert(load11(&b11) == b11);
    B7[2] d7;
    d7[1].a[] = 0xEE;
    copy7(&d7[0], &b7);
    assert(d7[0] == b7 && d7[1].a[0] == 0xEE);
    return 0;
}
