const std = @import("std");
const fs = std.fs;
const testing = std.testing;

const FileMeta = @import("./utils.zig").FileMeta;

pub const RuntimeArchive = struct {
    file: fs.File,
    data_padding: u64,

    pub fn new(file: fs.File) !RuntimeArchive {
        var my_file = file;
        try my_file.seekTo(0);

        var reader = file.reader();
        const data_padding = try reader.readInt(u64, .little);
        
        return RuntimeArchive {
            .file = my_file,
            .data_padding = data_padding,
        };
    }

    pub fn deinit(self: *RuntimeArchive) void {
        self.file.close();
    }

    pub fn getData(self: *RuntimeArchive, allocator: std.mem.Allocator, path: []const u8) !?[]const u8 {
        try self.file.seekTo(@sizeOf(u64));

        const reader = self.file.reader();

        while (try self.file.getPos() < self.data_padding) {
            var path_len: u32 = undefined;
            var basename_len: u32 = undefined;
            var data_len: u64 = undefined;
            var pointer: u64 = undefined;

            // Read metadata fields
            path_len = try reader.readInt(u32, .little);
            basename_len = try reader.readInt(u32, .little);
            data_len = try reader.readInt(u64, .little);
            pointer = try reader.readInt(u64, .little);

            // Allocate and read path and basename
            const file_path = try allocator.alloc(u8, path_len);
            defer allocator.free(file_path);
            if (try reader.readAll(file_path) != path_len) @panic("Missmatched read length and expected length!");

            const basename = try allocator.alloc(u8, basename_len);
            defer allocator.free(basename);
            if (try reader.readAll(basename) != basename_len) @panic("Missmatched read length and expected length!");

            if (std.mem.eql(u8, path, file_path)) {
                try self.file.seekTo(self.data_padding + pointer);

                const data = try allocator.alloc(u8, data_len);
                if (try reader.readAll(data) != data_len) @panic("Missmatched read length and expected length!");

                return data;
            }
        }

        return null;
    }
};

test "All" {
    const allocator = std.testing.allocator;

    const file = try fs.cwd().openFile("test_archive.scroll", .{});
    var archive = try RuntimeArchive.new(file);

    {
        const data = (try archive.getData(allocator, "a.txt")).?;
        defer allocator.free(data);
        try testing.expectEqualStrings("hello there i am human!", data);
    }

    {
        const data = (try archive.getData(allocator, "b/bb.txt")).?;
        defer allocator.free(data);
        try testing.expectEqualStrings("RUN!", data);
    }

    // {
    //     const data = (try archive.getData(allocator, "gnu.png")).?;
    //     defer allocator.free(data);
    //     for (data) |byte| {
    //         if (byte > 0xF) { std.debug.print("{X}", .{byte}); }
    //         else { std.debug.print("0{X}", .{byte}); }
    //     }
    //     std.debug.print("\n", .{});
    // }
    // check if image works (put the hex in a hex to png converter)
}