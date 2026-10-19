module lib;

int libValue()() { return 1; }

struct Box(T)
{
    T v;
    T twice() { return v * 2; }
}

// speculatively instantiated before the root module instantiates it
enum canTwice = __traits(compiles, Box!long(1).twice());

enum banner = import("banner.txt");
