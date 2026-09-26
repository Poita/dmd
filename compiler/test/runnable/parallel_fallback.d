/* When the compilation split across worker processes falls back to compiling the
 * modules in the original process, it generates all the code the workers did.
REQUIRED_ARGS: -j=3
EXTRA_SOURCES: imports/parallel_fallback_a.d imports/parallel_fallback_b.d
TEST_OUTPUT:
---
compiling fromB
---
*/

import imports.parallel_fallback_a;
import imports.parallel_fallback_b;

void main()
{
    assert(twice(21) == fromB());
}
