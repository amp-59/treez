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
    .enable_cache = true,
    .compiler_rt = false,
};

// zl looks for `buildMain` instead of `build` or `main`, because `main` is
// actually in build_runner.zig and might be useful for the name of one of the
// target (as below), and `build` is the name of import containing build system
// components.
pub fn buildMain(allocator: *build.Allocator, builder: *build.Builder) !void {
    _ = builder.addTarget(basic_target_spec, allocator, "treez", "./src/main.zig");
}
