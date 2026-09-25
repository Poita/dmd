// The length of an array held in a register pair is its low register.

size_t f(const string[] a) { size_t t; foreach (v; a) t += v.length; return t; }
void main() { string[2] s = ["abc", "de"]; assert(f(s[]) == 5); }
