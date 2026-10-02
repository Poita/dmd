// REQUIRED_ARGS: -inline
// PERMUTE_ARGS: -O

/* A condition (!x) ^ 1 of a bool, as inlining a check of a value gives,
 * jumps on x
 */

T check(T)(T value)
{
    if (!value)
        throw new Exception("check failed");
    return value;
}

pragma(inline, false) bool get(bool b) { return b; }

void main()
{
    string[] names = ["", "", "c", ""];
    const a = check(names[3].length == 0);
    const b = check(names[2].length != 0);
    const c = check(get(true));
    bool threw;
    try
        cast(void) check(names[2].length == 0);
    catch (Exception)
        threw = true;
    if (!threw)
        assert(0);
    threw = false;
    try
        cast(void) check(get(false));
    catch (Exception)
        threw = true;
    if (!threw)
        assert(0);
}
