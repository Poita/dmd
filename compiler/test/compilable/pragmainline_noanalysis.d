/* REQUIRED_ARGS: -c
 * PERMUTE_ARGS:
 */
// Looking for calls to inline in a module with pragma(inline, true) functions does
// not analyze the bodies of functions not marked to be inlined from imported modules

import imports.pragmainline_noanalysis;

pragma(inline, true) int twice(int x) { return x * 2; }

int use(int x)
{
    return twice(x) + notInlined(x);
}
