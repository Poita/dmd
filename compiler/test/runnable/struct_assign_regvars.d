// A struct assignment whose address registers must avoid register variables.

struct Rect { float x, y, w, h; }
struct WindowState { uint id; bool used; Rect rect; int lastFrame; int flags; int cmdStart; bool collapsed; }

uint fnv1a(string s) { uint h = 2166136261; foreach (c; s) { h ^= c; h *= 16777619; } return h; }

class Ui
{
    WindowState[16] windows;
    float uiScale = 1;
    int frame;

    bool begin(string title, int flags)
    {
        const id = fnv1a(title);
        int idx = -1, free = -1;
        foreach (i, ref w; windows)
        {
            if (w.used && w.id == id) idx = cast(int) i;
            else if (!w.used && free < 0) free = cast(int) i;
        }
        if (idx < 0)
        {
            if (free < 0) return false;
            idx = free;
            windows[idx] = WindowState.init;
            windows[idx].id = id;
            windows[idx].used = true;
            const cascade = (idx % 8) * 36.0f * uiScale;
            windows[idx].rect = Rect(60 * uiScale + cascade, 60 * uiScale + cascade, 320 * uiScale, 260 * uiScale);
        }
        auto w = &windows[idx];
        w.lastFrame = frame;
        w.flags = flags + cast(int) title.length;
        return true;
    }
}

void main()
{
    auto u = new Ui;
    assert(u.begin("abc", 1));
    assert(u.begin("xy", 2));
    assert(u.begin("abc", 3));
    assert(u.windows[0].used && u.windows[0].id == fnv1a("abc") && u.windows[0].flags == 6);
    assert(u.windows[1].rect.x == 96 && u.windows[1].flags == 4);
}
