module imports.parallel_split_b;

import imports.parallel_split_a;

long useB() { return twice(20L) + Box!long(2).get(); }

string nameB() { return typeof(Box!string("x")).stringof; }
