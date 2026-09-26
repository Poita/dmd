module imports.parallel_split_a;

// Templates first instantiated from other modules, after the split.
T twice(T)(T x) { return x + x; }

struct Box(T)
{
    T value;
    T get() { return value; }
}

int aOnly() { return twice(3); }
