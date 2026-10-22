// With SOURCE_DATE_EPOCH set, a library records that time for each of its members,
// and no user or group, so that it is the same whenever and by whoever it is written.
module test.dshell.lib_source_date_epoch;

import dshell;
import std.conv : to;

int main()
{
    std.file.write(Vars.OUTPUT_BASE ~ "/a.d", "module a; int a() { return 1; } int a2() { return 2; }\n");
    std.file.write(Vars.OUTPUT_BASE ~ "/b.d", "module b; int b() { return 3; }\n");
    Vars.set("LIB", "$OUTPUT_BASE/epoch$LIBEXT");
    run("$DMD -m$MODEL -c -of=$OUTPUT_BASE/b$OBJ $OUTPUT_BASE/b.d");
    // a.d's functions in members of their own, and an object file read from disk
    run("$DMD -m$MODEL -lib -multiobj -of=$LIB $OUTPUT_BASE/a.d $OUTPUT_BASE/b$OBJ", stdout, stderr,
        ["SOURCE_DATE_EPOCH": "704124840"]);

    auto lib = cast(const(ubyte)[]) std.file.read(Vars.LIB);
    assert(lib.length >= 8 && lib[0 .. 8] == "!<arch>\n", "not an archive");
    size_t members;
    for (size_t p = 8; p + 60 <= lib.length; )
    {
        const header = cast(const(char)[]) lib[p .. p + 60];
        const name = header[0 .. 16].strip;
        const date = header[16 .. 28].strip;
        const uid = header[28 .. 34].strip;
        const gid = header[34 .. 40].strip;
        const size = header[48 .. 58].strip.to!size_t;
        if (date != "704124840" || uid.length && uid != "0" || gid.length && gid != "0")
        {
            writefln("member '%s' records date '%s', user '%s', group '%s'", name, date, uid, gid);
            return 1;
        }
        ++members;
        p += 60 + size;
        p += p & 1;
    }
    assert(members >= 3, "too few members");
    return 0;
}
