/**
 * Keep the modules a compilation imports loaded in a resident process, so that the next
 * identical compilation starts with them read, parsed and with their symbol tables built.
 *
 * Setting the environment variable `DMD_SERVER` to a directory enables it. A compilation
 * computes a key from everything its result depends on besides the source files it reads:
 * the compiler binary, the working directory, the arguments after the configuration file
 * and response files are applied, the environment and whether messages are colored. It
 * then connects to the server for that key, a socket in `/tmp/dmd-server-<uid>`. Without
 * a server it compiles by itself and records the modules that importing the root modules
 * loads, in the order it loads them, with the root module each is first imported from.
 * When it succeeds and the same key has been compiled before, it starts a server: a copy
 * of the compiler, run with the same arguments and environment, that loads those modules
 * as the compilation did, up to their importAll, and waits.
 *
 * The server compiles a request in a fork of itself, which takes the client's standard
 * streams, reads and parses the root modules, finds the modules they import already
 * loaded and continues as a compilation does; the client exits with its status. Before
 * forking, the server checks that none of the files it read has changed since it read
 * them; if one has, it tells the client to compile by itself, and exits. A server that has
 * had no request for `DMD_SERVER_IDLE` seconds (600 by default) exits, and no more than
 * `DMD_SERVER_MAX` servers (8 by default) of a user run at once. The directory keeps
 * each key's recorded imports and its server's log.
 *
 * Loading a module does not depend on the root modules, while the outcome of semantic
 * analysis can depend on the order in which modules are analyzed (which instantiation
 * of a template comes first, how `ModuleInfo` needs propagate through import cycles), so
 * the server analyzes nothing. The identifiers loading generates are numbered as in the
 * compilation it was started from, and a request whose root modules are unchanged
 * generates the same output as a compilation by itself.
 *
 * A server only starts when loading the imported modules gives no messages and reads
 * none of the root modules. Compilations that report on everything they analyze, such as
 * those with `-v`, `-X`, `-D`, `-H`, `-deps` or `-i`, do not use servers.
 *
 * `DMD_SERVER_VERIFY` makes every compilation that can use a server run three times:
 * by itself with its output discarded, then by a server started for it alone, whose result
 * is the compilation's, or by itself again when no server could start. It runs the test
 * suite through servers.
 *
 * Copyright:   Copyright (C) 1999-2026 by The D Language Foundation, All Rights Reserved
 * License:     $(LINK2 https://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module dmd.compileserver;

import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;

import dmd.arraytypes;
import dmd.astenums : FileType;
import dmd.dimport : Import;
import dmd.dmodule;
import dmd.dsymbol;
import dmd.globals;
import dmd.location : Loc;
import dmd.root.array;
import dmd.root.filename;
import dmd.root.string : toDString;

version (Posix)
{
    import core.sys.posix.fcntl : open, O_RDONLY, O_WRONLY, O_CREAT, O_APPEND;
    import core.sys.posix.poll : poll, pollfd, POLLIN, POLLHUP, POLLERR;
    import core.sys.posix.signal : kill, SIGHUP, SIGINT, SIGKILL, SIGTERM, signal, SIG_DFL;
    import core.sys.posix.sys.socket;
    import core.sys.posix.sys.stat : stat, stat_t, fstat, mkdir;
    import core.sys.posix.sys.types : pid_t, ssize_t;
    import core.sys.posix.sys.un : sockaddr_un;
    import core.sys.posix.sys.wait : waitpid, WIFEXITED, WEXITSTATUS, WIFSIGNALED, WTERMSIG, WNOHANG;
    import core.sys.posix.unistd : close, dup2, fork, getcwd, getpid, pipe, read, setpgid, unlink, write, _exit;
}

/// What this process does about servers
enum Role : ubyte
{
    none,    /// compiles by itself
    client,  /// asks a server first, and records its imports when it compiles by itself
    server,  /// analyzes the imported modules and waits for requests
    request, /// compiles a request, forked from a server
}

__gshared Role role;

private:

enum envServer = "DMD_SERVER";
enum envRole = "DMD_SERVER_ROLE";
enum compileYourself = -1;  /// reply telling the client to compile by itself

__gshared const(char)[] dir;            // DMD_SERVER
__gshared const(char)[] key;            // everything the compilation depends on besides its files
__gshared const(char)[] base;           // dir/<hash of key>, for the files of the server
__gshared const(char)[] sockDir;        // where the sockets are, a short path
__gshared const(char)[] sockPath;       // sockDir/<hash of key>.sock
__gshared const(char*)* spawnArgv;      // arguments this process was started with
__gshared bool verify;                  // DMD_SERVER_VERIFY
__gshared bool oneRequest;              // server for a single request, for DMD_SERVER_VERIFY
__gshared int readyFd = -1;             // where a single-request server reports whether it started
__gshared const(char)[] importList;     // the imported modules a client compilation recorded
__gshared Strings arguments;            // arguments after configuration and response files
__gshared bool startable;               // the list of imported modules allows a server to start
__gshared size_t rootIds;               // identifiers generated when the root modules are parsed
__gshared size_t loadedIds;             // ... and when importing them has loaded the imported modules
__gshared size_t importAllModules;      // modules loaded when importing the root modules

// in a server: the root modules' members added while loading the imported modules
struct Pending { Module m; Dsymbols* members; }
__gshared Array!Pending pending;
// in a server: the root module each imported module is imported from, by file name
__gshared Module[const(char)[]] listedImporter;
// in a client: the name each module was loaded by
__gshared const(char)[][void*] loadedAs;
// in a server: the modules it loaded for the root modules' imports, by identity
__gshared bool[void*] unplaced;

struct Stamp
{
    const(char)[] name;
    ulong dev, ino, size;
    long mtime, mtimeNsec, ctime, ctimeNsec;
}
__gshared Array!Stamp stamps;

public:

/**************************************
 * Note the arguments after the configuration file, the `DFLAGS` and response files are
 * applied, which are part of the key.
 */
