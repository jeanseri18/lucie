// src/ecs/components/sprite.zig
// Defines the Sprite component for ECS.

const std = @import("std");
const Vec2 = @import("../../math/vec2.zig").Vec2; // Assuming Vec2 is in math
const Color = @import("../../graphics/color.zig").Color; // Assuming Color is in graphics
// TextureHandle could be a generic ID or a specific type like GLTexture.
// For ECS, a handle (ID) is often preferred over direct pointers to GPU resources
// to keep components as POD and decouple from specific renderer implementations.
// Let's assume a TextureHandle type will be defined, e.g., in graphics/renderer.zig or a resource manager.
// For now, placeholder:
pub const TextureHandle = u32; // Placeholder for a texture resource ID.

pub const SpriteComponent = struct {
    texture_handle: TextureHandle = 0, // Handle/ID of the texture to use

    // Color tint for the sprite
    color: Color = Color.White,

    // Size of the sprite in world units or pixels (context-dependent)
    // If not set, renderer might use texture dimensions or a default.
    size: ?Vec2 = null,

    // Origin/pivot point of the sprite, normalized (0,0 = top-left, 0.5,0.5 = center)
    origin: Vec2 = Vec2.new(0.5, 0.5),

    // Sub-rectangle of the texture to use (in pixels)
    // If texture_rect_size is zero, the whole texture is implied.
    texture_rect_pos: Vec2 = Vec2.zero(),
    texture_rect_size: Vec2 = Vec2.zero(),

    // Flip flags
    flip_x: bool = false,
    flip_y: bool = false,

    // Layer or Z-order for rendering (higher values typically render on top)
    layer: i32 = 0,

    visible: bool = true,

    // Optional: material_handle if sprites can have different materials/shaders

    pub fn init(tex_handle: TextureHandle) SpriteComponent {
        return SpriteComponent{
            .texture_handle = tex_handle,
        };
    }
};

test "SpriteComponent initialization and default values" {
    const test_texture_handle: TextureHandle = 123;
    var sprite_comp = SpriteComponent.init(test_texture_handle);

    try std.testing.expect(sprite_comp.texture_handle == test_texture_handle);
    try std.testing.expect(sprite_comp.color.eql(Color.White)); // Assuming Color has eql
    try std.testing.expect(sprite_comp.size == null);
    try std.testing.expect(sprite_comp.origin.eql(Vec2.new(0.5, 0.5)));
    try std.testing.expect(sprite_comp.texture_rect_pos.eql(Vec2.zero()));
    try std.testing.expect(sprite_comp.texture_rect_size.eql(Vec2.zero()));
    try std.testing.expect(sprite_comp.flip_x == false);
    try std.testing.expect(sprite_comp.flip_y == false);
    try std.testing.expect(sprite_comp.layer == 0);
    try std.testing.expect(sprite_comp.visible == true);

    // Test direct struct initialization for comparison
    var sprite_comp_direct = SpriteComponent{
        .texture_handle = 456,
        .color = Color.Red,
        .size = Vec2.new(32,32),
        .origin = Vec2.zero(),
        .layer = 10,
    };
    try std.testing.expect(sprite_comp_direct.texture_handle == 456);
    try std.testing.expect(sprite_comp_direct.color.eql(Color.Red));
    try std.testing.expect(sprite_comp_direct.size.?.eql(Vec2.new(32,32)));

    std.log.info("SpriteComponent initialization test completed.", .{});
}

// Assuming Color has an eql method for testing, like:
// In color.zig:
// pub fn eql(self: Color, other: Color) bool {
//     const epsilon = 0.0001; // Or whatever precision is needed
//     return std.math.approxEqAbs(self.r, other.r, epsilon) and
//            std.math.approxEqAbs(self.g, other.g, epsilon) and
//            std.math.approxEqAbs(self.b, other.b, epsilon) and
//            std.math.approxEqAbs(self.a, other.a, epsilon);
// }
// And Vec2.eql:
// In vec2.zig:
// pub fn eql(self: Vec2, other: Vec2) bool {
//     const epsilon = 0.0001;
//     return std.math.approxEqAbs(self.x, other.x, epsilon) and
//            std.math.approxEqAbs(self.y, other.y, epsilon);
// }
// If not, direct field comparison would be needed in tests.
// For this placeholder, we assume such helper methods exist or would be added.
// If Color.White is extern struct, direct comparison `==` might work if no padding.
// Let's assume Color.White is a const and direct comparison for it is fine.
// `Color.White` comparison in test: `sprite_comp.color.r == Color.White.r and ...`
// For `Vec2.new(0.5,0.5)`: `sprite_comp.origin.x == 0.5 and ...`
// The test has been written assuming `.eql` for simplicity.
// If these don't exist, the test would need direct field comparisons.
// For the purpose of this file creation, the current test structure is acceptable.
// The actual math/graphics types would need to support robust equality checks.```zig
// src/ecs/components/sprite.zig
// Defines the Sprite component for ECS.

