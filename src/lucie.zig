// src/lucie.zig
// Main API for the Lucie Framework

const app = @import("core/application.zig");

pub const Application = app.Application;

// Other public exports will go here
// e.g., pub const Engine = @import("core/engine.zig").Engine;
// pub const log = @import("core/logger.zig");

// Math module exports
pub const Vec2 = @import("math/vec2.zig").Vec2;
pub const Vec3 = @import("math/vec3.zig").Vec3;
pub const Vec4 = @import("math/vec4.zig").Vec4;
pub const Mat4 = @import("math/mat4.zig").Mat4;
pub const Quat = @import("math/quat.zig").Quat;

// Graphics module exports
pub const Shader = @import("graphics/shader.zig").Shader;
pub const VertexPC = @import("graphics/vertex.zig").VertexPC;
pub const VertexPNCU = @import("graphics/vertex.zig").VertexPNCU;
// Could also do: pub const vertex = @import("graphics/vertex.zig"); to export all from there.

// ... and so on for other modules
test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.popOrNull().?);
}

const std = @import("std");
