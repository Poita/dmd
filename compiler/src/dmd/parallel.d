/**
 * Split the semantic3, inlining and code generation of the root modules across
 * forked worker processes.
 *
 * After semantic2 the original process forks worker processes, each of which compiles
 * the root modules assigned to it: the modules are dealt out by size, largest first,
 * each to the worker with the least source so far, so the split depends only on the
 * sources and the number of workers. Each worker writes its output (an object file or
 * a library) with a part suffix, and the original process waits for the workers and
 * combines the parts, in the order of the workers, into the requested output.
 * Declarations are fully analyzed before the split, so every worker sees the same
 * symbols.
 *
 * A template instance function can be needed by more than one worker. Once their
 * modules' code is generated, the workers settle in rounds which of them generates
 * each such function: every worker publishes the ones it needs, and when all have, each
 * function goes to one of the workers needing it, chosen by its mangled name. Generating
 * those can need more, settled in the next round, until no worker needs any. What
 * each worker generates is so a function of the sources and the flags only, not of
 * how fast the workers run.
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
import dmd.dtemplate : TemplateInstance;
import dmd.func : FuncDeclaration;
import dmd.globals;
import dmd.root.filename;

version (Posix)
{
    import core.sys.posix.sys.mman : mmap, MAP_ANON, MAP_FAILED, MAP_SHARED, PROT_READ, PROT_WRITE;
    import core.sys.posix.sys.types : pid_t;
    import core.sys.posix.sys.wait : waitpid, WIFEXITED, WEXITSTATUS;
    import core.sys.posix.unistd : dup2, fork, _exit, execvp;
}

/**************************************
 * In a worker, run semantic3 on the modules assigned to it.
 * Params:
 *      w = the split
 *      modules = the root modules; narrowed to those of this worker
 */
