// The object files in a Mach-O static library must start on 8 byte
// boundaries, or the Apple linker rejects the library.
module test.dshell.macho_lib_align;

import dshell;
import std.algorithm : startsWith;
import std.conv : to;
import std.string : strip;

int main()
{
    version (OSX) {} else return DISABLED;

    Vars.set("SRC", "$OUTPUT_BASE/lib.d");
    Vars.set("LIB", "$OUTPUT_BASE/lib$LIBEXT");

    // -lib puts each function in its own member; the symbol table size
    // varies with the number of functions, covering all sizes modulo 8
    foreach (n; 1 .. 13)
    {
        string src;
        foreach (i; 0 .. n)
            src ~= "int fun" ~ i.to!string ~ "() { return " ~ i.to!string ~ "; }\n";
        std.file.write(Vars.SRC, src);
        run("$DMD -m$MODEL -lib -of=$LIB $SRC");
        if (!checkAlignment(cast(const(ubyte)[]) std.file.read(Vars.LIB), n))
            return 1;
    }
    return 0;
}

bool checkAlignment(const(ubyte)[] lib, size_t expectedMembers)
{
    assert(lib[0 .. 8] == "!<arch>\n");
    size_t offset = 8;
    size_t members;
    while (offset + 60 <= lib.length)
    {
        const header = cast(const(char)[]) lib[offset .. offset + 60];
        const size = header[48 .. 58].strip.to!size_t;
        const longName = header[0 .. 3] == "#1/";
        const nameLength = longName ? header[3 .. 16].strip.to!size_t : 0;
        const data = offset + 60 + nameLength;
        const name = longName ? cast(const(char)[]) lib[offset + 60 .. data] : header[0 .. 16];
        if (!name.startsWith("__.SYMDEF"))
        {
            ++members;
            if (data % 8)
            {
                writefln("member %s data at offset %s is not 8 byte aligned", name, data);
                return false;
            }
        }
        offset += 60 + size;
        offset += offset & 1;
    }
    assert(members >= expectedMembers);
    return true;
}
