module imports.parallel_lib_a;

pragma(lib, "sqlite3");

extern (C) int sqlite3_libversion_number();
