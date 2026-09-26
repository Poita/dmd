module imports.parallel_errors_a;

void shared_(T)() { T x = "s"; }

void fa() { int a = "a"; shared_!int(); }
