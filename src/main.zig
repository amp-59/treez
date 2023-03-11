const srg = @import("zig_lib");
const lit = srg.lit;
const sys = srg.sys;
const fmt = srg.fmt;
const mem = srg.mem;
const file = srg.file;
const meta = srg.meta;
const proc = srg.proc;
const preset = srg.preset;
const thread = srg.thread;
const builtin = srg.builtin;
pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;
pub const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .lb_offset = 0x40000000,
    .divisions = 32,
    .errors = .{ .acquire = .ignore, .release = .ignore },
});
const Allocator0 = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .options = preset.allocator.options.small,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});
const Allocator1 = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 1,
    .options = preset.allocator.options.small,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});
const Array = mem.StaticString(4096);
const Array1 = Allocator1.StructuredHolder(u8);
const Array0 = Allocator0.StructuredHolder(u8);
const DirStream = file.GenericDirStream(.{
    .Allocator = Allocator0,
    .options = .{},
    .logging = preset.dir.logging.silent,
});
const Filter = meta.EnumBitField(file.Kind);
const Names = mem.StaticArray([:0]const u8, max_pathname_args);
const Results = struct {
    files: u64 = 0,
    dirs: u64 = 0,
    links: u64 = 0,
    depth: u64 = 0,
    errors: u64 = 0,
    inline fn total(results: Results) u64 {
        return results.dirs +% results.files +% results.links;
    }
};
// Config:
const plain_print: bool = false;
const print_in_second_thread: bool = true;
const use_wide_arrows: bool = false;
const always_try_empty_dir_correction: bool = false;
const max_pathname_args: u16 = 128;
//
const Options = packed struct {
    hide: bool = hide_default,
    follow: bool = follow_default,
    colour: bool = colour_default,
    results: bool = results_default,
    max_depth: u12 = max_depth_default,

    const hide_default: bool = false;
    const follow_default: bool = true;
    const colour_default: bool = true;
    const results_default: bool = true;
    const max_depth_default: u16 = 4095;

    pub const Map = proc.GenericOptions(Options);
    const yes = .{ .boolean = true };
    const no = .{ .boolean = false };
    const int = .{ .convert = convertToInt };

    fn convertToInt(options: *Options, arg: []const u8) void {
        options.max_depth = builtin.parse.ud(u8, arg);
    }
};
// zig fmt: off
const opts_map: []const Options.Map = meta.slice(proc.GenericOptions(Options), .{
    .{ .field_name = "max_depth",   .short = "-d",  .long = "--max-depth",  .assign = Options.int,  .descr = about_max_depth_s },
    if (Options.colour_default)
    .{ .field_name = "colour",      .short = "-C",  .long = "--no-color",   .assign = Options.no,   .descr = about_no_colour_s }
    else
    .{ .field_name = "colour",      .short = "-c",  .long = "--color",      .assign = Options.yes,  .descr = about_colour_s },
    if (Options.hide_default)
    .{ .field_name = "hide",                        .long = "--no-hide",    .assign = Options.no,   .descr = about_show_s }
    else
    .{ .field_name = "hide",                        .long = "--hide",       .assign = Options.yes,  .descr = about_no_show_s },
    if (Options.hide_default)
    .{ .field_name = "follow",     .short = "-l",   .long = "--no-follow",  .assign = Options.no,   .descr = about_no_follow_s }
    else
    .{ .field_name = "follow",     .short = "-L",   .long = "--follow",     .assign = Options.yes,  .descr = about_follow_s },
    if (Options.results_default)
    .{ .field_name = "results",                     .long = "--no-results", .assign = Options.no,   .descr = about_no_results_s }
    else
    .{ .field_name = "results",                     .long = "--results",    .assign = Options.yes,  .descr = about_results_s },

}); // zig fmt: on
const map_spec: thread.MapSpec = .{
    .errors = .{},
    .options = .{},
};
const thread_spec: proc.CloneSpec = .{
    .errors = .{},
    .options = .{},
    .return_type = u64,
};
const about_max_depth_s: [:0]const u8 = "limit the maximum depth of recursion";
const about_show_s: [:0]const u8 = "show hidden file system objects";
const about_no_show_s: [:0]const u8 = "do not " ++ about_show_s;
const about_follow_s: [:0]const u8 = "follow symbolic links";
const about_no_follow_s: [:0]const u8 = "do not " ++ about_follow_s;
const about_colour_s: [:0]const u8 = "print directory entries with color";
const about_no_colour_s: [:0]const u8 = "print directory entries without color";
const about_results_s: [:0]const u8 = "show results";
const about_no_results_s: [:0]const u8 = "do not " ++ about_results_s;

