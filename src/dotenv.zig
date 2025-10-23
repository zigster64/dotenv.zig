const std = @import("std");
const builtin = @import("builtin");

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
        var buf: [1024]u8 = undefined;
        var reader = file.reader(&buf);
        while (parse(&reader.interface, '\n')) |slice| {
            const line = std.mem.trimEnd(u8, slice, "\r");
            // ignore commented out lines
            if (line.len > 0 and line[0] == '#') {
                continue;
            }
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

fn parse(r: *std.io.Reader, delimiter: u8) ?[]u8 {
    // https://github.com/ziglang/zig/issues/25597#issuecomment-3410445340
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor == 15 and builtin.zig_version.patch == 1) {
        return std.io.Reader.takeDelimiterExclusive(r, delimiter) catch null;
    } else {
        return std.io.Reader.takeDelimiter(r, delimiter) catch null;
    }
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
    try testing.expectEqual(null, expanded_env.get("VALUE4"));
}
