/* REQUIRED_ARGS: -O
 */
// A part of a variable held in registers read as an aggregate, as the pointer
// half of an array becoming a one field struct passed to a constructor

import std.range;
import std.algorithm.comparison : equal;

void main()
{
    string s = "foo";
    auto r = refRange(&s).chain("bar");
    assert(equal(r.save, "foobar"));
    assert(equal(r, "foobar"));
}
