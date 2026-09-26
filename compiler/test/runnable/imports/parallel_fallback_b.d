module imports.parallel_fallback_b;

import imports.parallel_fallback_a;

int fromB()
{
    // A message printed by a worker makes the original process compile the
    // modules itself
    pragma(msg, "compiling fromB");
    return twice(21);
}
