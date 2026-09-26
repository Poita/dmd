/**
 * Split the semantic3, inlining and code generation of the root modules across
 * forked worker processes.
 *
 * After semantic2 the original process forks worker processes, which take the
 * modules one at a time, largest first, and carry on compiling the modules they take.
 * Each worker writes its output (an object file or a library) with a part suffix, and
 * the original process waits for the workers and combines the parts into the requested
 * output. Declarations are fully analyzed before the split, so every worker sees the
 * same symbols; a template instance can end up generated in more than one part, which
 * is harmless as template instances are weak definitions.
 *
 * Copyright:   Copyright (C) 1999-2026 by The D Language Foundation, All Rights Reserved
 * License:     $(LINK2 https://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module dmd.parallel;

import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;

import dmd.arraytypes;
import dmd.dmodule;
import dmd.globals;
import dmd.root.filename;

version (Posix)
{
    import core.sys.posix.sys.mman : mmap, MAP_ANON, MAP_FAILED, MAP_SHARED, PROT_READ, PROT_WRITE;
    import core.sys.posix.sys.types : pid_t;
    import core.sys.posix.sys.wait : waitpid, WIFEXITED, WEXITSTATUS;
    import core.sys.posix.unistd : dup2, fork, _exit, sysconf, execvp, _SC_NPROCESSORS_ONLN;
}

/**************************************
 * In a worker, run semantic3 on the modules it takes from those not yet taken by
 * any worker, largest first, so that faster workers take more of them.
 * Params:
 *      w = the split
 *      modules = the root modules; narrowed to those this worker takes
 */
void semantic3Shared(ref Workers w, ref Modules modules) @system
{
    import core.atomic : atomicFetchAdd;
    import dmd.semantic3 : semantic3;

    auto taken = new bool[modules.length];
    while (true)
    {
        const i = atomicFetchAdd(*w.next, 1);
        if (i >= w.order.length)
            break;
        const j = w.order[i];
        taken[j] = true;
        modules[j].semantic3(null);
    }
    size_t k = 0;
    foreach (j; 0 .. modules.length)
    {
        if (taken[j])
            modules[k++] = modules[j];
        else
        {
            w.others ~= modules[j];
            w.seen ~= w.membersAtSplit[j];
        }
    }
    modules.setDim(k);
}

/**************************************
 * A template instance is added to the module declaring its template, which may be
 * one another worker compiles. Instances in the other workers' modules that this
 * worker has added since the split, or that were added before it and have completed
 * semantic analysis, are semantically analyzed here and added to this worker's first
 * module, so that it generates their code if it needs them. Which worker generates
 * the code of a template instance function is settled by `claimFunction`.
 * Params:
 *      w = the split
 *      modules = this worker's root modules
 */
void adoptForeignInstances(ref Workers w, ref Modules modules) @system
{
    import dmd.dsymbol : Dsymbol;
    import dmd.dtemplate : TemplateInstance;
    import dmd.dsymbolsem : runDeferredSemantic3;
    import dmd.semantic3 : semantic3;

    if (w.index < 0 || !modules.length)
        return;
    import dmd.dsymbol : PASS;

    TemplateInstance[] adopted;
    foreach (k, m; w.others)
    {
        if (!m.members)
            continue;
        foreach (s; (*m.members)[0 .. w.seen[k]])
        {
            if (auto ti = s.isTemplateInstance())
                if (ti.semanticRun >= PASS.semantic3)
                    adopted ~= ti;
        }
    }
    bool again = true;
    while (again)
    {
        again = false;
        foreach (k, m; w.others)
        {
            while (m.members && w.seen[k] < m.members.length)
            {
                Dsymbol s = (*m.members)[w.seen[k]++];
                if (auto ti = s.isTemplateInstance())
                {
                    semantic3(ti, null);
                    adopted ~= ti;
                    again = true;
                }
            }
        }
        runDeferredSemantic3();
    }
    foreach (ti; adopted)
        modules[0].members.push(ti);
}

nothrow:

/// The state of a compilation split across worker processes
struct Workers
{
    int index = -1;         /// in a worker, its number; -1 in the original process
    int count;              /// number of workers started, 0 if the compilation is not split
    bool succeeded;         /// in the original process: every worker wrote its output part
    shared(size_t)* next;   /// the position in `order` of the next module to take, shared by the workers
    size_t[] order;         /// indices of the root modules, largest first
    size_t[] membersAtSplit;/// the number of members of each root module when the split happened
    Module[] others;        /// in a worker: the root modules other workers take
    size_t[] seen;          /// how many members of each of `others` have been looked at

