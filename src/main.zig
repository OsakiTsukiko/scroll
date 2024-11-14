const std = @import("std");
const fs = std.fs;
const ArrayList = std.ArrayList;

const Utils = @import("./utils.zig").Utils;
const FileMeta = @import("./utils.zig").FileMeta;

pub fn main() !u8 {
    // define allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // get arguments
    var args=  std.process.args();
    if (args.next()) |_| {} // path

    // archive file path from arguments
    const archive_filename = if (args.next()) |arg| arg else {
        std.log.err("Invalid usage: \"{s}\"", .{Utils.USAGE});
        return 1;
    };

    // directory path to be archived from arguments
    const root_directory_path = if (args.next()) |arg| arg else {
        std.log.err("Invalid usage: \"{s}\"", .{Utils.USAGE});
        return 1;
    };

    // directory Dir to be archived
    const root_directory = try fs.cwd().openDir(root_directory_path, .{ .iterate = true });

    // arrays for meta and data
    var meta_buffer = ArrayList(FileMeta).init(allocator);
    var data_buffer = ArrayList([]u8).init(allocator);

    // index to keep count of data sizes
    // while creating metas
    var data_index: u64 = 0;

    // walk through root dir
    var wlk = try root_directory.walk(allocator);
    defer wlk.deinit();

    // READING DATA

    // file walker
    while (try wlk.next()) |e| {
        if (e.kind == .file) { // ignore all non files
            const path: []const u8 = e.path;
            const basename: []const u8 = e.basename;

            // open file
            const file = try root_directory.openFile(path, .{.mode = .read_only});
            const data = try file.readToEndAlloc(allocator, 1073741824);
            defer allocator.free(data);

            std.debug.print("Load: {s}\n", .{basename});

            // create FileMeta struct
            const meta = FileMeta{
                .path_len = @as(u32, @intCast(path.len)),
                .basename_len = @as(u32, @intCast(basename.len)),
                .data_len = @as(u64, @intCast(data.len)),
                .poiner = data_index,
                .path = try allocator.dupe(u8, path),
                .basename = try allocator.dupe(u8, basename),
            };
            data_index += @as(u64, @intCast(data.len)); // increment data index

            // append meta to arraylist
            try meta_buffer.append(meta);
            // alloc copy data
            const data_copy = try allocator.dupe(u8, data);
            // append data to array list
            try data_buffer.append(data_copy);
        }
    }

    // WRITING DATA

    // open output file
    const output_file = try std.fs.cwd().createFile(
        archive_filename,
        .{ .read = true },
    );
    defer output_file.close();
    const writer = output_file.writer();

    // leave space for header_size (data padding)
    try output_file.seekTo(@sizeOf(u64));

    // write meta_buffer (array list) to file
    for (meta_buffer.items) |meta| {
        try writer.writeInt(u32, meta.path_len, .little);
        try writer.writeInt(u32, meta.basename_len, .little);
        try writer.writeInt(u64, meta.data_len, .little);
        try writer.writeInt(u64, meta.poiner, .little);
        try writer.writeAll(meta.path);
        try writer.writeAll(meta.basename);
    }
    
    // save data chunk beginning index
    const data_padding = try output_file.getPos();

    // write data chunk to file
    for (data_buffer.items) |data| {
        try writer.writeAll(data);
    }

    // write data padding at pos 0
    try output_file.seekTo(0);
    try writer.writeInt(u64, data_padding, .little);

    // free meta buffer
    for (meta_buffer.items) |meta| {
        allocator.free(meta.path);
        allocator.free(meta.basename);
    }
    meta_buffer.deinit();

    // free data buffer
    for (data_buffer.items) |data| {
        allocator.free(data);
    }
    data_buffer.deinit();

    return 0;
}