void noteArguments(ref const Strings args)
{
    foreach (a; args)
        arguments.push(a);
}

/**************************************
 * Decide what this process does about servers. A client asks the server for its key to
 * compile, and returns true with `status` set when one did.
 * Params:
 *      argv = the arguments this process was started with
 *      params = the parsed command line
 *      status = set to the exit status of the compilation a server ran
 * Returns: true when a server ran the compilation
 */
bool start(const(char)[][] argv, ref Param params, out int status)
{
    version (Posix)
    {
        auto d = getenv(envServer);
        if (!d || !*d || !eligible(params))
            return false;
        dir = d[0 .. strlen(d)].idup;
        const r = getenv(envRole);
        if (r && r[0] == 's')
        {
            // `s<color><single request><ready fd>`
            role = Role.server;
            params.v.color = r[1] == '1';
            oneRequest = r[2] == '1';
            if (r[3])
                readyFd = atoi(r + 3);
        }
        else
            role = Role.client;
        verify = getenv("DMD_SERVER_VERIFY") !is null;

        auto args = new const(char)*[argv.length + 1];
        foreach (i, a; argv)
            args[i] = (a ~ '\0').ptr;
        spawnArgv = args.ptr;

        if (!makeKey(params))
        {
            role = Role.none;
            return false;
        }
        import dmd.dsymbolsem : onImport;
        onImport = &noteImport;
        if (role == Role.server)
            return false;

        if (verify)
            return verifyRequest(status);
        if (ask(status))
            return true;
        return false;
    }
    else
        return false;
}

/**************************************
 * After the root modules are parsed: a client notes how many identifiers that generated.
 */
void rootsParsed()
{
    import dmd.identifier : Identifier;
    if (role == Role.client)
        rootIds = Identifier.suffixCount;
}

/**************************************
 * After the root modules' importAll: a client notes which modules it loaded; a request
 * adds the root modules' members that loading the imported modules added, as compiling
 * by itself adds them later, and continues the numbering of generated identifiers after
 * those of the loaded modules.
 */
void rootsImported()
{
    import dmd.identifier : Identifier;
    if (role == Role.client)
    {
        importAllModules = Module.amodules.length;
        loadedIds = Identifier.suffixCount;
    }
    else if (role == Role.request)
    {
        foreach (ref p; pending)
            p.m.members.append(p.members);
        pending.setDim(0);
        if (Identifier.suffixCount < loadedIds)
            Identifier.suffixCount = loadedIds;
    }
}

/**************************************
 * In a client compiling by itself, before the compilation is split: record the modules
 * that importing the root modules loaded, with the root module each was first imported
 * from.
 */
