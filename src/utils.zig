pub const Utils = struct {
    pub const USAGE = "sroll <archive_name> <root_directory>";
};

pub const FileMeta = struct {
    path_len: u32,
    basename_len: u32,
    data_len: u64,
    poiner: u64,
    path: []const u8,
    basename: []const u8,
    // TODO: TYPES AND STUFF
};