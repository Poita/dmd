module parser.static_if_error_copy;

import dmd.frontend : parseModule;
import support : afterEach, beforeEach;

@beforeEach
void initializeFrontend()
{
    import dmd.frontend : initDMD;

    initDMD();
}

@afterEach
void deinitializeFrontend()
{
    import dmd.frontend : deinitializeDMD;

    deinitializeDMD();
}

@("a `static if` without its parenthesized condition can be copied")
unittest
{
    import dmd.dsymbol : Dsymbol;
    import dmd.globals : global;

    const errors = global.errors;
    global.gag = 1;
    scope (exit)
        global.gag = 0;
    auto t = parseModule("test.d", "template T() { static if { int a; } }");
    assert(global.errors != errors);

    auto members = t.module_.members;
    assert(members && members.length == 1);
    auto copy = Dsymbol.arraySyntaxCopy(members);
    assert(copy.length == 1);
}

@("a statement `static if` without its parenthesized condition can be copied")
unittest
{
    import dmd.dsymbol : Dsymbol;
    import dmd.globals : global;

    global.gag = 1;
    scope (exit)
        global.gag = 0;
    auto t = parseModule("test.d", "void f()() { static if { int a; } }");

    auto members = t.module_.members;
    assert(members && members.length == 1);
    auto copy = Dsymbol.arraySyntaxCopy(members);
    assert(copy.length == 1);
}
