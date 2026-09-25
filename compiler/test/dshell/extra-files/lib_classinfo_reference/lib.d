module lib;

class C
{
    int x = 3;
    C self() { return typeid(this) is typeid(C) ? this : null; }
    static C make() { return new C; }
}

C make2() { return new C; }
