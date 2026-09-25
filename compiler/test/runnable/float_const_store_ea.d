// A floating point constant stored through a pointer held in a general register.
struct Field { int size = 4; bool valid = true; ulong steps; float[] data; }

void sample(const ref Field f, float[] vals, out float groundMin, out float groundMax)
{
    groundMin = float.max;
    groundMax = -float.max;
    foreach (j; 0 .. f.size)
        foreach (i; 0 .. f.size)
        {
            const g = f.data[j * f.size + i];
            if (g < groundMin)
                groundMin = g;
            if (g > groundMax)
                groundMax = g;
            vals[(j * f.size + i) * 4] = g;
        }
}

struct Tex
{
    int size;
    float[] current, target;
    float groundMin = 0, groundMax = 0;
    ulong sampledSteps;
    bool settled;

    void update(const ref Field f)
    {
        if (!f.valid)
            return;
        if (size != f.size)
        {
            size = f.size;
            const n = size_t(size) * size * 4;
            current = new float[](n);
            target = new float[](n);
            sample(f, target, groundMin, groundMax);
            sampledSteps = f.steps;
            current[] = target[];
            settled = false;
        }
        if (sampledSteps != f.steps)
        {
            sampledSteps = f.steps;
            sample(f, target, groundMin, groundMax);
            settled = false;
        }
    }
}

void main()
{
    Field f;
    f.data = [3, -2, 5, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0];
    auto t = new Tex;
    t.update(f);
    assert(t.groundMin == -2 && t.groundMax == 7);
    f.steps = 1;
    f.data[5] = 9;
    t.update(f);
    assert(t.groundMin == -2 && t.groundMax == 9);
}
