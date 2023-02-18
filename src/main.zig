const std = @import("std");
const testing = std.testing;

const c = @cImport({
    @cInclude("sqlite3ext.h");
});

////////////////////////////////////////////////////////////////////////////////////
// #if !defined(SQLITE_CORE) && !defined(SQLITE_OMIT_LOAD_EXTENSION)              //
//   /* This case when the file really is being compiled as a loadable            //
//   ** extension */                                                              //
// # define SQLITE_EXTENSION_INIT1     const sqlite3_api_routines *sqlite3_api=0; //
// # define SQLITE_EXTENSION_INIT2(v)  sqlite3_api=v;                             //
// # define SQLITE_EXTENSION_INIT3     \                                          //
//     extern const sqlite3_api_routines *sqlite3_api;                            //
// #else                                                                          //
//   /* This case when the file is being statically linked into the               //
//   ** application */                                                            //
// # define SQLITE_EXTENSION_INIT1     /*no-op*/                                  //
// # define SQLITE_EXTENSION_INIT2(v)  (void)v; /* unused parameter */            //
// # define SQLITE_EXTENSION_INIT3     /*no-op*/                                  //
// #endif                                                                         //
////////////////////////////////////////////////////////////////////////////////////
// Normal SQLite functions (ex.: create_function_v2) are taken from               //
// function pointers inside of p_api instead of globally linkable                 //
// functions.                                                                     //
////////////////////////////////////////////////////////////////////////////////////

var sqlite_api: ?*c.sqlite3_api_routines = null;

const sqlite_type = enum (c_int) {
    integer = 1,
    float = 2,
    text = 3,
    blob = 4,
    @"null" = 5,
};

export fn sqlite3_extension_init(
    db: ?*c.sqlite3,
    pz_err_msg: ?*[*:0]const u8,
    p_api: ?*c.sqlite3_api_routines
) c_int {
    _ = pz_err_msg;
    std.debug.print("Hello! Loaded!\n", .{});
    sqlite_api = p_api.?;
    const ret = sqlite_api.?.create_function_v2.?(db, "thing", -1, c.SQLITE_UTF8 | c.SQLITE_DETERMINISTIC | c.SQLITE_INNOCUOUS, null, scalarThingFunc, null, null, null);
    std.debug.print("Return value: {d}\n", .{ret});
    return c.SQLITE_OK;
}

fn scalarThingFunc(context: ?*c.sqlite3_context, argc: c_int, argv: [*c]?*c.sqlite3_value) callconv(.C) void {
    std.debug.print("Called with {d} args\n", .{argc});
    const args = argv[0..@intCast(usize, argc)];
    for (args) |arg, i| {
        const t = std.meta.intToEnum(sqlite_type, sqlite_api.?.value_type.?(arg)) catch unreachable;
        std.log.debug("Arg {d}: {}\n", .{i, t});
    }
    sqlite_api.?.result_text.?(context, "hello!!", -1, c.SQLITE_STATIC);
}
