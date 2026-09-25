/* REQUIRED_ARGS: -inline
 * Twelve byte arguments of an inlined function next to a live four byte argument.
 */
struct WorldId { ushort index, generation; }
struct JointDef { void* user; long a, b; float[7] fa, fb; float motor = 0; int[20] flags; }
struct Vec3 { float x = 0, y = 0, z = 0; }
struct Body { long id; }

__gshared WorldId seen;
__gshared float seenMotor = 0;

pragma(inline, false) JointDef defaultJointDef() { JointDef d; d.fa[] = 0; d.fb[] = 0; d.motor = 2; return d; }
pragma(inline, false) int createJoint(WorldId w, const JointDef* d) { seen = w; seenMotor = d.motor + d.fa[2] + d.fb[2]; return w.index; }

int createJoint3(WorldId world, Body a, Body b, Vec3 anchor, Vec3 axis, bool collide = false)
{
    auto def = defaultJointDef();
    def.a = a.id;
    def.b = b.id;
    def.fa[2] = anchor.z + axis.z;
    def.fb[2] = anchor.x;
    return createJoint(world, &def);
}

struct World
{
    WorldId id;
    int joint(Body a, Body b, Vec3 anchor, Vec3 axis, bool collide = false)
        => createJoint3(id, a, b, anchor, axis, collide);
}

void main()
{
    auto w = World(WorldId(1, 31));
    w.joint(Body(1), Body(2), Vec3(0, 0, 0), Vec3(0, 0, 1));
    assert(seen == WorldId(1, 31) && seenMotor == 3);
    w.joint(Body(1), Body(2), Vec3(5, 0, 1), Vec3(0, 0, 1));
    assert(seen == WorldId(1, 31) && seenMotor == 9);
}
