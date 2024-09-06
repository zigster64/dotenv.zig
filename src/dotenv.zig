const std = @import("std");

const testing = std.testing;
const Allocator = std.mem.Allocator;
const Self = @This();

map: std.process.EnvMap = undefined,

pub fn init(allocator: Allocator, filename: ?[]const u8) !Self {
    var map = try std.process.getEnvMap(allocator);

    if (filename) |f| {
        var file = std.fs.cwd().openFile(f, .{}) catch {
            return .{ .map = map };
        };

        defer file.close();
        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            // split into KEY and Value
            if (std.mem.indexOf(u8, line, "=")) |index| {
                const key = line[0..index];
                const value = line[index + 1 ..];
                try map.put(key, value);
            }
        }
    }
    return .{
        .map = map,
    };
}

pub fn deinit(self: *Self) void {
    self.map.deinit();
}

pub fn get(self: Self, key: []const u8) ?[]const u8 {
    return self.map.get(key);
}

pub fn put(self: *Self, key: []const u8, value: []const u8) !void {
    return self.map.put(key, value);
}

test "load an env file" {
    var basic_env = try Self.init(testing.allocator, null);
    defer basic_env.deinit();
    const basic_env_count = basic_env.map.count();

    var expanded_env = try Self.init(testing.allocator, ".env");
    defer expanded_env.deinit();
    const expanded_env_count = expanded_env.map.count();

    try testing.expectEqual(basic_env_count + 3, expanded_env_count);
    try testing.expectEqualStrings("1", expanded_env.get("VALUE1").?);
    try testing.expectEqualStrings("2", expanded_env.get("VALUE2").?);
    try testing.expectEqualStrings("3", expanded_env.get("VALUE3").?);
}
