// Storing a value held in a register pair (slice, delegate) into an array
// element at a nonzero offset writes both halves of that element.

size_t total(scope string[] keys...)
{
    size_t n;
    foreach (k; keys)
        n += k.length + (k.length ? k[0] : 0);
    return n;
}

void main()
{
    string[3] keys = ["a", "bb", "ccc"];
    assert(keys[0] == "a" && keys[1] == "bb" && keys[2] == "ccc");
    assert(total("a", "bb", "ccc") == 6 + 'a' + 'b' + 'c');

    int[string] aa = ["x": 1, "yy": 2, "zzz": 3];
    assert(aa["x"] == 1 && aa["yy"] == 2 && aa["zzz"] == 3);
}
