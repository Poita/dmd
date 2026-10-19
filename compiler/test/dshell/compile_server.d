// With DMD_SERVER set, a resident server keeps the modules a compilation imports loaded
// and compiles the next identical compilation on top of them. A change to a root module
// or to a string import is compiled by the server; a change to an imported module makes
// the compilation run by itself.
module test.dshell.compile_server;

import dshell;
import core.thread : Thread;
import core.time : msecs, seconds, MonoTime;
import std.algorithm : canFind, count, map;
import std.array : array, replace;
import std.conv : to;
import std.file;
import std.process : environment, execute;
import std.string : splitLines, strip;

string serverDir, src, exe;

string[] serverFiles(string ext)
{
    return dirEntries(serverDir, "*" ~ ext, SpanMode.shallow).map!(e => e.name).array;
}

string logs()
{
    string all;
    foreach (f; serverFiles(".log"))
        all ~= readText(f);
    return all;
}

/// Wait for the `n`th server to be ready
void waitForServer(size_t n)
{
    const deadline = MonoTime.currTime + 60.seconds;
    while (logs.count("ready ") < n)
    {
        assert(MonoTime.currTime < deadline, "no server started:\n" ~ logs());
        Thread.sleep(20.msecs);
    }
}

/// Compile the program, with the messages in `messages`
int build()
{
    auto f = File(OUTPUT_BASE ~ "/messages.txt", "w");
    const status = tryRun("$DMD -m$MODEL -I" ~ src ~ "/imp -J" ~ src ~ " -of" ~ exe ~ " " ~ src ~ "/app.d",
        std.stdio.stdout, f);
    f.close();
    messages = readText(OUTPUT_BASE ~ "/messages.txt");
    return status;
}

string messages;

void expectOutput(string expected)
{
    assert(build() == 0, "compilation failed:\n" ~ logs());
    const r = execute([exe]);
    assert(r.status == 0, r.output);
    assert(r.output.strip == expected, "expected `" ~ expected ~ "`, got `" ~ r.output.strip ~ "`\n" ~ logs());
    // the deprecation is reported where the module is imported
    assert(messages.canFind("app.d(2): Deprecation: module `old` is deprecated"), messages);
}

void edit(string file, string from, string to)
{
    const text = readText(file);
    assert(text.canFind(from), file);
    std.file.write(file, text.replace(from, to));
}

void stopServers()
{
    import core.sys.posix.signal : kill, SIGTERM;
    foreach (line; logs.splitLines)
        if (line.length > 6 && line[0 .. 6] == "ready ")
            kill(line[6 .. $].strip.to!int, SIGTERM);
}

int main()
{
    version (Posix) {} else return DISABLED;

    serverDir = OUTPUT_BASE ~ "/server";
    src = OUTPUT_BASE ~ "/src";
    exe = OUTPUT_BASE ~ "/app";
    foreach (d; [serverDir, src])
        if (exists(d))
            rmdirRecurse(d);
    mkdirRecurse(serverDir);
    mkdirRecurse(src ~ "/imp");
    foreach (f; ["app.d", "imp/lib.d", "imp/old.d", "imp/renamed.d", "banner.txt"])
        copy(EXTRA_FILES ~ "/compile_server/" ~ f, src ~ "/" ~ f);
    environment["DMD_SERVER"] = serverDir;
    environment.remove("DMD_SERVER_VERIFY");
    environment["DMD_SERVER_IDLE"] = "120";
    scope (exit) stopServers();

    // the first compilation records its imports, the second starts a server
    expectOutput("app1 1 6 10 b1");
    assert(serverFiles(".log").length == 0);
    expectOutput("app1 1 6 10 b1");
    waitForServer(1);

    // a change to the root module is compiled by the server
    edit(src ~ "/app.d", "app1", "app2");
    expectOutput("app2 1 6 10 b1");
    assert(logs.canFind("served 0"), logs);

    // errors reach the client
    edit(src ~ "/app.d", "tag.ptr", "tagg.ptr");
    assert(build() != 0);
    assert(messages.canFind("undefined identifier `tagg`"), messages);
    assert(logs.canFind("served 1"), logs);
    edit(src ~ "/app.d", "tagg.ptr", "tag.ptr");

    // a change to an imported module is not compiled by the stale server
    edit(src ~ "/imp/lib.d", "return 1;", "return 2;");
    expectOutput("app2 2 6 10 b1");
    assert(logs.canFind("stale"), logs);

    // a string import is read by each compilation
    waitForServer(2);
    std.file.write(src ~ "/banner.txt", "b2");
    expectOutput("app2 2 6 10 b2");
    assert(logs.count("served 0") == 2, logs);
    return 0;
}
