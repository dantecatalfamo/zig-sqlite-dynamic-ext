const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addSharedLibrary("zs", "src/main.zig", .unversioned);
    // const lib = b.addStaticLibrary("sqlite3-extension-zig", "src/main.zig");
    // lib.linkSystemLibrary("sqlite3");
    lib.force_pic = true;
    lib.setBuildMode(mode);
    lib.linkLibC();
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