void recordImports(ref Modules modules)
{
    if (role != Role.client)
        return;
    import dmd.common.outbuffer;
    OutBuffer buf;
    buf.printf("%llu %llu\n", cast(ulong)rootIds, cast(ulong)loadedIds);
    startable = true;
    foreach (m; Module.amodules[0 .. importAllModules])
    {
        if (m.isRoot())
            continue;
        if (m.filetype != FileType.d && m.filetype != FileType.dhdr)
        {
            startable = false;
            return;
        }
        // a module no import loaded is a package.d loaded to look up a package
        auto name = cast(void*)m in loadedAs;
        if (!name && !m.isPackageFile)
        {
            startable = false;
            return;
        }
        const(char)[] how = name ? "import" : "package";
        const(char)[] n = name ? *name : m.toPrettyChars().toDString();
        int from = -1;
        foreach (i, r; modules)
            if (r is m.importedFrom)
                from = cast(int)i;
        buf.printf("%d\t%.*s\t%.*s\t%s\n", from, cast(int)how.length, how.ptr,
            cast(int)n.length, n.ptr, m.srcfile.toChars());
    }
    importList = buf.extractSlice();
}

/**************************************
 * In a client that compiled by itself and succeeded, save its imports and start a server
 * when the same key has been compiled before.
 */
void finish(int status)
{
    version (Posix)
    {
        if (role != Role.client || status != 0 || !startable)
            return;
        import dmd.root.file : File;
        const list = base ~ ".list";
        const compiledBefore = FileName.exists(list) == 1;
        const tmp = base ~ ".list.tmp";
        if (!File.write(tmp, importList) || rename((tmp ~ '\0').ptr, (list ~ '\0').ptr) != 0)
            return;
        if (verify)
            spawnServer(true);
        else if (compiledBefore && !failedBefore() && runningServers() < limit("DMD_SERVER_MAX", 8))
            spawnServer(false);
    }
}

/**************************************
 * In a server: load the imported modules the last compilation by itself recorded, then
 * serve requests. Returns only in a forked process that compiles a
 * request; the server itself exits.
 * Params:
 *      modules = the root modules, created but not read
 */
void serve(ref Modules modules)
{
    version (Posix)
    {
        if (role != Role.server)
            return;
        if (!preload(modules))
        {
            // clients start no server for the same imports again
            import dmd.root.file : File;
            import dmd.common.outbuffer;
            OutBuffer list;
            if (!File.read(base ~ ".list", list))
                File.write(base ~ ".failed", list[]);
            report(false);
            exit(EXIT_SUCCESS);
        }
        const listener = openListener();
        if (listener < 0)
        {
            report(false);
            exit(EXIT_SUCCESS);
        }
        report(true);
        fprintf(stderr, "ready %d\n", getpid());
        fflush(stderr);
        serveRequests(listener);
    }
}

/**************************************
 * Called when an import has found or loaded (`loaded`) its module. A client notes the
 * name each module is loaded by. A server loading the imported modules sets the root
 * module each is first imported from as in the compilation it was started from. In a
 * request, the module the server loaded for a root module's import takes that import's
 * location, as loading it there would have given it.
 */
void noteImport(Import imp, bool loaded)
{
    final switch (role)
    {
        case Role.none:
            break;
        case Role.client:
            if (loaded)
            {
                import dmd.common.outbuffer;
                OutBuffer buf;
                foreach (p; imp.packages)
                {
                    buf.writestring(p.toString());
                    buf.writeByte('.');
                }
                buf.writestring(imp.id.toString());
                loadedAs[cast(void*)imp.mod] = buf.extractSlice();
            }
            break;
        case Role.server:
            if (!imp.mod.importedFrom)
                if (auto p = imp.mod.srcfile.toString() in listedImporter)
                    imp.mod.importedFrom = *p;
            break;
        case Role.request:
            if (cast(void*)imp.mod in unplaced)
            {
                // a module's location is that of the import that loads it, which the
                // server loaded it before
                *cast(Loc*)&imp.mod.loc = imp.loc;
                unplaced.remove(cast(void*)imp.mod);
            }
            break;
    }
}

private:

bool eligible(const ref Param params)
{
    import dmd.compiler : includeImports;
    return params.obj && !includeImports && !params.addMain && !params.run &&
        !params.json.doOutput && !params.ddoc.doOutput && !params.vcg_ast &&
        !params.cxxhdr.doOutput && !params.moduleDeps.buffer && !params.moduleDeps.doOutput &&
        !params.dihdr.doOutput && !params.timeTrace && !params.v.verbose && !params.v.templates &&
        !params.makeDeps.doOutput && !params.mixinOut.doOutput && !params.readStdin;
}

