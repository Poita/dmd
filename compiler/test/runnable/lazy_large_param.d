// Lazy parameters of large aggregate types are passed as delegates.
struct Big { long[10] a; }
struct Small { long a; }

Big make(int n) { Big b; b.a[] = n; if (n < 0) throw new Exception("neg"); return b; }

long force(lazy Big e, string msg = null) { return e.a[3]; }
long forceSmall(lazy Small e) { return e.a; }
bool throws(lazy Big e, string msg = null, string file = __FILE__, size_t line = __LINE__)
{
    try e();
    catch (Exception) return true;
    return false;
}

void main()
{
    assert(force(make(4)) == 4);
    assert(forceSmall(Small(9)) == 9);
    assert(throws(make(-1)));
    assert(!throws(make(1)));
}
