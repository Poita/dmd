/* Complex float values returned from and passed to functions.
 * REQUIRED_ARGS: -d
 */

cfloat mk(float re, float im) { return re + im * 1.0fi; }
cfloat add(cfloat a, cfloat b) { return a + b; }
float sumParts(cfloat c) { return c.re + c.im; }

void main()
{
    cfloat c = mk(1.5f, 2.5f);
    assert(c.re == 1.5f && c.im == 2.5f);
    cfloat d = add(c, mk(1, 1));
    assert(d.re == 2.5f && d.im == 3.5f);
    assert(sumParts(d) == 6);
}
