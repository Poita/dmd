/* A library named by pragma(lib) in a module compiled by a worker process is linked in.
DISABLED: win linux freebsd openbsd dragonflybsd netbsd
REQUIRED_ARGS: -j=3
EXTRA_SOURCES: imports/parallel_lib_a.d imports/parallel_lib_b.d
*/

import imports.parallel_lib_a;
import imports.parallel_lib_b;

void main()
{
    assert(sqlite3_libversion_number() > 3_000_000);
    assert(twice(21) == 42);
    assert(thrice(14) == 42);
}