    /// Returns: true if this is a forked worker
    bool isChild() const nothrow { return index >= 0; }
}

/// Returns: the suffix added to the output file names of worker `index`
const(char)[] partSuffix(int index)
{
    char[16] buf = void;
    const n = snprintf(buf.ptr, buf.length, ".part%d", index);
    return buf[0 .. n].idup;
}

version (Posix)
{
    /* The mangled names of the template instance functions the workers generate code
     * for, in memory shared by the workers
     */
    private struct Claims
    {
        enum slotCount = 1 << 20;                   // a power of 2
        enum arenaSize = 64 << 20;
        shared(uint)[slotCount] slots;  // offset + 1 in `arena` of a claimed name, 0 if free
        shared(uint) used;              // bytes of `arena` in use
        ubyte[arenaSize] arena;         // each name as its length and its claimer, uints, then its characters
    }
    private __gshared Claims* claims;       // in a worker: the claims of all workers
    private __gshared uint workerIndex;     // in a worker: its number

    /* In a worker: where it reports its results to the original process, and how
     * many library files were listed when it started
     */
    private __gshared FILE* resultFile;
    private __gshared size_t libfilesAtSplit;
}

/**************************************
 * Split the root modules across worker processes.
 *
 * The original process forks the workers and waits for them. A worker's output
 * goes to a temporary file: a worker that prints anything (errors, warnings,
 * deprecations, messages) or fails makes the split unsuccessful, and the original
 * process, still in its state from before the split, then compiles all the modules
 * itself, so that diagnostics are exactly those of an unsplit compilation.
 * Params:
 *      modules = the root modules
 *      requested = number of workers asked for, 0 for one per processor
 * Returns:
 *      the split
 */
Workers split(ref Modules modules, uint requested)
{
    Workers w;
    version (Posix)
    {
        size_t n = requested ? requested : cast(size_t)sysconf(_SC_NPROCESSORS_ONLN);
        if (n > modules.length)
            n = modules.length;
        if (n < 2)
            return w;

        /* Workers take the largest modules first
         */
        auto order = new size_t[modules.length];
        foreach (i, ref o; order)
            o = i;
        static size_t weight(Module m) { return m.src.length + 1; }
        __gshared Module[] sortModules;
        sortModules = modules[];
        extern (C) static int cmp(const void* a, const void* b)
        {
            const wa = weight(sortModules[*cast(size_t*)a]);
            const wb = weight(sortModules[*cast(size_t*)b]);
            return wa < wb ? 1 : wa > wb ? -1 : 0;
        }
        qsort(order.ptr, order.length, size_t.sizeof, &cmp);

        void* next = mmap(null, size_t.sizeof, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANON, -1, 0);
        if (next == MAP_FAILED)
            return w;
        w.next = cast(shared(size_t)*)next;
        void* c = mmap(null, Claims.sizeof, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANON, -1, 0);
        if (c != MAP_FAILED)
            claims = cast(Claims*)c;
        w.order = order;
        foreach (m; modules)
            w.membersAtSplit ~= m.members ? m.members.length : 0;

        fflush(stdout);
        fflush(stderr);
        libfilesAtSplit = global.params.libfiles.length;
        pid_t[] children;
        FILE*[] outputs;
        FILE*[] results;
        foreach (k; 0 .. n)
        {
            FILE* output = tmpfile();
            FILE* result = tmpfile();
            if (!output || !result)
                break;
            const pid = fork();
            if (pid == -1)
                break;
            if (pid == 0)
            {
                dup2(fileno(output), 1);
                dup2(fileno(output), 2);
                resultFile = result;
                workerIndex = cast(uint)k;
                w.index = cast(int)k;
                break;
            }
            children ~= pid;
            outputs ~= output;
            results ~= result;
        }

        if (w.isChild)
        {
            w.count = cast(int)n;
            return w;
        }

        claims = null;              // the original process generates all it compiles
        w.count = cast(int)children.length;
        w.succeeded = children.length == n;
        foreach (k, pid; children)
        {
            int status;
            if (waitpid(pid, &status, 0) == -1 || !WIFEXITED(status) || WEXITSTATUS(status) != 0 ||
                fseek(outputs[k], 0, SEEK_END) != 0 || ftell(outputs[k]) != 0)
                w.succeeded = false;
            fclose(outputs[k]);
        }
        if (w.succeeded)
        {
            foreach (result; results)
                readResult(result);
        }
        foreach (result; results)
            fclose(result);
    }
    return w;
}

