// REQUIRED_ARGS: -j=4
// EXTRA_SOURCES: imports/parallel_split_a.d imports/parallel_split_b.d
// Compiling root modules split across worker processes: template instances made in
// one worker for templates declared in another worker's module are still generated.

import imports.parallel_split_a;
import imports.parallel_split_b;

double useMain() { return twice(1.5) + Box!double(0.5).get(); }

void main()
{
    assert(aOnly() == 6);
    assert(useB() == 42);
    assert(useMain() == 3.5);
    assert(nameB() == "Box!string");
}
