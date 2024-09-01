const std = @import("std");

const Allocator = std.Allocator;
const EnvMap = std.AutoHashMap([]const u8, []const u8);
const Self = @This();

map: EnvMap = EnvMap{},
deleted: EnvMap = EnvMap{},

pub fn init(allocator: Allocator) !Self {
    _ = allocator; // autofix
    var dotenv = Self{};
    _ = dotenv; // autofix

    // read the .env file if it exists, and add each line to the map

}
