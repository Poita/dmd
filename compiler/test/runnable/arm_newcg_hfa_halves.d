// REQUIRED_ARGS: -O -inline -release
// A 16 byte HFA copied as two 8 byte integers: each half is a plain 8 byte copy,
// not a copy of the whole HFA.

struct Quat { float x = 0, y = 0, z = 0, w = 1; }
struct Def { int kind; float[3] position; Quat rotation; long tail = 77; }

__gshared float result;

pragma(inline, false) void create(Def* d)
{
    result = d.rotation.w + d.rotation.z * 10 + d.rotation.y * 100 + d.rotation.x * 1000 + d.tail;
}

pragma(inline, false) float spawn(float px, float rz)
{
    Quat rotation;
    rotation.z = rz;
    Def def;
    def.kind = 2;
    def.position = [px, 0, 0];
    Quat q = rotation;
    def.rotation = q;
    create(&def);
    return result;
}

void main()
{
    if (!(spawn(1, 3) == 1 + 30 + 77)) assert(0);
}
