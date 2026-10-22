/**
 * A module defining an abstract library.
 * Implementations for various formats are in separate `libXXX.d` modules.
 *
 * Copyright:   Copyright (C) 1999-2026 by The D Language Foundation, All Rights Reserved
 * Authors:     $(LINK2 https://www.digitalmars.com, Walter Bright)
 * License:     $(LINK2 https://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:      $(LINK2 https://github.com/dlang/dmd/blob/master/compiler/src/dmd/lib/package.d, _lib.d)
 * Documentation:  https://dlang.org/phobos/dmd_lib.html
 * Coverage:    https://codecov.io/gh/dlang/dmd/src/master/compiler/src/dmd/lib/package.d
 */

module dmd.lib;

import core.stdc.stdio;

import dmd.common.outbuffer;
import dmd.errorsink;
import dmd.location;
import dmd.target : Target;

import dmd.lib.elf;
import dmd.lib.mach;
import dmd.lib.mscoff;

private enum LOG = false;

/// The time, user and group a library records for the members it writes
package struct MemberStamp
{
    long time;
    uint userId, groupId;
    bool fixed;         /// set by SOURCE_DATE_EPOCH, rather than by when and by whom
}

/**
 * Returns: the stamp of the members of a library written now: with the environment
 * variable SOURCE_DATE_EPOCH set to a UNIX time, that time and user and group 0, so
 * that the library is the same whenever and by whoever it is written; otherwise the
 * current time and the user and group of this process
 */
package MemberStamp memberStamp() nothrow
{
    import core.stdc.stdlib : getenv;
    import core.stdc.string : strlen;
    import core.stdc.time : time, time_t;
    import dmd.utils : parseDigits;

    MemberStamp stamp;
    if (auto epoch = getenv("SOURCE_DATE_EPOCH"))
    {
        long t;
        if (parseDigits(t, epoch[0 .. strlen(epoch)]))
        {
            stamp.time = t;
            stamp.fixed = true;
            return stamp;
        }
    }
    time_t now;
    time(&now);
    stamp.time = now;
    version (Posix)
    {
        import core.sys.posix.unistd : getgid, getuid;
        stamp.userId = getuid();
        stamp.groupId = getgid();
    }
    return stamp;
}

class Library
{
    const(char)[] lib_ext;      // library file extension
    ErrorSink eSink;            // where the error messages go

    static Library factory(Target.ObjectFormat of, const char[] lib_ext, ErrorSink eSink)
    {
        Library lib;
        final switch (of)
        {
            case Target.ObjectFormat.elf:   lib = LibElf_factory();     break;
            case Target.ObjectFormat.macho: lib = LibMach_factory();    break;
            case Target.ObjectFormat.coff:  lib = LibMSCoff_factory();  break;
        }
        lib.lib_ext = lib_ext;
        lib.eSink = eSink;
        return lib;
    }

    abstract void addObject(const(char)[] module_name, const ubyte[] buf);

    abstract void writeLibToBuffer(ref OutBuffer libbuf);


    /***********************************
     * Set library file name
     * Params:
     *  filename = name of library file
     */
    final void setFilename(const char[] filename)
    {
        static if (LOG)
        {
            printf("LibElf::setFilename(filename = '%.*s')\n",
                   cast(int)filename.length, filename.ptr);
        }

        this.filename = filename;
    }

  public:
    const(char)[] filename; /// the filename of the library
}
