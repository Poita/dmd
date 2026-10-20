// The search for nested functions left unused by inlining visits the
// functions given to template instances, where the function generateHash!K,
// instantiated by Map!string as its default argument, has that instance among
// its own instantiating instances, so each leads back to the other.

size_t generateHash(T)()
{
    return 7;
}

struct Map(K, alias hashFunction = generateHash!K)
{
    int[int] items;
    size_t n;

    this(size_t n)
    {
        this.n = n + hashFunction();
    }
}

void main()
{
    auto m = Map!string(16);
    if (m.n != 23)
        assert(0);
}
