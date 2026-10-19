module imports.pragmainline_noanalysis;

int notInlined(int x)
{
    static assert(0, "the body of notInlined is analyzed");
}
