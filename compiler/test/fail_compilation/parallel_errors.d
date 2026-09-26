/* Errors found after the compilation is split across worker processes are reported
 * in the same order as without the split, and only once.
REQUIRED_ARGS: -j=4
EXTRA_SOURCES: imports/parallel_errors_a.d imports/parallel_errors_b.d imports/parallel_errors_c.d
TEST_OUTPUT:
---
fail_compilation/parallel_errors.d(18): Error: cannot implicitly convert expression `"m"` of type `string` to `int`
fail_compilation/imports/parallel_errors_a.d(5): Error: cannot implicitly convert expression `"a"` of type `string` to `int`
fail_compilation/imports/parallel_errors_a.d(3): Error: cannot implicitly convert expression `"s"` of type `string` to `int`
fail_compilation/imports/parallel_errors_a.d(5): Error: template instance `imports.parallel_errors_a.shared_!int` error instantiating
fail_compilation/imports/parallel_errors_b.d(5): Error: cannot implicitly convert expression `"b"` of type `string` to `int`
fail_compilation/imports/parallel_errors_c.d(5): Error: cannot implicitly convert expression `"c"` of type `string` to `int`
---
*/

import imports.parallel_errors_b;

void fm() { int m = "m"; }
