// REQUIRED_ARGS: -cov
// PERMUTE_ARGS: -O -inline -release

// An aggregate returned from a call, which coverage counts before the call

struct S3 { float x, y, z; }

pragma(inline, false) float[3] arr(float a) { return [a, a * 2, a * 3]; }
pragma(inline, false) float[3] fwdArr(float a) { return arr(a + 1); }

pragma(inline, false) S3 s3(float a) { return S3(a, a + 1, a + 2); }
pragma(inline, false) S3 fwdS3(float a) { return s3(a * 2); }

void main()
{
    const a = fwdArr(1);
    assert(a[0] == 2 && a[1] == 4 && a[2] == 6);
    const s = fwdS3(1);
    assert(s.x == 2 && s.y == 3 && s.z == 4);
}
