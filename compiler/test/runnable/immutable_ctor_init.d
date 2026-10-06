/* REQUIRED_ARGS: -O -inline
 */
// Immutable variables given their values at startup are not folded to their initial values

immutable size_t pageSizeLike;
immutable int[4] tableLike;

shared static this()
{
    (cast() pageSizeLike) = 4096;
    (cast() tableLike)[] = [1, 2, 3, 4];
}

pragma(inline, false) size_t pages(size_t bytes) { return (bytes + pageSizeLike - 1) / pageSizeLike; }
pragma(inline, false) int sum() { int s; foreach (k; 0 .. 4) s += tableLike[k] * pageSizeLike.sizeof; return s; }

void main()
{
    if (pages(10000) != 3) assert(0);
    if (sum() != 10 * size_t.sizeof) assert(0);
}
