/* REQUIRED_ARGS: -O
 */

// A switch with enough sparse cases is compiled to a binary search.

int classify(int x)
{
    switch (x)
    {
        case 1:     return 10;
        case 7:     return 20;
        case 13:    return 30;
        case 100:   return 40;
        case 1000:  return 50;
        case 5000:  return 60;
        default:    return -1;
    }
}

void main()
{
    assert(classify(1) == 10);
    assert(classify(7) == 20);
    assert(classify(13) == 30);
    assert(classify(100) == 40);
    assert(classify(1000) == 50);
    assert(classify(5000) == 60);
    assert(classify(0) == -1);
    assert(classify(50) == -1);
    assert(classify(6000) == -1);
}
