/* REQUIRED_ARGS: -O -inline
 */
// Function literals declaring structs, every call of them inlined: what is
// generated for their structs is still there for the inlined code and the
// template instances of the structs to refer to

void assertCTFEable(alias dg)()
{
    static assert({ cast(void) dg(); return true; }());
    cast(void) dg();
}

import core.lifetime : move;

void main()
{
    assertCTFEable!((){
        static struct S1 { int a = 1, b = 2; }
        S1 s11 = { 10, 11 };
        S1 s12;
        move(s11, s12);
        assert(s11.a == 10 && s12.b == 11);
    });

    int n;
    auto f = () {
        struct Local { int v = 5; int twice() { return v * 2; } }
        Local l;
        return l.twice() + n;
    };
    assert(f() == 10);
}
