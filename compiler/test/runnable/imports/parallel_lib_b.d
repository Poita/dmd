module imports.parallel_lib_b;

// This module is larger than imports.parallel_lib_a, so that the two are compiled
// by different workers, and neither by the first.
int twice(int x)
{
    return 2 * x;
}

int thrice(int x)
{
    return 3 * x;
}
