import std.uni;
import other;
size_t f() { auto s = unicode.White_Space; return s.length; }
bool g() { return h(" 12 "); }
void main() { assert(f() > 0); }
