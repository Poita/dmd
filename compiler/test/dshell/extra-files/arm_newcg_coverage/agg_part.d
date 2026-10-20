// A small struct field of a struct held in a register passed on by value.
module agg_part;

struct Tex { ushort idx; }
struct Fb { ushort idx; }
struct Target { Fb fb; Tex tex; ushort w, h; }

__gshared int seen;

pragma(inline, false)
void setTexture(int stage, Tex t, uint flags) { seen = stage * 100000 + t.idx * 10 + flags; }

pragma(inline, false)
Target make(ushort k) { return Target(Fb(k), Tex(cast(ushort)(k + 1)), 64, 32); }

void run(ushort k)
{
    const coarser = make(k);
    setTexture(3, coarser.tex, coarser.w > 10 ? 1 : 0);
}

int main()
{
    run(7);
    if (seen != 300081)
        assert(0);
    return 0;
}
