/* REQUIRED_ARGS: -g
 */
// Unwinding through a frame that saves callee-saved floating point registers.
struct Vec3 { float x = 0, y = 0, z = 0; }

struct Debris
{
    int calls;
    float total = 0;

    void spawn(Vec3 pos, Vec3 back, float speed, float rate, float halfWidth,
            float dt, float now, Vec3 eye)
    {
        total += pos.y + back.z + speed + rate + halfWidth + dt + now + eye.y;
        if (++calls == 3)
            throw new Exception("stop");
    }
}

void run(ref Debris d)
{
    foreach (i; 0 .. 100)
        d.spawn(Vec3(0, 2, 0), Vec3(0, 0, -1), 4, 4, 3, 0.1f, 0.1f * i, Vec3(0, 10, 0));
}

void main()
{
    Debris d;
    bool caught;
    try
        run(d);
    catch (Exception e)
        caught = e.msg == "stop";
    assert(caught && d.calls == 3);
}
