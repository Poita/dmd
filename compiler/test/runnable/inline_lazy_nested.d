/* REQUIRED_ARGS: -O -inline
 */
// Nested functions given as lazy arguments that the inlined callee never
// evaluates: the delegates made for them are still generated, and so are they

A select(bool cond : true, A, B)(A a, lazy B b) { return a; }
B select(bool cond : false, A, B)(lazy A a, B b) { return b; }

void main()
{
    real run() { return 0; }
    int fail() { assert(0); }
    auto a = select!true(run(), fail());
    auto b = select!false(fail(), run());
    assert(a == 0 && b == 0);
}
