pub const zl = @import("./zig_lib/zig_lib.zig");

pub const Builder = zl.build.GenericBuilder(.{});
const Node = Builder.Node;

const build_cmd: zl.build.BuildCommand = .{
    .kind = .exe,
    .mode = .ReleaseSmall,
    .strip = true,
    .compiler_rt = false,
};

pub fn buildMain(allocator: *zl.build.Allocator, toplevel: *Node) !void {
    const treez: *Node = toplevel.addBuild(allocator, build_cmd, "treez", "./src/main.zig");
    const zl_treez: *Node = toplevel.addBuild(allocator, build_cmd, "zl_treez", "./zig_lib/examples/treez.zig");
    treez.descr = "List contents of directories in a tree-like format";
    zl_treez.descr = "List contents of directories in a tree-like format, but faster";
}
