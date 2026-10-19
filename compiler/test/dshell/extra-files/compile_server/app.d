import lib;
import old;     // deprecated
import renamed; // declares itself `elsewhere.renamed`

import core.stdc.stdio : printf;

enum tag = "app1";

void main()
{
    printf("%s %d %d %lld %s\n", tag.ptr, libValue() + renamedValue - 1, Box!int(3).twice, Box!long(5).twice, banner.ptr);
}
