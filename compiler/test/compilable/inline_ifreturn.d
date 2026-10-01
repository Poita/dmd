// REQUIRED_ARGS: -inline -wi
/*
TEST_OUTPUT:
---
---
*/

/* Functions with a chain of early returns are inlined as nested ?:
 */

pragma(inline, true) int classify(int x)
{
    if (x < 0)
        return -1;
    const y = x * 2;
    if (y > 10)
        return 2;
    if (y > 4)
        return 1;
    return 0;
}

pragma(inline, true) float clampStep(float d, float t)
{
    if (d > t)
        return d - t;
    if (-d > t)
        return d + t;
    return 0;
}

int use(int a, float b)
{
    return classify(a) + cast(int) clampStep(b, 0.5f);
}
