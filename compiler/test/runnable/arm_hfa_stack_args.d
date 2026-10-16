/* REQUIRED_ARGS: -O
 */
// Aggregates of floats that do not fit in the vector registers left are passed on the
// stack, and the function called reads each where its caller put it, also when the
// optimizer splits one into halves

struct Vec3 { float x, y, z; }
struct Quat { float x, y, z, w; }

__gshared float[16] got;
__gshared uint gotHandle;

pragma(inline, false) void take(Vec3 pos, Quat rot, Vec3 ext, Vec3 lin, Vec3 ang, uint handle)
{
    got = [pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w, ext.x, ext.y, ext.z,
        lin.x, lin.y, lin.z, ang.x, ang.y, ang.z];
    gotHandle = handle;
}

struct World
{
    bool created = true;

    // a member function with a contract
    pragma(inline, false) void take(Vec3 pos, Quat rot, Vec3 ext, Vec3 lin, Vec3 ang, uint handle)
    in (created)
    {
        .take(pos, rot, ext, lin, ang, handle);
    }
}

extern (C) pragma(inline, false) void takeC(Vec3 pos, Quat rot, Vec3 ext, Vec3 lin, Vec3 ang, uint handle)
{
    take(pos, rot, ext, lin, ang, handle);
}

// another library's types of the same layout, converted to as one would
struct BV { float x = 0, y = 0, z = 0; }
struct BQ { BV v; float s = 1; }
pragma(inline, true) BV toB(Vec3 v) { return BV(v.x, v.y, v.z); }
pragma(inline, true) BQ toB(Quat q) { return BQ(BV(q.x, q.y, q.z), q.w); }

struct Def { int type; BV position; BQ rotation; }
__gshared Def lastDef;
pragma(inline, false) void create(const Def* d) { lastDef = *d; }

// rot is read as two halves, so the optimizer splits it in two, which stay where
// the caller put them
pragma(inline, false) void place(Vec3 pos, Quat rot, Vec3 ext, Vec3 lin, Vec3 ang, uint handle)
{
    Def d;
    d.type = handle;
    d.position = toB(pos);
    d.rotation = toB(rot);
    create(&d);
}

void main()
{
    float[16] want = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    take(Vec3(1, 2, 3), Quat(4, 5, 6, 7), Vec3(8, 9, 10), Vec3(11, 12, 13), Vec3(14, 15, 16), 42);
    assert(got == want && gotHandle == 42);

    got[] = 0;
    World w;
    w.take(Vec3(1, 2, 3), Quat(4, 5, 6, 7), Vec3(8, 9, 10), Vec3(11, 12, 13), Vec3(14, 15, 16), 44);
    assert(got == want && gotHandle == 44);

    got[] = 0;
    takeC(Vec3(1, 2, 3), Quat(4, 5, 6, 7), Vec3(8, 9, 10), Vec3(11, 12, 13), Vec3(14, 15, 16), 43);
    assert(got == want && gotHandle == 43);

    place(Vec3(1, 2, 3), Quat(4, 5, 6, 7), Vec3(8, 9, 10), Vec3(11, 12, 13), Vec3(14, 15, 16), 45);
    assert(lastDef.type == 45);
    assert(lastDef.position == BV(1, 2, 3));
    assert(lastDef.rotation == BQ(BV(4, 5, 6), 7));
}
