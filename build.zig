//! Example build program. Use `zig_lib/support/switch_build_runner.sh` to
//! switch build runner.

// This has to be public so that the zl build runner can use the build import.
// The standard does not require this, as it is implicitly available as
// a module and can import itself from anywhere.
pub const zig_lib = @import("zig_lib/zig_lib.zig");

const spec = zig_lib.spec;
const build = zig_lib.build2;
const builtin = zig_lib.builtin;

pub const Builder: type = build.GenericBuilder(spec.builder.default);

// zl dependencies and modules:
const deps: []const build.ModuleDependency = &.{.{ .name = "zig_lib" }};
const mods: []const build.Module = &.{.{
    .name = "zig_lib",
    .path = "zig_lib/zig_lib.zig",
}};

const init = .{
    .modules = mods,
    .dependencies = deps,
    .mode = .ReleaseSmall,
    .strip = true,
    .compiler_rt = false,
};

// zl looks for `buildMain` instead of `build` or `main`, because `main` is
// actually in build_runner.zig and might be useful for the name of one of the
// target (as below), and `build` is the name of import containing build system
// components.
pub fn buildMain(allocator: *Builder.Allocator, builder: *Builder) !void {
    const all: *Builder.Group = try builder.addGroup(allocator, "all");

    const treez: *Builder.Target = try all.addTarget(allocator, init, "treez", "./src/main.zig");
    const zl_treez: *Builder.Target = try all.addTarget(allocator, init, "zl_treez", "./zig_lib/examples/treez.zig");

    treez.descr = "List contents of directories in a tree-like format";
    zl_treez.descr = "List contents of directories in a tree-like format, but faster";
    zl_treez.build_cmd.name = "treez";
}
