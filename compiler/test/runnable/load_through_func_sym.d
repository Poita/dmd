// Reading data at the address of a function.

void func() { }

int firstWord() { return *cast(int*) &func; }

void main()
{
    assert(firstWord() != 0);
    assert(firstWord() == *cast(int*) &func);
}
