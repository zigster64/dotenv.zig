const std = @import("std");
const builtin = @import("builtin");

const testing = std.testing;
const Allocator = std.mem.Allocator;
const Self = @This();

map: std.process.Environ.Map = undefined,

pub fn init(allocator: Allocator, io: std.Io, filename: ?[]const u8) !Self {
    var map: std.process.Environ.Map = undefined;
    if (builtin.os.tag == .windows) {
        map = try std.process.Environ.createMapWide(std.os.windows.peb().ProcessParameters.Environment, allocator);
    } else if (builtin.os.tag == .wasi and !builtin.link_libc) {
        map = try std.process.Environ.createMap(.{ .block = {} }, allocator);
    } else {
        const env_ptr: [*:null]?[*:0]const u8 = @ptrCast(std.c.environ);
        const env_slice = std.mem.span(env_ptr);
        map = try std.process.Environ.createMap(.{ .block = env_slice }, allocator);
    }

    if (filename) |f| {
        var file = std.Io.Dir.cwd().openFile(io, f, .{}) catch {
            return .{ .map = map };
        };
        defer file.close(io);
        var buf: [1024]u8 = undefined;
        var reader = file.reader(io, &buf);
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

fn parse(r: *std.Io.Reader, delimiter: u8) ?[]u8 {
    return r.takeDelimiter(delimiter) catch null;
}

pub fn deinit(self: *Self) void {
    self.map.deinit();
}

pub fn get(self: Self, key: []const u8) ?[]const u8 {
    return self.map.get(key);
}

pub fn getInt(self: Self, comptime T: type, key: []const u8) !?T {
    const string_value = self.map.get(key);
    if (string_value) |str| {
        return try std.fmt.parseInt(T, str, 10);
    }
    return null;
}

pub fn put(self: *Self, key: []const u8, value: []const u8) !void {
    return self.map.put(key, value);
}

test "load an env file" {
    const io = std.Io.Threaded.global_single_threaded.io();
    var basic_env = try Self.init(testing.allocator, io, null);
    defer basic_env.deinit();
    const basic_env_count = basic_env.map.count();

    const test_filename = "test.env";
    {
        var file = try std.Io.Dir.cwd().createFile(io, test_filename, .{});
        defer file.close(io);
        try file.writeStreamingAll(io, "TEST_ENV_KEY=123\n");
    }
    defer std.Io.Dir.cwd().deleteFile(io, test_filename) catch {};

    var expanded_env = try Self.init(testing.allocator, io, test_filename);
    defer expanded_env.deinit();
    const expanded_env_count = expanded_env.map.count();

    // Only check count if the key wasn't already there (it shouldn't be)
    if (basic_env.get("TEST_ENV_KEY") == null) {
        try testing.expectEqual(basic_env_count + 1, expanded_env_count);
    }
    try testing.expectEqualStrings("123", expanded_env.get("TEST_ENV_KEY").?);

    if (try basic_env.getInt(u8, "TEST_ENV_KEY")) |parsed_key| {
        try testing.expectEqual(parsed_key, 123);
    }
}
