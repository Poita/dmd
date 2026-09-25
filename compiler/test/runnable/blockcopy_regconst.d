// The loop copying a large struct increments its index register, so the
// register must not be remembered as still holding the constant 0.

struct Big { long[12] a; }

__gshared bool ok;

void check(Big* p, void* q, int z)
{
    ok = p !is null && q is null && z == 0 && p.a[11] == 11;
}

void copy(ref Big dst, ref Big src)
{
    dst = src;
    check(&dst, null, 0);
}

void main()
{
    Big src, dst;
    foreach (i, ref x; src.a)
        x = i;
    copy(dst, src);
    assert(ok);
}