int limit(const(char)* name, int dflt)
{
    if (auto p = getenv(name))
        return atoi(p);
    return dflt;
}

version (Posix):

extern (C) extern __gshared char** environ;

version (OSX)
    extern (C) int _NSGetExecutablePath(char* buf, uint* bufsize);

const(char)[] executablePath()
{
    char[4096] buf = void;
    version (OSX)
    {
        uint size = buf.length;
        if (_NSGetExecutablePath(buf.ptr, &size) != 0)
            return null;
        return buf[0 .. strlen(buf.ptr)].idup;
    }
    else
    {
        import core.sys.posix.unistd : readlink;
        const n = readlink("/proc/self/exe", buf.ptr, buf.length);
        return n > 0 ? buf[0 .. n].idup : null;
    }
}

bool makeKey(const ref Param params)
{
    import dmd.common.outbuffer;
    OutBuffer buf;
    const exe = executablePath();
    if (!exe.length)
        return false;
    stat_t st;
    if (stat((exe ~ '\0').ptr, &st) != 0)
        return false;
    buf.printf("%.*s %llu %llu %llu %lld\n", cast(int)exe.length, exe.ptr,
        cast(ulong)st.st_dev, cast(ulong)st.st_ino, cast(ulong)st.st_size, cast(long)st.st_mtime);
    char[4096] cwd = void;
    if (!getcwd(cwd.ptr, cwd.length))
        return false;
    buf.writestring(cwd.ptr);
    buf.writeByte(0);
    buf.printf("color=%d", params.v.color);
    buf.writeByte(0);
    foreach (a; arguments)
    {
        buf.writestring(a);
        buf.writeByte(0);
    }
    buf.writeByte(0);
    for (auto e = environ; *e; ++e)
    {
        if (strncmp(*e, envRole ~ "=", envRole.length + 1) == 0)
            continue;
        buf.writestring(*e);
        buf.writeByte(0);
    }
    key = buf.extractSlice();

    // FNV-1a
    ulong h = 0xcbf29ce484222325;
    foreach (c; key)
    {
        h ^= cast(ubyte)c;
        h *= 0x100000001b3;
    }
    char[17] hex = void;
    snprintf(hex.ptr, hex.length, "%016llx", h);
    mkdir((dir ~ '\0').ptr, octal!700);
    base = dir ~ "/" ~ hex[0 .. 16].idup;

    // a socket's path is limited to about a hundred bytes
    import core.sys.posix.unistd : getuid;
    char[64] sd = void;
    const sdlen = snprintf(sd.ptr, sd.length, "/tmp/dmd-server-%u", cast(uint)getuid());
    sockDir = sd[0 .. sdlen].idup;
    mkdir((sockDir ~ '\0').ptr, octal!700);
    sockPath = sockDir ~ "/" ~ hex[0 .. 16].idup ~ ".sock";
    return sockPath.length < sockaddr_un.sun_path.length;
}

enum octal(int n) = (n / 100) * 64 + ((n / 10) % 10) * 8 + n % 10;

bool socketAddress(ref sockaddr_un addr)
{
    const path = sockPath;
    if (path.length >= addr.sun_path.length)
        return false;
    memset(&addr, 0, addr.sizeof);
    addr.sun_family = AF_UNIX;
    memcpy(addr.sun_path.ptr, path.ptr, path.length);
    return true;
}

// Ancillary data carrying three file descriptors
version (OSX)
    enum cmsgAlign = 4;
else
    enum cmsgAlign = size_t.sizeof;
size_t cmsgAligned(size_t n) { return (n + cmsgAlign - 1) & ~(cmsgAlign - 1); }
enum fdBytes = 3 * int.sizeof;

bool sendAll(int fd, const(void)[] data)
{
    while (data.length)
    {
        const n = send(fd, data.ptr, data.length, 0);
        if (n <= 0)
            return false;
        data = data[n .. $];
    }
    return true;
}

bool recvAll(int fd, void[] data)
{
    while (data.length)
    {
        const n = recv(fd, data.ptr, data.length, 0);
        if (n <= 0)
            return false;
        data = data[n .. $];
    }
    return true;
}

