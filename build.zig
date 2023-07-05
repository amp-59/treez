pub const zl = @import("./zig_lib/zig_lib.zig");

pub const Node = zl.build.GenericNode(.{});

pub fn buildMain(allocator: *zl.build.Allocator, toplevel: *Node) !void {
    const all: *Node = try toplevel.addGroup(allocator, "all");
    const treez: *Node = try all.addBuild(
        allocator,
        .{ .kind = .exe, .mode = .ReleaseSmall, .strip = true },
        "treez",
        "./src/main.zig",
    );
    const zl_treez: *Node = try all.addBuild(
        allocator,
        .{ .kind = .exe, .mode = .ReleaseSmall, .strip = true },
        "zl_treez",
        "./zig_lib/examples/treez.zig",
    );
    treez.descr = "List contents of directories in a tree-like format";
    zl_treez.descr = "List contents of directories in a tree-like format, but faster";
    zl_treez.task.info.build.name = "treez";
}
