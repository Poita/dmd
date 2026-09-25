// Floating point %= where the operation is done in a wider type than the variable.

void main()
{
    float a = 7;
    a %= 4.0;
    assert(a == 3);

    float b = 7.5f;
    double d = 2;
    b %= d;
    assert(b == 1.5f);

    double c = 9;
    c %= 4.0f;
    assert(c == 1);

    float[] arr = [5, 6];
    arr[1] %= 4.0;
    assert(arr[1] == 2);
}