/// Send the key with this process's standard streams; true when sent
bool sendRequest(int fd)
{
    uint len = cast(uint)key.length;
    iovec iov;
    iov.iov_base = &len;
    iov.iov_len = len.sizeof;
    ubyte[64] control = 0;
    msghdr msg;
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;
    msg.msg_control = control.ptr;
    msg.msg_controllen = cast(typeof(msg.msg_controllen))(cmsgAligned(cmsghdr.sizeof) + cmsgAligned(fdBytes));
    auto cmsg = cast(cmsghdr*)control.ptr;
    cmsg.cmsg_level = SOL_SOCKET;
    cmsg.cmsg_type = SCM_RIGHTS;
    cmsg.cmsg_len = cast(typeof(cmsg.cmsg_len))(cmsgAligned(cmsghdr.sizeof) + fdBytes);
    int[3] fds = [0, 1, 2];
    memcpy(control.ptr + cmsgAligned(cmsghdr.sizeof), fds.ptr, fdBytes);
    if (sendmsg(fd, &msg, 0) != len.sizeof)
        return false;
    return sendAll(fd, key);
}

enum Received { nothing, otherKey, request }

/// Receive a request, with `fds` set to the client's standard streams
Received receiveRequest(int fd, ref int[3] fds)
{
    uint len;
    iovec iov;
    iov.iov_base = &len;
    iov.iov_len = len.sizeof;
    ubyte[64] control = 0;
    msghdr msg;
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;
    msg.msg_control = control.ptr;
    msg.msg_controllen = control.length;
    if (recvmsg(fd, &msg, MSG_WAITALL) != len.sizeof)
        return Received.nothing;    // a client checking that the server is running
    auto cmsg = cast(cmsghdr*)control.ptr;
    if (msg.msg_controllen < cmsgAligned(cmsghdr.sizeof) + fdBytes ||
        cmsg.cmsg_level != SOL_SOCKET || cmsg.cmsg_type != SCM_RIGHTS)
        return Received.otherKey;
    memcpy(fds.ptr, control.ptr + cmsgAligned(cmsghdr.sizeof), fdBytes);
    if (len != key.length)
        return Received.otherKey;
    auto k = new char[len];
    return recvAll(fd, k) && k == key ? Received.request : Received.otherKey;
}

/// Ask the server for this key to compile; true with `status` set when it did
bool ask(out int status)
{
    sockaddr_un addr;
    if (!socketAddress(addr))
        return false;
    const fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0)
        return false;
    scope (exit) close(fd);
    if (connect(fd, cast(sockaddr*)&addr, addr.sizeof) != 0)
        return false;
    int reply;
    if (!sendRequest(fd) || !recvAll(fd, (&reply)[0 .. 1]) || reply == compileYourself)
        return false;
    if (reply >= 256)
    {
        // the compilation was killed by a signal
        fflush(stdout);
        fflush(stderr);
        signal(reply - 256, SIG_DFL);
        kill(getpid(), reply - 256);
        status = EXIT_FAILURE;
        return true;
    }
    status = reply;
    return true;
}

/// For DMD_SERVER_VERIFY: compile by itself with the output discarded, then through a server
bool verifyRequest(out int status)
{
    fflush(stdout);
    fflush(stderr);
    const pid = fork();
    if (pid < 0)
        return false;
    if (pid == 0)
    {
        const nul = open("/dev/null", O_WRONLY);
        dup2(nul, 1);
        dup2(nul, 2);
        close(nul);
        return false;   // compile, and start a server when that succeeds
    }
    int st;
    while (waitpid(pid, &st, 0) < 0) {}
    const served = ask(status);
    role = Role.none;   // compiling by itself again starts no other server
    return served;
}

/// Whether a server failed to start for the imports just recorded
bool failedBefore()
{
    import dmd.root.file : File;
    import dmd.common.outbuffer;
    OutBuffer failed;
    return !File.read(base ~ ".failed", failed) && failed[] == importList;
}

int runningServers()
{
    import core.sys.posix.dirent;
    auto d = opendir((sockDir ~ '\0').ptr);
    if (!d)
        return 0;
    scope (exit) closedir(d);
    int n;
    while (auto e = readdir(d))
    {
        const name = e.d_name.ptr[0 .. strlen(e.d_name.ptr)];
        if (name.length <= 5 || name[$ - 5 .. $] != ".sock")
            continue;
        // count the sockets of running servers, removing those left by servers that are gone
        const path = sockDir ~ "/" ~ name;
        sockaddr_un addr;
        if (path.length >= addr.sun_path.length)
            continue;
        addr.sun_family = AF_UNIX;
        memcpy(addr.sun_path.ptr, path.ptr, path.length);
        const fd = socket(AF_UNIX, SOCK_STREAM, 0);
        if (connect(fd, cast(sockaddr*)&addr, addr.sizeof) == 0)
            ++n;
        else
            unlink((path ~ '\0').ptr);
        close(fd);
    }
    return n;
}

