module outer.pkgroot;

// a root module whose name is also the name of a package
import outer.pkgroot.sub;

int pkgrootValue() { return subValue; }