/**************************************
 * Settle which worker generates the code of a template instance function, which
 * any worker needing it could.
 * Params:
 *      name = the function's mangled name
 *      claim = claim the function for this worker if no worker has
 * Returns:
 *      true if this worker is to generate the function: the compilation is not split,
 *      this worker has claimed it, or no worker had and `claim` is set
 */
bool claimFunction(const(char)[] name, bool claim)
{
    version (Posix)
    {
        import core.atomic : atomicFetchAdd, atomicLoad, cas;

        if (!claims)
            return true;
        ulong h = 14695981039346656037UL;          // FNV-1a
        foreach (c; name)
        {
            h ^= c;
            h *= 1099511628211UL;
        }
        uint mine;
        foreach (probe; 0 .. Claims.slotCount)
        {
            shared(uint)* slot = &claims.slots[(h + probe) & (Claims.slotCount - 1)];
            uint v = atomicLoad(*slot);
            if (v == 0)
            {
                if (!claim)
                    return true;
                if (!mine)
                {
                    const need = cast(uint)((2 * uint.sizeof + name.length + 3) & ~3);
                    const offset = atomicFetchAdd(claims.used, need);
                    if (offset + need > Claims.arenaSize)
                        return true;            // out of space: generate it anyway
                    auto header = cast(uint*)(claims.arena.ptr + offset);
                    header[0] = cast(uint)name.length;
                    header[1] = workerIndex;
                    memcpy(claims.arena.ptr + offset + 2 * uint.sizeof, name.ptr, name.length);
                    mine = offset + 1;
                }
                if (cas(slot, 0u, mine))
                    return true;
                v = atomicLoad(*slot);
            }
            const header = cast(uint*)(claims.arena.ptr + v - 1);
            if (header[0] == name.length && memcmp(header + 2, name.ptr, name.length) == 0)
                return header[1] == workerIndex;
        }
    }
    return true;
}

/**************************************
 * End a worker once its output part is written, reporting to the original process
 * the library files it added to the link.
 */
void exitWorker(bool ok)
{
    version (Posix)
    {
        foreach (name; global.params.libfiles[libfilesAtSplit .. $])
            fwrite(name, 1, strlen(name) + 1, resultFile);
        if (fflush(resultFile) != 0)
            ok = false;
    }
    fflush(stdout);
    fflush(stderr);
    version (Posix)
        _exit(ok ? 0 : 1);
    else
        exit(ok ? 0 : 1);
}

/* Add the library files a worker reported to the link.
 */
version (Posix)
private void readResult(FILE* result)
{
    fseek(result, 0, SEEK_END);
    const size = ftell(result);
    if (size <= 0)
        return;
    auto buf = cast(char*)malloc(size);
    rewind(result);
    if (fread(buf, 1, size, result) != size)
        return;
    for (size_t i = 0; i < size; i += strlen(buf + i) + 1)
        global.params.libfiles.push(buf + i);
}

/// Returns: the names of the output parts written by `count` workers writing `file`;
/// a worker that took no modules writes none
const(char)[][] partNames(const(char)[] file, int count)
{
    const(char)[][] parts;
    foreach (k; 0 .. count)
    {
        const p = file ~ partSuffix(k);
        if (FileName.exists(p) == 1)
            parts ~= p;
    }
    return parts;
}

/// Delete output parts
void removeParts(const(char)[][] parts)
{
    foreach (p; parts)
        remove(toCString(p));
}

/**************************************
 * Combine object file parts into one object file with `ld -r`.
 * Params:
 *      objfile = the object file to write
 *      parts = the object files to combine
 * Returns:
 *      true on success
 */
bool mergeObjects(const(char)[] objfile, const(char)[][] parts)
{
    version (Posix)
    {
        const(char)*[] argv;
        argv ~= "ld";
        argv ~= "-r";
        argv ~= "-o";
        argv ~= toCString(objfile);
        foreach (p; parts)
            argv ~= toCString(p);
        argv ~= null;

        fflush(stdout);
        fflush(stderr);
        const pid = fork();
        if (pid == -1)
            return false;
        if (pid == 0)
        {
            execvp(argv[0], argv.ptr);
            _exit(127);
        }
        int status;
        return waitpid(pid, &status, 0) != -1 && WIFEXITED(status) && WEXITSTATUS(status) == 0;
    }
    else
        return false;
}

private const(char)* toCString(const(char)[] s)
{
    auto p = cast(char*)malloc(s.length + 1);
    memcpy(p, s.ptr, s.length);
    p[s.length] = 0;
    return p;
}