/// Start a server for this key, with this process's arguments and environment
void spawnServer(bool single)
{
    import core.sys.posix.spawn;
    int[2] ready = [-1, -1];
    if (single && pipe(ready) != 0)
        return;

    char[32] roleVar = void;
    snprintf(roleVar.ptr, roleVar.length, "%s=s%d%d%s", envRole.ptr, global.params.v.color ? 1 : 0,
        single ? 1 : 0, single ? "3".ptr : "".ptr);
    Array!(const(char)*) env;
    for (auto e = environ; *e; ++e)
        if (strncmp(*e, envRole ~ "=", envRole.length + 1) != 0)
            env.push(*e);
    env.push(roleVar.ptr);
    env.push(null);

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    scope (exit) posix_spawn_file_actions_destroy(&actions);
    posix_spawn_file_actions_addopen(&actions, 0, "/dev/null", O_RDONLY, 0);
    const log = (base ~ ".log\0");
    posix_spawn_file_actions_addopen(&actions, 1, log.ptr, O_WRONLY | O_CREAT | O_APPEND, octal!600);
    posix_spawn_file_actions_adddup2(&actions, 1, 2);
    if (single)
        posix_spawn_file_actions_adddup2(&actions, ready[1], 3);

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    scope (exit) posix_spawnattr_destroy(&attr);
    version (OSX)
    {
        // POSIX_SPAWN_SETSID | POSIX_SPAWN_CLOEXEC_DEFAULT: close every other descriptor
        posix_spawnattr_setflags(&attr, cast(short)(0x0400 | 0x4000));
    }
    else
    {
        posix_spawnattr_setflags(&attr, cast(short)POSIX_SPAWN_SETSID);
    }

    const exe = executablePath() ~ '\0';
    pid_t pid;
    const r = posix_spawn(&pid, exe.ptr, &actions, &attr, cast(char**)spawnArgv, cast(char**)env[].ptr);
    if (single)
    {
        close(ready[1]);
        if (r == 0)
        {
            char c;
            read(ready[0], &c, 1);  // until the server is ready or has exited
        }
        close(ready[0]);
    }
}

/// In a single-request server, report whether it started
void report(bool started)
{
    if (readyFd < 0)
        return;
    const char c = started ? 'y' : 'n';
    write(readyFd, &c, 1);
    close(readyFd);
    readyFd = -1;
}

int openListener()
{
    sockaddr_un addr;
    if (!socketAddress(addr))
        return -1;
    const fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0)
        return -1;
    if (bind(fd, cast(sockaddr*)&addr, addr.sizeof) != 0)
    {
        // a socket left by a server that is gone is replaced; a live server is kept
        const probe = socket(AF_UNIX, SOCK_STREAM, 0);
        const live = connect(probe, cast(sockaddr*)&addr, addr.sizeof) == 0;
        close(probe);
        if (live || unlink(cast(const(char)*)addr.sun_path.ptr) != 0 || bind(fd, cast(sockaddr*)&addr, addr.sizeof) != 0)
        {
            close(fd);
            return -1;
        }
    }
    if (core.sys.posix.sys.socket.listen(fd, 16) != 0)
    {
        close(fd);
        return -1;
    }
    return fd;
}

void stopListening(int listener)
{
    unlink((sockPath ~ '\0').ptr);
    close(listener);
}

