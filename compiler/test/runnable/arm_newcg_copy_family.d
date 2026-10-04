/* REQUIRED_ARGS: -O -inline -release
 */
// Register allocation of copies of a register, including a register copied to itself

import std.string;

void main()
{
    string s = "  ab c  ";
    if (s.strip != "ab c" || s.stripRight != "  ab c" || s.stripLeft != "ab c  ") assert(0);
}
