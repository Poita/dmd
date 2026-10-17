module other;
import std.regex;
bool h(string s)
{
    static re = regex(`^\s*(\d+)\s*$`, ``);
    return !matchFirst(s, re).empty;
}