/// Load the imported modules of the list; true when the server can start
bool preload(ref Modules roots)
{
    import dmd.dsymbolsem : importAll;
    import dmd.identifier : Identifier;
    import dmd.location : Loc;
    import dmd.root.file : File;
    import dmd.common.outbuffer;

    if (!roots.length)
        return false;
    OutBuffer listBuf;
    if (File.read(base ~ ".list", listBuf))
        return false;
    const outputBefore = outputSize();

    foreach (m; roots)
    {
        m.importedFrom = m;
        m.members = new Dsymbols();
    }
    Module.rootModule = roots[0];

    auto lines = splitLines(listBuf[]);
    if (!lines.length)
        return false;
    {
        // the identifiers generated before and after loading, in the compilation by itself
        const sp = indexOf(lines[0], ' ');
        if (sp < 0)
            return false;
        rootIds = strtoull((lines[0][0 .. sp] ~ '\0').ptr, null, 10);
        loadedIds = strtoull((lines[0][sp + 1 .. $] ~ '\0').ptr, null, 10);
    }
    Identifier.suffixCount = rootIds;

    // `<root index or -1>\t<import|package>\t<name>\t<file>`
    static struct Entry { Module from; bool imported; const(char)[] name; const(char)[] file; }
    Entry[] entries;
    foreach (line; lines[1 .. $])
    {
        const(char)[][4] f;
        foreach (i; 0 .. 3)
        {
            const t = indexOf(line, '\t');
            if (t < 0)
                return false;
            f[i] = line[0 .. t];
            line = line[t + 1 .. $];
        }
        f[3] = line;
        const from = atoi((f[0] ~ '\0').ptr);
        if (from < -1 || from >= cast(int)roots.length)
            return false;
        auto e = Entry(from < 0 ? null : roots[from], f[1] == "import", f[2].idup, f[3].idup);
        entries ~= e;
        if (e.from)
            listedImporter[e.file] = e.from;
    }

    Module[const(char)[]] loaded;
    foreach (ref e; entries)
    {
        if (e.file !in loaded)
        {
            Identifier[] packages;
            const(char)[] rest = e.name;
            for (ptrdiff_t dot; (dot = indexOf(rest, '.')) >= 0; rest = rest[dot + 1 .. $])
                packages ~= Identifier.idPool(rest[0 .. dot]);
            // as an import of a root module loads it, but without the import's location,
            // or as looking up a package loads its package.d
            auto id = Identifier.idPool(rest);
            auto dst = Package.resolve(packages, null, null);
            auto m = Module.load(Loc.initial, packages, id);
            if (!m || m.srcfile.toString() != e.file || global.errors)
                return false;
            if (e.imported)
            {
                dst.insert(id, m);
                unplaced[cast(void*)m] = true;
            }
            if (!m.importedFrom)
                m.importedFrom = e.from;
            m.importAll(null);
            if (global.errors)
                return false;
            foreach (a; Module.amodules)
                loaded[a.srcfile.toString()] = a;
        }
    }
    foreach (ref e; entries)
        if (e.file !in loaded)
            return false;
    loadedIds = Identifier.suffixCount;

    fflush(stdout);
    fflush(stderr);
    if (global.errors || global.warnings || global.deprecations || outputSize() != outputBefore)
        return false;

    foreach (m; roots)
    {
        pending.push(Pending(m, m.members));
        m.members = null;
    }
    listedImporter = null;
    return stampFiles(roots);
}

/// Bytes written to standard error, which is the log file
long outputSize()
{
    fflush(stderr);
    stat_t st;
    return fstat(2, &st) == 0 ? cast(long)st.st_size : -1;
}

/// Record the state of the files read so far; false when one is a root module
bool stampFiles(ref Modules roots)
{
    bool[ulong] rootInodes;
    foreach (m; roots)
    {
        stat_t st;
        if (stat(m.srcfile.toChars(), &st) == 0)
            rootInodes[st.st_ino] = true;
    }
    const(char)[][] names;
    global.fileManager.eachFile((const(char)[] name) { names ~= name.idup; });
    foreach (name; names)
    {
        Stamp s;
        s.name = name;
        if (!stampOf(s) || s.ino in rootInodes)
            return false;
        stamps.push(s);
    }
    return true;
}

bool stampOf(ref Stamp s)
{
    stat_t st;
    if (stat((s.name ~ '\0').ptr, &st) != 0)
        return false;
    s.dev = st.st_dev;
    s.ino = st.st_ino;
    s.size = st.st_size;
    version (OSX)
    {
        s.mtime = st.st_mtimespec.tv_sec;
        s.mtimeNsec = st.st_mtimespec.tv_nsec;
        s.ctime = st.st_ctimespec.tv_sec;
        s.ctimeNsec = st.st_ctimespec.tv_nsec;
    }
    else
    {
        s.mtime = st.st_mtim.tv_sec;
        s.mtimeNsec = st.st_mtim.tv_nsec;
        s.ctime = st.st_ctim.tv_sec;
        s.ctimeNsec = st.st_ctim.tv_nsec;
    }
    return true;
}

