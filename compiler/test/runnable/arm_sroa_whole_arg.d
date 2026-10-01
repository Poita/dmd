// REQUIRED_ARGS: -O
// PERMUTE_ARGS: -inline -release

/* A struct of floats split into element variables, passed whole to a
 * function that takes it in floating point registers, directly and through
 * a function pointer.
 */

struct Vec2
{
    float x = 0, y = 0;
    Vec2 opBinary(string op)(float s) const if (op == "*")
    {
        return Vec2(x * s, y * s);
    }
}

pragma(inline, false) float noise(Vec2 p, ulong seed) { return p.x * 0.5f + p.y * 0.25f + (seed & 7); }

__gshared float function(Vec2, ulong) noisePtr = &noise;

float fbm(bool viaPtr)(Vec2 p, int octaves, float lacunarity, float gain, ulong seed)
{
    float sum = 0;
    float amp = 1;
    float norm = 0;
    Vec2 q = p;
    foreach (i; 0 .. octaves)
    {
        static if (viaPtr)
            sum += noisePtr(q, seed + i) * amp;
        else
            sum += noise(q, seed + i) * amp;
        norm += amp;
        amp *= gain;
        q = q * lacunarity;
    }
    return sum / norm;
}

int main()
{
    // q: (2, 4), (4, 8): noise 1 + 1 + 2 = 4 and 2 + 2 + 3 = 7; amp 1, 0.5
    assert(fbm!false(Vec2(2, 4), 2, 2, 0.5f, 2) == 5);
    assert(fbm!true(Vec2(2, 4), 2, 2, 0.5f, 2) == 5);
    return 0;
}
