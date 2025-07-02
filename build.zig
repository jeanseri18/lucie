// build.zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "lucie",
        .root_source_file = .{ .path = "src/lucie.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add the generated OpenGL bindings as a module
    const gl_module = b.addModule("gl", .{
        .source_file = .{ .path = "src/graphics/opengl/gl.zig" },
    });
    lib.addModule("gl", gl_module);

    // Miniaudio dependency removed due to download issues.
    // Will use a placeholder audio engine for now.

    // GLFW dependency removed due to download issues.
    // Will use a placeholder Window interface for now.

    b.installArtifact(lib);

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/lucie.zig" },
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