/// The first file read that has changed since, or null
const(char)[] changedFile()
{
    foreach (ref s; stamps)
    {
        Stamp now = s;
        if (!stampOf(now) || now != s)
            return s.name;
    }
    return null;
}

__gshared const(char)* sockPathz;

extern (C) void stopOnSignal(int) nothrow @nogc
{
    unlink(sockPathz);
    _exit(EXIT_SUCCESS);
}

void serveRequests(int listener)
{
    sockPathz = (sockPath ~ '\0').ptr;
    foreach (sig; [SIGTERM, SIGINT, SIGHUP])
        signal(sig, &stopOnSignal);
    const idleMs = limit("DMD_SERVER_IDLE", 600) * 1000;
    while (true)
    {
        pollfd p = pollfd(listener, POLLIN, 0);
        const n = poll(&p, 1, idleMs);
        if (n == 0)
        {
            stopListening(listener);
            exit(EXIT_SUCCESS);
        }
        if (n < 0)
            continue;
        const conn = accept(listener, null, null);
        if (conn < 0)
            continue;
        int[3] fds = [-1, -1, -1];
        const received = receiveRequest(conn, fds);
        if (received != Received.request)
        {
            if (received == Received.otherKey)
            {
                fprintf(stderr, "other key\n");
                fflush(stderr);
                reply(conn, compileYourself);
            }
            closeAll(fds);
            close(conn);
            continue;
        }
        if (const changed = changedFile())
        {
            fprintf(stderr, "stale %.*s\n", cast(int)changed.length, changed.ptr);
            fflush(stderr);
            stopListening(listener);
            reply(conn, compileYourself);
            exit(EXIT_SUCCESS);
        }
        fflush(stdout);
        fflush(stderr);
        const pid = fork();
        if (pid == 0)
        {
            foreach (sig; [SIGTERM, SIGINT, SIGHUP])
                signal(sig, SIG_DFL);
            setpgid(0, 0);
            close(listener);
            close(conn);
            foreach (i, fd; fds)
                dup2(fd, cast(int)i);
            closeAll(fds);
            becomeRequest();
            return;
        }
        closeAll(fds);
        const status = pid < 0 ? compileYourself : await(pid, conn);
        fprintf(stderr, "served %d\n", status);
        fflush(stderr);
        reply(conn, status);
        close(conn);
        if (oneRequest)
        {
            stopListening(listener);
            exit(EXIT_SUCCESS);
        }
    }
}

/// Wait for the request `pid`, killing it when the client goes away; its exit status
int await(pid_t pid, int conn)
{
    while (true)
    {
        int st;
        const r = waitpid(pid, &st, WNOHANG);
        if (r == pid)
            return WIFEXITED(st) ? WEXITSTATUS(st) : WIFSIGNALED(st) ? 256 + WTERMSIG(st) : EXIT_FAILURE;
        pollfd p = pollfd(conn, POLLIN, 0);
        if (poll(&p, 1, 20) > 0 && (p.revents & (POLLHUP | POLLERR | POLLIN)))
        {
            // the client sends nothing more: readable means it has closed the connection
            kill(-pid, SIGKILL);
            kill(pid, SIGKILL);
            waitpid(pid, &st, 0);
            return EXIT_FAILURE;
        }
    }
}

void reply(int conn, int status)
{
    sendAll(conn, (&status)[0 .. 1]);
}

void closeAll(ref int[3] fds)
{
    foreach (fd; fds)
        if (fd > 2)
            close(fd);
}

/// In the forked process: refresh what depends on the time or the client's streams
void becomeRequest()
{
    import dmd.console : createConsole;
    import dmd.identifier : Identifier;
    role = Role.request;
    Identifier.suffixCount = 0;     // as before the root modules are parsed
    global.initDateTime();
    global.fileManager.forgetPaths();
    if (global.params.v.color)
        global.console = cast(void*) createConsole(core.stdc.stdio.stderr);
}

const(char)[][] splitLines(const(char)[] s)
{
    const(char)[][] lines;
    while (s.length)
    {
        const nl = indexOf(s, '\n');
        if (nl < 0)
        {
            lines ~= s;
            break;
        }
        if (nl)
            lines ~= s[0 .. nl];
        s = s[nl + 1 .. $];
    }
    return lines;
}

ptrdiff_t indexOf(const(char)[] s, char c)
{
    foreach (i, ch; s)
        if (ch == c)
            return i;
    return -1;
}
