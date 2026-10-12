void main()
{
    try
    {
        f1();
    }
    catch (Exception e)
    {
        import core.stdc.stdio : printf;
        auto str = e.toString();
        printf("%.*s\n", cast(int)str.length, str.ptr);
    }
}

pragma(inline, false) void f1()
{
    throw new Exception("exception");
}
