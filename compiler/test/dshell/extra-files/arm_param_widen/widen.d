// A ushort parameter that begin() reads from the register it was passed in, after
// inlining, is zero-extended by its own size (it was masked to a byte: 810 became 42).
pragma(inline, false) float tan(float x) { return x + x * x * x / 3; }
struct Vec2 { float x, y; }
struct Mat4
{
    float[16] m;
    static Mat4 perspective(float fovYRadians, float aspect, float near, float far, bool homogeneousDepth)
    {
        const f = 1 / tan(fovYRadians * 0.5f);
        Mat4 r;
        r.m[0] = f / aspect;
        return r;
    }
}
struct Camera3D
{
    float fovYRadians = 1.0f;
    float near = 0.5f;
    float far = 1000;
    Vec2 jitter;
    Mat4 projection(float viewportW, float viewportH, bool homogeneousDepth) const
    {
        auto p = projectionNoJitter(viewportW, viewportH, homogeneousDepth);
        return p;
    }
    Mat4 projectionNoJitter(float viewportW, float viewportH, bool homogeneousDepth) const
    {
        const aspect = viewportH > 0 ? viewportW / viewportH : 1;
        return Mat4.perspective(fovYRadians, aspect, near, far, homogeneousDepth);
    }
}
Vec2 taaJitter(long frame, uint w, uint h) { return Vec2(0.5f / w, -0.5f / h); }
Vec2 scaled(Vec2 v, float k) { return Vec2(v.x * k, v.y * k); }
class Pipeline
{
    ushort width, height, nativeWidth, nativeHeight;
    bool homogeneousDepth_, metalFxActive_, taaOn = true;
    float aspect_;
    long frameIndex = 3;
    Mat4 proj_;
    void begin(ref Camera3D cam, ushort w, ushort h, ushort nativeW, ushort nativeH, bool homogeneousDepth)
    {
        height = h;
        cam.jitter = metalFxActive_ ? scaled(taaJitter(frameIndex, w, h), 2) : taaOn ? taaJitter(frameIndex, w, h) : Vec2(0, 0);
        proj_ = cam.projection(w, h, homogeneousDepth);
    }
}
void main()
{
    Camera3D c;
    auto p = new Pipeline;
    p.begin(c, 1440, 810, 2880, 1620, false);
    if (p.height != 810)
        assert(0);
}