void semantic3Assigned(ref Workers w, ref Modules modules) @system
{
    import dmd.semantic3 : semantic3;

    size_t k = 0;
    foreach (j; 0 .. modules.length)
    {
        if (w.assign[j] == w.index)
        {
            modules[j].semantic3(null);
            modules[k++] = modules[j];
        }
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
 * the code of a template instance function is settled by `generateInstanceFunction`
 * and `settleRound`.
 * Params:
 *      w = the split
 *      modules = this worker's root modules
 */
void adoptForeignInstances(ref Workers w, ref Modules modules) @system
{
    import dmd.dsymbol : PASS;

    if (w.index < 0 || !modules.length)
        return;

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
    adoptAdded(w, adopted);
    bool[void*] added;     // by identity, as frontend classes are extern(C++)
    foreach (ti; adopted)
    {
        if (cast(void*) ti in added)
            continue;
        added[cast(void*) ti] = true;
        modules[0].members.push(ti);
    }
    adopting = &w;
}

/**************************************
 * Code generation can instantiate templates too, adding the instances to the
 * modules other workers compile; this worker adopts those it has added since
 * `adoptForeignInstances` (or the last call), to generate their code itself.
 * Returns:
 *      the instances adopted, semantically analyzed; none if the compilation is not split
 */
TemplateInstance[] adoptLateInstances() @system
{
    TemplateInstance[] adopted;
    if (adopting)
        adoptAdded(*adopting, adopted);
    return adopted;
}

/* Returns: true if `ti` is a member of one of this worker's own root modules, which
 * it generates the code of as it does theirs
 */
private bool isOwnMember(ref Workers w, TemplateInstance ti)
{
    foreach (m; w.others)
        if (ti.memberOf is m)
            return false;
    return true;
}

/// The split this worker adopts instances from, once its modules have been analyzed
private __gshared Workers* adopting;

/**************************************
 * Returns: true if `m` is a root module another worker of the split compilation
 * generates the code of, after this worker's modules have been analyzed
 */
bool compiledElsewhere(const Module m) @system
{
    if (!adopting || !m)
        return false;
    foreach (o; adopting.others)
        if (o is m)
            return true;
    return false;
}

/* Semantically analyze the template instances added to the other workers' modules
 * since they were last looked at, and those of them that were speculative at the
 * split but that this worker has since needed, and append them to `adopted`.
 */
private void adoptAdded(ref Workers w, ref TemplateInstance[] adopted) @system
{
    import dmd.dsymbol : Dsymbol, PASS;
    import dmd.dsymbolsem : runDeferredSemantic3;
    import dmd.semantic3 : semantic3;

    bool again = true;
    while (again)
    {
        again = false;
        /* An instance that was speculative at the split stays in the module it
         * was added to; needing it does not add it to this worker's modules
         */
        size_t still = 0;
        foreach (ti; w.speculativeAtSplit)
        {
            if (!ti.minst)
                w.speculativeAtSplit[still++] = ti;
            else if (!isOwnMember(w, ti))
            {
                if (ti.semanticRun < PASS.semantic3)
                    semantic3(ti, null);
                adopted ~= ti;
                again = true;
            }
        }
        w.speculativeAtSplit = w.speculativeAtSplit[0 .. still];
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
}

nothrow:

/// The state of a compilation split across worker processes
struct Workers
{
    int index = -1;         /// in a worker, its number; -1 in the original process
    int count;              /// number of workers started, 0 if the compilation is not split
    bool succeeded;         /// in the original process: every worker wrote its output part
    uint[] assign;          /// the worker each root module is assigned to
    size_t[] membersAtSplit;/// the number of members of each root module when the split happened
    Module[] others;        /// in a worker: the root modules other workers compile
    size_t[] seen;          /// how many members of each of `others` have been looked at
    /// the template instances of the root modules that were speculative when the
    /// split happened, until this worker adopts them
    TemplateInstance[] speculativeAtSplit;

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

/// The most workers a compilation is split across; each is a bit of a mask
enum maxWorkers = 32;

/* The number of workers a compilation is split across when the number is not given:
 * a constant rather than the number of processors, so that the output does not
 * depend on the machine
 */
private enum autoWorkers = 8;

version (Posix)
{
    /* Mangled names of template instance functions, each with the mask of the
     * workers needing it and the worker generating it, in memory shared by the workers
     */
    private struct NameTable
    {
        enum slotCount = 1 << 20;                   // a power of 2
        enum arenaSize = 64 << 20;
        shared(uint)[slotCount] slots;  // offset + 1 in `arena` of a name, 0 if free
        shared(uint) used;              // bytes of `arena` in use
        ubyte[arenaSize] arena;         // each name as an `Entry` followed by its characters
    }

    /// A name in a `NameTable`
    private struct Entry
    {
        uint length;            // of the name
        shared(uint) need;      // the workers that need the function, a bit for each
        /* the worker generating it + 1, and the round in which that was settled shifted
         * by `roundShift`; 0 until it is settled
         */
        shared(uint) owner;
    }
    private enum roundShift = 8;

    /* Where the workers meet between the rounds of settling who generates the
     * template instance functions, in memory shared by the workers and the original
     * process
     */
    private struct Rendezvous
    {
        shared(uint) arrived;           // workers waiting for the others
        shared(uint) meetings;          // how many times all the workers have met
        shared(uint) abort;             // set when the split fails: waiting workers give up
        shared(uint)[maxWorkers] pending;   // how many functions each worker has to settle
        shared(uint)[maxWorkers] load;      // the work each worker has done, in functions
    }

    private __gshared NameTable* names;         // in a worker
    private __gshared Rendezvous* rendezvous;
    private __gshared uint workerIndex;         // in a worker: its number
    private __gshared uint workerCount;         // in a worker: the number of workers

    /* In a worker: where it reports its results to the original process, and how
     * many library files were listed when it started
     */
    private __gshared FILE* resultFile;
    private __gshared size_t libfilesAtSplit;
}

/// A template instance function whose generation waits for the workers to settle
private struct Pending
{
    FuncDeclaration fd;
    const(char)[] name;     // its mangled name
}

private __gshared Pending[] pending;    // in a worker, in the order it needed them
private __gshared bool[const(char)[]] pendingNames;
private __gshared bool[const(char)[]] generatedHere;  // the instance functions this worker generates
private __gshared bool settled;         // in a worker: no more rounds are held
private __gshared uint round;           // in a worker: the rounds held so far
private __gshared size_t needed;        // in a worker: the instance functions it has put off

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
 *      requested = number of workers asked for, 0 for as many as the amount of source
 *                  warrants
 * Returns:
 *      the split
 */
Workers split(ref Modules modules, uint requested)
{
    Workers w;
    version (Posix)
    {
        import core.atomic : atomicStore;
        import core.stdc.errno : errno, EINTR;

        size_t n = requested;
        if (!n)
        {
            /* Starting a worker costs more than compiling a little source, so by
             * default there is one worker for each `sourcePerWorker` bytes of source
             */
            enum sourcePerWorker = 128 * 1024;
            size_t total;
            foreach (m; modules)
                total += m.src.length;
            n = autoWorkers;
            if (n > total / sourcePerWorker)
                n = total / sourcePerWorker;
        }
        if (n > maxWorkers)
            n = maxWorkers;
        if (n > modules.length)
            n = modules.length;
        if (n < 2)
            return w;

        /* Deal the modules out, largest first, each to the worker with the least
         * source so far
         */
        auto order = new size_t[modules.length];
        foreach (i, ref o; order)
            o = i;
        __gshared Module[] sortModules;
        sortModules = modules[];
        extern (C) static int cmp(const void* a, const void* b)
        {
            const ia = *cast(size_t*)a, ib = *cast(size_t*)b;
            const wa = sortModules[ia].src.length, wb = sortModules[ib].src.length;
            return wa != wb ? (wa < wb ? 1 : -1) : (ia > ib) - (ia < ib);
        }
        qsort(order.ptr, order.length, size_t.sizeof, &cmp);
        w.assign = new uint[modules.length];
        auto load = new size_t[n];
        foreach (i; order)
        {
            uint least = 0;
            foreach (k; 1 .. n)
                if (load[k] < load[least])
                    least = cast(uint)k;
            w.assign[i] = least;
            load[least] += modules[i].src.length + 1;
        }

        void* r = mmap(null, Rendezvous.sizeof, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANON, -1, 0);
        void* t = mmap(null, NameTable.sizeof, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANON, -1, 0);
        if (r == MAP_FAILED || t == MAP_FAILED)
            return w;
        rendezvous = cast(Rendezvous*)r;
        names = cast(NameTable*)t;
        workerCount = cast(uint)n;
        foreach (m; modules)
        {
            w.membersAtSplit ~= m.members ? m.members.length : 0;
            if (m.members)
                foreach (s; *m.members)
                    if (auto ti = s.isTemplateInstance())
                        if (!ti.minst)
                            w.speculativeAtSplit ~= ti;
        }

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
                atexit(&leaving);
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

        names = null;               // the original process generates all it compiles
        w.count = cast(int)children.length;
        w.succeeded = children.length == n;
        if (!w.succeeded)           // the workers started would wait for the others
            atomicStore(rendezvous.abort, 1u);
        auto exited = new bool[children.length];
        foreach (_; 0 .. children.length)
        {
            int status;
            pid_t pid;
            do
                pid = waitpid(-1, &status, 0);
            while (pid == -1 && errno == EINTR);
            if (pid == -1)
            {
                w.succeeded = false;
                break;
            }
            foreach (k, c; children)
            {
                if (c != pid)
                    continue;
                exited[k] = true;
                if (!WIFEXITED(status) || WEXITSTATUS(status) != 0)
                {
                    // a worker that failed fails the split: the others need not finish
                    w.succeeded = false;
                    atomicStore(rendezvous.abort, 1u);
                }
            }
        }
        foreach (k, output; outputs)
        {
            if (!exited[k] || fseek(output, 0, SEEK_END) != 0 || ftell(output) != 0)
                w.succeeded = false;
            fclose(output);
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
 * Decide whether this process generates the code of a template instance function
 * now, which any worker of a split compilation needing it could. A worker puts off
 * the ones it needs until the workers settle who generates them (see `settleRound`).
 * Params:
 *      fd = the function
 *      name = its mangled name
 *      enclosingHere = this worker generates the code of the function `fd` is nested in,
 *                      or needs `fd` generated first to lay out the frames of others
 * Returns:
 *      true if this process is to generate the function now: the compilation is not
 *      split, this worker generates the function it is nested in, the workers settled
 *      that this worker generates it, or they settled before this worker needed it
 *      and none generates it
 */
bool generateInstanceFunction(FuncDeclaration fd, const(char)[] name, bool enclosingHere)
{
    version (Posix)
    {
        import core.atomic : atomicLoad;

        if (!names)
            return true;
        if (name in generatedHere)
            return true;
        if (enclosingHere)
        {
            generatedHere[name] = true;
            return true;
        }
        auto e = find(name, false);
        if (e && atomicLoad(e.owner))
            return false;
        if (settled)
        {
            generatedHere[name] = true;
            return true;
        }
        if (!(name in pendingNames))
        {
            pendingNames[name] = true;
            pending ~= Pending(fd, name);
            ++needed;
        }
        return false;
    }
    else
        return true;
}

/**************************************
 * In a worker, take part in a round of settling which workers generate the template
 * instance functions they have put off generating. Every worker, whether or not it has
 * any, takes part in each round, until a round in which none has any.
 *
 * Once every worker has published what it needs, each takes the same decisions: the
 * functions to settle are dealt out in the order of their mangled names, each to the
 * worker needing it that has done the least work so far.
 * Params:
 *      generated = how many functions this worker has generated so far
 *      generate = set to the functions this worker is to generate in this round
 * Returns:
 *      false if no worker had any left to settle, and no more rounds are held
 */
bool settleRound(size_t generated, out FuncDeclaration[] generate)
{
    version (Posix)
    {
        import core.atomic : atomicLoad, atomicOp, atomicStore;

        if (!names || settled)
            return false;
        // tell the others what this worker needs that is not yet settled
        size_t kept = 0;
        foreach (p; pending)
        {
            auto e = find(p.name, true);
            if (!e)
                giveUp();       // out of space: the split fails
            if (atomicLoad(e.owner))
                continue;
            atomicOp!"|="(e.need, 1u << workerIndex);
            pending[kept++] = p;
        }
        pending = pending[0 .. kept];
        atomicStore(rendezvous.pending[workerIndex], cast(uint)kept);
        /* Analyzing the template instances a worker needs is much of its work, which
         * shows in how many of their functions it needs
         */
        atomicStore(rendezvous.load[workerIndex], cast(uint)(generated + needed / 3));
        meet();
        ++round;
        size_t total = 0;
        foreach (k; 0 .. workerCount)
            total += atomicLoad(rendezvous.pending[k]);
        if (!total)
        {
            settled = true;
            return false;
        }

        /* The functions needed in this round: all those in the table not settled in an
         * earlier round, in the order of their names
         */
        static struct Need { ulong hash; const(char)[] name; Entry* e; }
        Need[] needs;
        const used = atomicLoad(names.used);
        for (size_t offset = 0; offset + Entry.sizeof <= used && offset < NameTable.arenaSize; )
        {
            auto e = cast(Entry*)(names.arena.ptr + offset);
            offset += (Entry.sizeof + e.length + 3) & ~3;
            const owner = atomicLoad(e.owner);
            if (!atomicLoad(e.need) || owner && owner >> roundShift < round)
                continue;
            const name = (cast(const(char)*)(e + 1))[0 .. e.length];
            needs ~= Need(fnv(name), name, e);
        }
        __gshared Need[] sorting;
        extern (C) static int byName(const void* a, const void* b)
        {
            auto x = cast(const Need*)a, y = cast(const Need*)b;
            if (x.hash != y.hash)
                return x.hash < y.hash ? -1 : 1;
            const n = x.name.length < y.name.length ? x.name.length : y.name.length;
            if (const c = memcmp(x.name.ptr, y.name.ptr, n))
                return c;
            return (x.name.length > y.name.length) - (x.name.length < y.name.length);
        }
        qsort(needs.ptr, needs.length, Need.sizeof, &byName);

        size_t[maxWorkers] load;
        foreach (k; 0 .. workerCount)
            load[k] = atomicLoad(rendezvous.load[k]);
        foreach (ref n; needs)
        {
            const need = atomicLoad(n.e.need);
            uint owner = uint.max;
            foreach (k; 0 .. workerCount)
                if (need & (1u << k) && (owner == uint.max || load[k] < load[owner]))
                    owner = k;
            ++load[owner];
            if (owner == workerIndex)
            {
                atomicStore(n.e.owner, round << roundShift | (owner + 1));
                generatedHere[n.name] = true;
            }
        }
        foreach (p; pending)
            if (p.name in generatedHere)
                generate ~= p.fd;
        pending = null;
        pendingNames = null;
        // no worker publishes what it needs next before all have read the needs
        meet();
        return true;
    }
    else
        return false;
}

version (Posix)
{
    /* Wait for all the workers to arrive. A worker that gives up waiting, as the
     * split has failed or the original process is gone, ends.
     */
    private void meet()
    {
        import core.atomic : atomicFetchAdd, atomicLoad, atomicStore;
        import core.sys.posix.time : nanosleep, timespec;
        import core.sys.posix.unistd : getppid;

        const meeting = atomicLoad(rendezvous.meetings);
        if (atomicFetchAdd(rendezvous.arrived, 1) + 1 == workerCount)
        {
            atomicStore(rendezvous.arrived, 0u);
            atomicStore(rendezvous.meetings, meeting + 1);
            return;
        }
        for (uint spins = 0; atomicLoad(rendezvous.meetings) == meeting; ++spins)
        {
            if (atomicLoad(rendezvous.abort) || getppid() == 1)
                giveUp();
            timespec ts = timespec(0, spins < 100 ? 20_000 : 500_000);
            nanosleep(&ts, null);
        }
    }

    /// End this worker, and with it the split
    private void giveUp()
    {
        import core.atomic : atomicStore;
        atomicStore(rendezvous.abort, 1u);
        _exit(1);
    }

    /// When a worker ends before the rounds are over, the others are not to wait for it
    private extern (C) void leaving()
    {
        import core.atomic : atomicStore;
        if (!settled)
            atomicStore(rendezvous.abort, 1u);
    }

    private ulong fnv(const(char)[] name)
    {
        ulong h = 14695981039346656037UL;          // FNV-1a
        foreach (c; name)
        {
            h ^= c;
            h *= 1099511628211UL;
        }
        return h;
    }

    /* Find `name` in the shared table, adding it if it is not there and `add` is set.
     * Returns: the name's entry, null if the name is not there and not added, or the
     * table is out of space
     */
    private Entry* find(const(char)[] name, bool add)
    {
        import core.atomic : atomicFetchAdd, atomicLoad, cas;

        const h = fnv(name);
        uint mine;
        foreach (probe; 0 .. NameTable.slotCount)
        {
            shared(uint)* slot = &names.slots[(h + probe) & (NameTable.slotCount - 1)];
            uint v = atomicLoad(*slot);
            if (v == 0)
            {
                if (!add)
                    return null;
                if (!mine)
                {
                    const need = cast(uint)((Entry.sizeof + name.length + 3) & ~3);
                    const offset = atomicFetchAdd(names.used, need);
                    if (offset + need > NameTable.arenaSize)
                        return null;
                    auto e = cast(Entry*)(names.arena.ptr + offset);
                    e.length = cast(uint)name.length;
                    memcpy(names.arena.ptr + offset + Entry.sizeof, name.ptr, name.length);
                    mine = offset + 1;
                }
                if (cas(slot, 0u, mine))
                    return cast(Entry*)(names.arena.ptr + mine - 1);
                v = atomicLoad(*slot);
            }
            auto e = cast(Entry*)(names.arena.ptr + v - 1);
            if (e.length == name.length && memcmp(e + 1, name.ptr, name.length) == 0)
                return e;
        }
        return null;
    }
}

/**************************************
 * End a worker once its output part is written, reporting to the original process
 * the library files it added to the link. A worker that has not settled with the
 * others what it generates takes part in the remaining rounds first.
 */
void exitWorker(bool ok)
{
    version (Posix)
    {
        FuncDeclaration[] generate;
        if (pending.length)
            ok = false;     // functions put off with no module left to generate them in
        while (settleRound(0, generate))
            if (generate.length)
                ok = false;
        foreach (name; global.params.libfiles[libfilesAtSplit .. $])
            fwrite(name, 1, strlen(name) + 1, resultFile);
        if (fflush(resultFile) != 0)
            ok = false;
    }
    // exit() rather than _exit(), so that an instrumented compiler writes its profile
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

