/*
TEST_OUTPUT:
---
fail_compilation/static_if_noparen_copy.d(15): Error: (expression) expected following `static if`
fail_compilation/static_if_noparen_copy.d(17): Error: (expression) expected following `static if`
---
*/

// A `static if` missing the parentheses of its condition is diagnosed once,
// also in templates, whose members are copied for each instance (see
// unit/parser/static_if_error_copy.d for the copy).

template T(int n)
{
    static if { enum T = 1; } else enum T = 2;
}
struct S(int n) { static if { int a; } }

enum x = T!1;
S!1 s;
