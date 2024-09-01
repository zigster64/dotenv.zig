const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dotenv_module = b.addModule("dotenv", .{
        .root_source_file = b.path("src/dotenv.zig"),
    });
    _ = dotenv_module; // autofix

    {
        const tests = b.addTest(.{
            .root_source_file = b.path("src/dotenv.zig"),
            .target = target,
            .optimize = optimize,
        });
        const run_test = b.addRunArtifact(tests);

        const test_step = b.step("test", "Run tests");
        test_step.dependOn(&run_test.step);
    }
}
