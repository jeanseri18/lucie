// src/graphics/vertex.zig
// Defines vertex structures for rendering.

const Vec3 = @import("../math/vec3.zig").Vec3;
const Vec4 = @import("../math/vec4.zig").Vec4;
const Vec2 = @import("../math/vec2.zig").Vec2; // For UVs

// A common vertex structure. Can be expanded or specialized.
pub const VertexPNCU = struct { // Position, Normal, Color, UV
    position: Vec3,
    normal: Vec3,
    color: Vec4,
    uv: Vec2,

    // TODO: Add functions to describe vertex layout to OpenGL
    // e.g., vertexAttribPointer details for each field.
    // This is often done via a VertexArrayObject (VAO) setup.
};

// Simpler vertex for basic examples
pub const VertexPC = struct { // Position, Color
    position: Vec3,
    color: Vec4,
};


test "VertexPC structure" {
    const vp = VertexPC {
        .position = Vec3.init(1,2,3),
        .color = Vec4.init(0.5, 0.5, 0.5, 1.0),
    };
    std.debug.print("\nVertexPC: {any}\n", .{vp});
    // Basic compilation check
    _ = vp;
}

test "VertexPNCU structure" {
     const vp = VertexPNCU {
        .position = Vec3.init(1,2,3),
        .normal = Vec3.up,
        .color = Vec4.init(0.5, 0.5, 0.5, 1.0),
        .uv = Vec2.init(0,0),
    };
    std.debug.print("\nVertexPNCU: {any}\n", .{vp});
    _ = vp;
}
