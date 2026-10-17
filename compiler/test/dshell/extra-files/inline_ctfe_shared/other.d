module other;
import lib;
size_t h() { static immutable n = make(3); return n; }
