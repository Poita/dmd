// REQUIRED_ARGS: -d
// Filling arrays of real, ireal and creal.

void main()
{
    auto c = new creal[3];
    c[] = 0.5 + 1.0i;
    foreach (x; c)
        assert(x == 0.5 + 1.0i);

    auto r = new real[3];
    r[] = 2.5;
    foreach (x; r)
        assert(x == 2.5);

    auto i = new ireal[2];
    i[] = 3.0i;
    foreach (x; i)
        assert(x == 3.0i);
}
