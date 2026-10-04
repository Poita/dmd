/* REQUIRED_ARGS: -O -inline -release
 * PERMUTE_ARGS:
 */
// Functions given function literals as delegates inlined, and the literals into them

float total(float[] cells, float k)
{
    void forCells(int n, scope void delegate(size_t idx, float d) f)
    {
        foreach (i; 0 .. n)
            f(i, i * 0.5f);
    }
    void tail(float r)
    {
        forCells(cast(int)cells.length, (idx, d) {
            const w = d * r + k;
            if (w > cells[idx])
                cells[idx] = w;
        });
    }
    tail(2.0f);
    tail(3.0f);
    float s = 0;
    foreach (c; cells)
        s += c;
    return s;
}

int reassigned(int x)
{
    int apply(int delegate(int) f, int v)
    {
        auto r = f(v);
        f = (int y) => y * 100;     // the parameter changes
        return r + f(v);
    }
    return apply((int y) => y + x, 2);
}

int delegate(int) saved;
int stores(int x)
{
    void keep(int delegate(int) f) { saved = f; }   // the delegate escapes
    keep((int y) => y + x);
    return saved(5);
}

int counts(int n)
{
    int calls;
    void each(scope void delegate() f) { foreach (_; 0 .. n) f(); }
    each(() { ++calls; });
    return calls;
}

float earlyReturns(float[] cells, float k)
{
    void forCells(int n, scope void delegate(size_t idx, float d) f)
    {
        foreach (i; 0 .. n)
            f(i, i * 0.5f);
    }
    int skipped;
    void tail(float r)
    {
        forCells(cast(int)cells.length, (idx, d) {
            const t = d * r;
            if (t <= 0.0f || t >= 6.0f)
            {
                ++skipped;
                return;
            }
            const w = t + k;
            if (w > cells[idx])
                cells[idx] = w;
        });
    }
    tail(2.0f);
    tail(3.0f);
    float s = skipped * 1000;
    foreach (c; cells)
        s += c;
    return s;
}

int twoReturns(int n)
{
    int t;
    void each(scope void delegate(int) f) { foreach (i; 0 .. n) f(i); }
    each((i) {
        if (i == 1)
            return;
        t += i;
        if (i == 3)
            return;
        t += 100;
    });
    return t;
}

struct Field
{
    float[] v;
    uint n;
}

Field makeField(uint n, float step, scope float delegate(float x, float y) f)
{
    Field c;
    c.n = n;
    c.v = new float[](size_t(n) * n);
    foreach (y; 0 .. n)
        foreach (x; 0 .. n)
            c.v[size_t(y) * n + x] = f(x * step, y * step);
    return c;
}

float fields(float k)
{
    const a = makeField(3, 0.5f, (x, y) => x + y * k);
    const b = makeField(2, 1.0f, (x, y) { return x > y ? x : y + k; });
    float s = 0;
    foreach (v; a.v)
        s += v;
    foreach (v; b.v)
        s += v * 10;
    return s;
}

float longFields(float k)
{
    /* A caller long enough that only calls given literals are inlined as statements:
     * filler line 0
     * filler line 1
     * filler line 2
     * filler line 3
     * filler line 4
     * filler line 5
     * filler line 6
     * filler line 7
     * filler line 8
     * filler line 9
     * filler line 10
     * filler line 11
     * filler line 12
     * filler line 13
     * filler line 14
     * filler line 15
     * filler line 16
     * filler line 17
     * filler line 18
     * filler line 19
     * filler line 20
     * filler line 21
     * filler line 22
     * filler line 23
     * filler line 24
     * filler line 25
     * filler line 26
     * filler line 27
     * filler line 28
     * filler line 29
     * filler line 30
     * filler line 31
     * filler line 32
     * filler line 33
     * filler line 34
     * filler line 35
     * filler line 36
     * filler line 37
     * filler line 38
     * filler line 39
     * filler line 40
     * filler line 41
     * filler line 42
     * filler line 43
     * filler line 44
     * filler line 45
     * filler line 46
     * filler line 47
     * filler line 48
     * filler line 49
     * filler line 50
     * filler line 51
     * filler line 52
     * filler line 53
     * filler line 54
     * filler line 55
     * filler line 56
     * filler line 57
     * filler line 58
     * filler line 59
     * filler line 60
     * filler line 61
     * filler line 62
     * filler line 63
     * filler line 64
     * filler line 65
     * filler line 66
     * filler line 67
     * filler line 68
     * filler line 69
     * filler line 70
     * filler line 71
     * filler line 72
     * filler line 73
     * filler line 74
     * filler line 75
     * filler line 76
     * filler line 77
     * filler line 78
     * filler line 79
     * filler line 80
     * filler line 81
     * filler line 82
     * filler line 83
     * filler line 84
     * filler line 85
     * filler line 86
     * filler line 87
     * filler line 88
     * filler line 89
     * filler line 90
     * filler line 91
     * filler line 92
     * filler line 93
     * filler line 94
     * filler line 95
     * filler line 96
     * filler line 97
     * filler line 98
     * filler line 99
     * filler line 100
     * filler line 101
     * filler line 102
     * filler line 103
     * filler line 104
     * filler line 105
     * filler line 106
     * filler line 107
     * filler line 108
     * filler line 109
     * filler line 110
     * filler line 111
     * filler line 112
     * filler line 113
     * filler line 114
     * filler line 115
     * filler line 116
     * filler line 117
     * filler line 118
     * filler line 119
     * filler line 120
     * filler line 121
     * filler line 122
     * filler line 123
     * filler line 124
     * filler line 125
     * filler line 126
     * filler line 127
     * filler line 128
     * filler line 129
     * filler line 130
     * filler line 131
     * filler line 132
     * filler line 133
     * filler line 134
     * filler line 135
     * filler line 136
     * filler line 137
     * filler line 138
     * filler line 139
     * filler line 140
     * filler line 141
     * filler line 142
     * filler line 143
     * filler line 144
     * filler line 145
     * filler line 146
     * filler line 147
     * filler line 148
     * filler line 149
     * filler line 150
     * filler line 151
     * filler line 152
     * filler line 153
     * filler line 154
     * filler line 155
     * filler line 156
     * filler line 157
     * filler line 158
     * filler line 159
     */
    const a = makeField(2, 1.0f, (x, y) => x * k + y);
    return a.v[0] + a.v[1] + a.v[2] + a.v[3];
}

float elements(float k)
{
    Field[3] fs;
    foreach (i; 0 .. 3)
        fs[i] = makeField(2, 1.0f, (x, y) => x + y * k + i);
    float s = 0;
    foreach (ref f; fs)
        foreach (v; f.v)
            s += v;
    return s;
}

void main()
{
    if (elements(2.0f) != 3 * (2 + 2 * 2) + 4 * (0 + 1 + 2))
        assert(0);
    if (longFields(3.0f) != 0 + 3 + 1 + 4)
        assert(0);
    if (fields(2.0f) != 13.5f + 10 * (2 + 1 + 3 + 3))
        assert(0);
    float[8] e = 0;
    if (earlyReturns(e[], 1.0f) != 23 + 8000)
        assert(0);
    if (twoReturns(5) != (0 + 2 + 3 + 4) + 300)
        assert(0);
    float[8] c = 0;
    if (total(c[], 1.0f) != 50)
        assert(0);
    if (reassigned(3) != 5 + 200)
        assert(0);
    if (stores(7) != 12)
        assert(0);
    if (counts(4) != 4)
        assert(0);
}
