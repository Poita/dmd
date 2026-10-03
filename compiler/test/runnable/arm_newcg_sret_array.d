/* REQUIRED_ARGS: -O
 */
// A non-POD static array returned through the hidden result pointer

struct S
{
    static int postblit;
    int i;
    this(this) { ++postblit; }
}

S[3] make(ref S[3] src) { return src; }

void main()
{
    S[3] a;
    a[0].i = 1; a[1].i = 2; a[2].i = 3;
    S[3] b = make(a);
    if (!(b[0].i == 1 && b[1].i == 2 && b[2].i == 3)) assert(0);
    if (S.postblit != 3) assert(0);
}