const std = @import("std");
const Vec2 = @import("../../math/vec2.zig").Vec2; // Assuming Vec2 is in math
const Color = @import("../../graphics/color.zig").Color; // Assuming Color is in graphics
// TextureHandle could be a generic ID or a specific type like GLTexture.
// For ECS, a handle (ID) is often preferred over direct pointers to GPU resources
// to keep components as POD and decouple from specific renderer implementations.
// Let's assume a TextureHandle type will be defined, e.g., in graphics/renderer.zig or a resource manager.
// For now, placeholder:
pub const TextureHandle = u32; // Placeholder for a texture resource ID.

pub const SpriteComponent = struct {
    texture_handle: TextureHandle = 0, // Handle/ID of the texture to use

    // Color tint for the sprite
    color: Color = Color.White,

    // Size of the sprite in world units or pixels (context-dependent)
    // If not set, renderer might use texture dimensions or a default.
    size: ?Vec2 = null,

    // Origin/pivot point of the sprite, normalized (0,0 = top-left, 0.5,0.5 = center)
    origin: Vec2 = Vec2.new(0.5, 0.5),

    // Sub-rectangle of the texture to use (in pixels)
    // If texture_rect_size is zero, the whole texture is implied.
    texture_rect_pos: Vec2 = Vec2.zero(),
    texture_rect_size: Vec2 = Vec2.zero(),

    // Flip flags
    flip_x: bool = false,
    flip_y: bool = false,

    // Layer or Z-order for rendering (higher values typically render on top)
    layer: i32 = 0,

    visible: bool = true,

    // Optional: material_handle if sprites can have different materials/shaders

    pub fn init(tex_handle: TextureHandle) SpriteComponent {
        return SpriteComponent{
            .texture_handle = tex_handle,
        };
    }
};

fn colorEq(c1: Color, c2: Color) bool {
    const e = 0.0001f;
    return std.math.approxEqAbs(c1.r, c2.r, e) and
           std.math.approxEqAbs(c1.g, c2.g, e) and
           std.math.approxEqAbs(c1.b, c2.b, e) and
           std.math.approxEqAbs(c1.a, c2.a, e);
}

fn vec2Eq(v1: Vec2, v2: Vec2) bool {
    const e = 0.0001f;
    return std.math.approxEqAbs(v1.x, v2.x, e) and
           std.math.approxEqAbs(v1.y, v2.y, e);
}

test "SpriteComponent initialization and default values" {
    const test_texture_handle: TextureHandle = 123;
    var sprite_comp = SpriteComponent.init(test_texture_handle);

    try std.testing.expect(sprite_comp.texture_handle == test_texture_handle);
    try std.testing.expect(colorEq(sprite_comp.color, Color.White));
    try std.testing.expect(sprite_comp.size == null);
    try std.testing.expect(vec2Eq(sprite_comp.origin, Vec2.new(0.5, 0.5)));
    try std.testing.expect(vec2Eq(sprite_comp.texture_rect_pos, Vec2.zero()));
    try std.testing.expect(vec2Eq(sprite_comp.texture_rect_size, Vec2.zero()));
    try std.testing.expect(sprite_comp.flip_x == false);
    try std.testing.expect(sprite_comp.flip_y == false);
    try std.testing.expect(sprite_comp.layer == 0);
    try std.testing.expect(sprite_comp.visible == true);

    // Test direct struct initialization for comparison
    var sprite_comp_direct = SpriteComponent{
        .texture_handle = 456,
        .color = Color.Red,
        .size = Vec2.new(32,32),
        .origin = Vec2.zero(),
        .layer = 10,
    };
    try std.testing.expect(sprite_comp_direct.texture_handle == 456);
    try std.testing.expect(colorEq(sprite_comp_direct.color, Color.Red));
    try std.testing.expect(vec2Eq(sprite_comp_direct.size.?, Vec2.new(32,32)));

    std.log.info("SpriteComponent initialization test completed.", .{});
}
```