const what_s: [:0]const u8 = "???";
const endl_s: [:0]const u8 = "\x1b[0m\n";
const del_s: [:0]const u8 = "\x08\x08\x08\x08";
const spc_bs: [:0]const u8 = "    ";
const spc_ws: [:0]const u8 = "    ";
const bar_bs: [:0]const u8 = "|   ";
const bar_ws: [:0]const u8 = "│   ";
const links_to_bs: [:0]const u8 = " --> ";
const links_to_ws: [:0]const u8 = " ⟶  ";
const file_arrow_bs: [:0]const u8 = del_s ++ "|-> ";
const file_arrow_ws: [:0]const u8 = del_s ++ "├── ";
const last_file_arrow_bs: [:0]const u8 = del_s ++ "`-> ";
const last_file_arrow_ws: [:0]const u8 = del_s ++ "└── ";
const link_arrow_bs: [:0]const u8 = file_arrow_bs;
const link_arrow_ws: [:0]const u8 = file_arrow_ws;
const last_link_arrow_bs: [:0]const u8 = last_file_arrow_bs;
const last_link_arrow_ws: [:0]const u8 = last_file_arrow_ws;
const dir_arrow_bs: [:0]const u8 = del_s ++ "|---+ ";
const dir_arrow_ws: [:0]const u8 = del_s ++ "├───┬ ";
const last_dir_arrow_bs: [:0]const u8 = del_s ++ "`---+ ";
const last_dir_arrow_ws: [:0]const u8 = del_s ++ "└───┬ ";
const empty_dir_arrow_bs: [:0]const u8 = del_s ++ "|-- ";
const empty_dir_arrow_ws: [:0]const u8 = del_s ++ "├── ";
const last_empty_dir_arrow_bs: [:0]const u8 = del_s ++ "`-- ";
const last_empty_dir_arrow_ws: [:0]const u8 = del_s ++ "└── ";
const about_dirs_s: [:0]const u8 = "dirs:           ";
const about_files_s: [:0]const u8 = "files:          ";
const about_links_s: [:0]const u8 = "links:          ";
const about_depth_s: [:0]const u8 = "depth:          ";
const about_errors_s: [:0]const u8 = "errors:         ";
const spc_s: [:0]const u8 = if (use_wide_arrows) spc_ws else spc_bs;
const bar_s: [:0]const u8 = if (use_wide_arrows) bar_ws else bar_bs;
const links_to_s: [:0]const u8 = if (use_wide_arrows) links_to_ws else links_to_bs;
const file_arrow_s: [:0]const u8 = if (use_wide_arrows) file_arrow_ws else file_arrow_bs;
const last_file_arrow_s: [:0]const u8 = if (use_wide_arrows) last_file_arrow_ws else last_file_arrow_bs;
const link_arrow_s: [:0]const u8 = if (use_wide_arrows) file_arrow_ws else file_arrow_bs;
const last_link_arrow_s: [:0]const u8 = if (use_wide_arrows) last_file_arrow_ws else last_file_arrow_bs;
const dir_arrow_s: [:0]const u8 = if (use_wide_arrows) dir_arrow_ws else dir_arrow_bs;
const last_dir_arrow_s: [:0]const u8 = if (use_wide_arrows) last_dir_arrow_ws else last_dir_arrow_bs;
const empty_dir_arrow_s: [:0]const u8 = if (use_wide_arrows) empty_dir_arrow_ws else empty_dir_arrow_bs;
const last_empty_dir_arrow_s: [:0]const u8 = if (use_wide_arrows) last_empty_dir_arrow_ws else last_empty_dir_arrow_bs;
const no_colour: [:0]const u8 = "";
var directory_style: [:0]const u8 = if (Options.colour_default) lit.fx.style.bold else no_colour;
var symbolic_link_style: [:0]const u8 = if (Options.colour_default) lit.fx.color.fg.hi_cyan else no_colour;
var regular_style: [:0]const u8 = if (Options.colour_default) lit.fx.color.fg.yellow else no_colour;
var block_special_style: [:0]const u8 = if (Options.colour_default) lit.fx.color.fg.orange else no_colour;
var character_special_style: [:0]const u8 = if (Options.colour_default) lit.fx.color.fg.hi_yellow else no_colour;
var named_pipe_style: [:0]const u8 = if (Options.colour_default) lit.fx.color.fg.magenta else no_colour;
var socket_style: [:0]const u8 = if (Options.colour_default) lit.fx.color.fg.hi_magenta else no_colour;
comptime {
    if (builtin.zig.mode == .Debug and print_in_second_thread) @compileError("unstable configuration");
}
fn colour(kind: file.Kind) [:0]const u8 {
    switch (kind) {
        .regular => return regular_style,
        .directory => return directory_style,
        .symbolic_link => return symbolic_link_style,
        .block_special => return block_special_style,
        .character_special => return character_special_style,
        .named_pipe => return named_pipe_style,
        .socket => return socket_style,
    }
}
fn show(results: Results) void {
    var array: Array = .{};
    array.writeMany(about_dirs_s);
    array.writeFormat(fmt.udh(results.dirs));
    array.writeOne('\n');
    array.writeMany(about_files_s);
    array.writeFormat(fmt.udh(results.files));
    array.writeOne('\n');
    array.writeMany(about_links_s);
    array.writeFormat(fmt.udh(results.links));
    array.writeOne('\n');
    array.writeMany(about_depth_s);
    array.writeFormat(fmt.udh(results.depth));
    array.writeOne('\n');
    array.writeMany(about_errors_s);
    array.writeFormat(fmt.udh(results.errors));
    array.writeOne('\n');
    file.write(.{ .errors = .{} }, 1, array.readAll());
}
inline fn printIfNAvail(comptime n: usize, allocator: Allocator1, array: Array1, offset: u64) u64 {
    const many: []const u8 = array.readManyAt(allocator, offset);
    if (many.len > (n -% 1)) {
        if (n == 1) {
            file.write(.{ .errors = .{} }, 1, many);
            return many.len;
        } else if (many[many.len -% 1] == '\n') {
            file.write(.{ .errors = .{} }, 1, many);
            return many.len;
        }
    }
    return 0;
}
noinline fn printAlong(results: *volatile Results, done: *bool, allocator: *Allocator1, array: *Array1) void {
    var offset: u64 = 0;
    while (true) {
        offset +%= printIfNAvail(4096, allocator.*, array.*, offset);
        if (done.*) break;
    }
    while (offset != array.len(allocator.*)) {
        offset +%= printIfNAvail(1, allocator.*, array.*, offset);
    }
    show(results.*);
    done.* = false;
}
inline fn getNames(args: [][*:0]u8) Names {
    var names: Names = .{};
    var i: u64 = 1;
    while (i != args.len) : (i +%= 1) {
        names.writeOne(meta.manyToSlice(args[i]));
    }
    return names;
}
fn conditionalSkip(entry_name: []const u8) bool {
    return entry_name[0] == '.' or
        mem.testEqualMany(u8, "zig-cache", entry_name) or
        mem.testEqualMany(u8, "zig-out", entry_name);
}
fn writeReadLink(
    allocator_1: *Allocator1,
    array: *Array1,
    link_buf: *Array,
    results: *Results,
    dir_fd: u64,
    base_name: [:0]const u8,
) !void {
    const buf: []u8 = link_buf.referManyUndefined(4096);
    const link_pathname: [:0]const u8 = file.readLinkAt(.{}, dir_fd, base_name, buf) catch {
        results.errors +%= 1;
        return array.appendAny(preset.reinterpret.ptr, allocator_1, .{ what_s, endl_s });
    };
    array.appendAny(preset.reinterpret.ptr, allocator_1, .{ link_pathname, endl_s });
}
fn writeAndWalkPlain(
    options: *const Options,
    allocator_0: *Allocator0,
    allocator_1: *Allocator1,
    array: *Array1,
    alts_buf: *Array,
    link_buf: *Array,
    results: *Results,
    dir_fd: ?u64,
    name: [:0]const u8,
    depth: u64,
) !void {
    const need_separator: bool = name[name.len -% 1] != '/';
    alts_buf.writeMany(name);
    if (need_separator) alts_buf.writeOne('/');
    defer alts_buf.undefine(name.len + builtin.int(u64, need_separator));
    var dir: DirStream = try DirStream.initAt(allocator_0, dir_fd, name);
    defer dir.deinit(allocator_0);
    var list: DirStream.ListView = dir.list();
    var index: u64 = 1;
    while (list.at(index)) |entry| : (index +%= 1) {
        const basename: [:0]const u8 = entry.name();
        if (options.hide and conditionalSkip(basename)) {
            continue;
        }
        switch (entry.kind()) {
            .symbolic_link => {
                results.links +%= 1;
                const style_0_s: [:0]const u8 = directory_style;
                const style_1_s: [:0]const u8 = symbolic_link_style;
                if (options.follow) {
                    array.appendAny(preset.reinterpret.ptr, allocator_1, .{ style_0_s, alts_buf.readAll(), style_1_s, basename, links_to_s });
                    try writeReadLink(allocator_1, array, link_buf, results, dir.fd, basename);
                } else {
                    array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), basename, endl_s });
                }
            },
            .regular, .character_special, .block_special, .named_pipe, .socket => {
                results.files +%= 1;
                const style_0_s: [:0]const u8 = directory_style;
                const style_1_s: [:0]const u8 = colour(entry.kind());
                array.appendAny(preset.reinterpret.ptr, allocator_1, .{ style_0_s, alts_buf.readAll(), style_1_s, basename, endl_s });
            },
            .directory => {
                results.dirs +%= 1;
                const style_s: [:0]const u8 = directory_style;
                array.appendAny(preset.reinterpret.ptr, allocator_1, .{ style_s, alts_buf.readAll(), basename, endl_s });
                if (depth != options.max_depth) {
                    results.depth = builtin.max(u64, results.depth, depth +% 1);
                    writeAndWalkPlain(options, allocator_0, allocator_1, array, alts_buf, link_buf, results, dir.fd, basename, depth +% 1) catch {
                        results.errors +%= 1;
                    };
                }
            },
        }
    }
}
fn writeAndWalk(
    options: *const Options,
    allocator_0: *Allocator0,
    allocator_1: *Allocator1,
    array: *Array1,
    alts_buf: *Array,
    link_buf: *Array,
    results: *Results,
    dir_fd: ?u64,
    name: [:0]const u8,
    depth: u64,
) !void {
    const try_empty_dir_correction: bool = always_try_empty_dir_correction or use_wide_arrows;
    var dir: DirStream = try DirStream.initAt(allocator_0, dir_fd, name);
    defer dir.deinit(allocator_0);
    var list: DirStream.ListView = dir.list();
    var index: u64 = 1;
    while (list.at(index)) |entry| : (index +%= 1) {
        const basename: [:0]const u8 = entry.name();
        const last: bool = index == list.count -% 1;
        if (options.hide and conditionalSkip(basename)) {
            continue;
        }
        const indent: []const u8 = if (last) spc_s else bar_s;
        alts_buf.writeMany(indent);
        defer alts_buf.undefine(indent.len);
        const style_s: [:0]const u8 = colour(entry.kind());
        switch (entry.kind()) {
            .symbolic_link => {
                results.links +%= 1;
                if (options.follow) {
                    const arrow_s: [:0]const u8 = if (last) last_link_arrow_s else link_arrow_s;
                    array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, style_s, basename, links_to_s });
                    try writeReadLink(allocator_1, array, link_buf, results, dir.fd, basename);
                } else {
                    const arrow_s: [:0]const u8 = if (last) last_link_arrow_s else link_arrow_s;
                    array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, style_s, basename, endl_s });
                }
            },
            .regular, .character_special, .block_special, .named_pipe, .socket => {
                results.files +%= 1;
                const arrow_s: [:0]const u8 = if (last) last_file_arrow_s else file_arrow_s;
                array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, style_s, basename, endl_s });
            },
            .directory => {
                results.dirs +%= 1;
                var arrow_s: [:0]const u8 = if (last) last_dir_arrow_s else dir_arrow_s;
                const len_0: u64 = array.len(allocator_1.*);
                try meta.wrap(array.appendAny(preset.reinterpret.ptr, allocator_1, .{ alts_buf.readAll(), arrow_s, basename, endl_s }));
                if (depth != options.max_depth) {
                    results.depth = builtin.max(u64, results.depth, depth +% 1);
                    const en_total: u64 = results.total();
                    writeAndWalk(options, allocator_0, allocator_1, array, alts_buf, link_buf, results, dir.fd, basename, depth +% 1) catch {
                        results.errors +%= 1;
                    };
                    const ex_total: u64 = results.total();
                    if (try_empty_dir_correction) {
                        arrow_s = if (index == list.count -% 1) last_empty_dir_arrow_s else empty_dir_arrow_s;
                        if (en_total == ex_total) {
                            array.undefine(array.len(allocator_1.*) -% len_0);
                            array.writeAny(preset.reinterpret.ptr, .{ alts_buf.readAll(), arrow_s, basename, endl_s });
                        }
                    }
                }
            },
        }
    }
}
pub fn main(args: [][*:0]u8) !void {
    var args_in: [][*:0]u8 = args;
    var address_space: AddressSpace = .{};
    const options: Options = proc.getOpts(Options, &args_in, opts_map);
    var names: Names = getNames(args_in);
    if (Options.colour_default != options.colour) {
        directory_style = if (!Options.colour_default) lit.fx.style.bold else no_colour;
        symbolic_link_style = if (!Options.colour_default) lit.fx.color.fg.hi_cyan else no_colour;
        regular_style = if (!Options.colour_default) lit.fx.color.fg.yellow else no_colour;
        block_special_style = if (!Options.colour_default) lit.fx.color.fg.orange else no_colour;
        character_special_style = if (!Options.colour_default) lit.fx.color.fg.hi_yellow else no_colour;
        named_pipe_style = if (!Options.colour_default) lit.fx.color.fg.magenta else no_colour;
        socket_style = if (!Options.colour_default) lit.fx.color.fg.hi_magenta else no_colour;
    }
    if (names.len() == 0) {
        names.writeOne(".");
    }
    var allocator_0: Allocator0 = Allocator0.init(&address_space);
    defer allocator_0.deinit(&address_space);
    var allocator_1: Allocator1 = Allocator1.init(&address_space);
    defer allocator_1.deinit(&address_space);
    try meta.wrap(allocator_0.map(32768));
    try meta.wrap(allocator_1.map(32768));
    for (names.readAll()) |arg| {
        var results: Results = .{};
        var alts_buf: Array = undefined;
        alts_buf.undefineAll();
        var link_buf: Array = undefined;
        link_buf.undefineAll();
        var array: Array1 = Array1.init(&allocator_1);
        defer array.deinit(&allocator_1);
        try meta.wrap(array.appendMany(&allocator_1, arg));
        try meta.wrap(array.appendMany(&allocator_1, if (arg[arg.len -% 1] != '/') "/\n" else "\n"));
        if (plain_print) {
            if (print_in_second_thread) {
                var tid: u64 = undefined;
                var done: bool = false;
                const stack_addr: u64 = try meta.wrap(thread.map(map_spec, 8));
                tid = proc.callClone(thread_spec, stack_addr, {}, printAlong, .{ &results, &done, &allocator_1, &array });
                @call(.auto, if (plain_print) writeAndWalkPlain else writeAndWalk, .{
                    &options,  &allocator_0, &allocator_1, &array,
                    &alts_buf, &link_buf,    &results,     null,
                    arg,       0,
                }) catch {
                    results.errors +%= 1;
                };
                done = true;
                mem.monitor(bool, &done);
                thread.unmap(.{ .errors = .{} }, 8);
            } else {
                @call(.auto, if (plain_print) writeAndWalkPlain else writeAndWalk, .{
                    &options,  &allocator_0, &allocator_1, &array,
                    &alts_buf, &link_buf,    &results,     null,
                    arg,       0,
                }) catch {
                    results.errors +%= 1;
                };
                builtin.debug.write(array.readAll(allocator_1));
                show(results);
            }
        } else {
            alts_buf.writeMany(" " ** 4096);
            alts_buf.undefine(4096);
            if (print_in_second_thread) {
                var tid: u64 = undefined;
                var done: bool = false;
                const stack_addr: u64 = try meta.wrap(thread.map(map_spec, 8));
                tid = proc.callClone(thread_spec, stack_addr, {}, printAlong, .{ &results, &done, &allocator_1, &array });
                @call(.auto, if (plain_print) writeAndWalkPlain else writeAndWalk, .{
                    &options,  &allocator_0, &allocator_1, &array,
                    &alts_buf, &link_buf,    &results,     null,
                    arg,       0,
                }) catch {
                    results.errors +%= 1;
                };
                done = true;
                mem.monitor(bool, &done);
                thread.unmap(.{ .errors = .{} }, 8);
            } else {
                @call(.auto, if (plain_print) writeAndWalkPlain else writeAndWalk, .{
                    &options,  &allocator_0, &allocator_1, &array,
                    &alts_buf, &link_buf,    &results,     null,
                    arg,       0,
                }) catch {
                    results.errors +%= 1;
                };
                builtin.debug.write(array.readAll(allocator_1));
                show(results);
            }
        }
    }
}
