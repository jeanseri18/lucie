// src/graphics/sprite.zig
// Sprite system: defines a sprite, potentially with animation.

const std = @import("std");
const math = @import("../math/vec2.zig"); // For Vec2
const Color = @import("color.zig").Color;
const Texture = @import("opengl/gl_texture.zig").GLTexture; // Assuming GLTexture for now, could be generic later
// Or a more generic handle: const TextureHandle = @import("renderer.zig").TextureHandle;

pub const Sprite = struct {
    texture: ?*Texture = null, // Pointer to a texture, or a handle
    // texture_handle: TextureHandle = 0, // Alternative: use handles from a resource manager

    position: math.Vec2 = math.Vec2.zero(),
    size: math.Vec2 = math.Vec2.new(1.0, 1.0), // Default size (e.g., in world units or pixels)
    rotation: f32 = 0.0, // In radians
    origin: math.Vec2 = math.Vec2.new(0.5, 0.5), // Normalized origin (0,0 top-left, 0.5,0.5 center)
    color: Color = Color.White,

    // For sprite sheets / atlases
    texture_rect_pos: math.Vec2 = math.Vec2.zero(), // Top-left corner of the sub-rectangle in texture pixels
    texture_rect_size: math.Vec2 = math.Vec2.zero(), // Size of the sub-rectangle in texture pixels. If zero, use full texture.

    // Optional: Flip flags
    flip_x: bool = false,
    flip_y: bool = false,

    // Optional: Visibility
    visible: bool = true,

    // allocator: std.mem.Allocator, // If sprite owns any allocated data

    pub fn init(
        allocator: std.mem.Allocator,
        texture_ref: ?*Texture,
        pos: math.Vec2,
        sz: math.Vec2,
    ) Sprite {
        _ = allocator; // Not used in this basic version unless sprite allocates something
        var new_sprite = Sprite {
            .texture = texture_ref,
            .position = pos,
            .size = sz,
        };
        // If a texture is provided, set texture_rect_size to its full dimensions by default
        if (texture_ref) |tex| {
            new_sprite.texture_rect_size = math.Vec2.new(@intToFloat(f32, tex.width), @intToFloat(f32, tex.height));
        }
        return new_sprite;
    }

    // Deinit if sprite allocated any resources. Not needed for this simple struct.
    // pub fn deinit(self: *Sprite) void {
    //     // self.allocator.destroy(self.some_allocated_field);
    // }

    // Getters and setters could be added here if needed for more complex logic.
    // pub fn setTexture(self: *Sprite, tex: ?*Texture) void {
    //     self.texture = tex;
    //     if (tex) |t| {
    //         // If texture_rect_size was meant to be full texture by default and not explicitly set
    //         if (self.texture_rect_size.x == 0 and self.texture_rect_size.y == 0) {
    //             self.texture_rect_size = math.Vec2.new(@intToFloat(f32, t.width), @intToFloat(f32, t.height));
    //         }
    //     } else {
    //         self.texture_rect_size = math.Vec2.zero();
    //     }
    // }

    // pub fn getTransform(self: *const Sprite) Mat4 {
    //     // Calculate and return a transformation matrix for this sprite
    //     // This would involve translation, rotation, scaling based on sprite properties.
    //     // Requires Mat4, which might be overkill if only 2D transforms are needed (Mat3).
    //     // For now, this logic is usually handled by the sprite renderer or batcher.
    //     return Mat4.identity();
    // }
};

// TODO: Add SpriteAnimation struct and related logic if animations are part of this file.
// pub const SpriteFrame = struct {
//     texture_rect_pos: math.Vec2,
//     texture_rect_size: math.Vec2,
//     duration: f32, // seconds
// };
// pub const SpriteAnimation = struct {
//     frames: std.ArrayList(SpriteFrame),
//     current_frame_index: usize = 0,
//     current_time: f32 = 0.0,
//     looping: bool = true,
//     // ...
// };


test "Sprite initialization" {
    const allocator = std.testing.allocator;

    // Create a dummy texture for testing (if GLTexture had a simpler init or mock)
    // For now, we'll pass null, as GLTexture creation is complex for a unit test here.
    // In a real test setup, you might have a mock texture or a way to get a test texture.
    var mock_texture_storage: Texture = undefined; // This is not ideal, just for pointer validity
    const tex_width = 32;
    const tex_height = 32;
    mock_texture_storage = Texture {
        .texture_id = 1, // Dummy ID
        .width = tex_width,
        .height = tex_height,
        .format = .RGBA,
    };

    const sprite_pos = math.Vec2.new(100.0, 150.0);
    const sprite_size = math.Vec2.new(50.0, 50.0);

    var sprite = Sprite.init(allocator, &mock_texture_storage, sprite_pos, sprite_size);

    try std.testing.expect(sprite.texture == &mock_texture_storage);
    try std.testing.expect(sprite.position.x == sprite_pos.x);
    try std.testing.expect(sprite.position.y == sprite_pos.y);
    try std.testing.expect(sprite.size.x == sprite_size.x);
    try std.testing.expect(sprite.size.y == sprite_size.y);
    try std.testing.expect(sprite.color.r == 1.0 and sprite.color.g == 1.0 and sprite.color.b == 1.0 and sprite.color.a == 1.0); // Default white
    try std.testing.expect(sprite.rotation == 0.0);
    try std.testing.expect(sprite.origin.x == 0.5 and sprite.origin.y == 0.5); // Default center

    // Check default texture_rect_size when texture is provided
    try std.testing.expect(sprite.texture_rect_pos.x == 0.0 and sprite.texture_rect_pos.y == 0.0);
    try std.testing.expect(sprite.texture_rect_size.x == @intToFloat(f32, tex_width));
    try std.testing.expect(sprite.texture_rect_size.y == @intToFloat(f32, tex_height));

    // Test with null texture
    var sprite_no_tex = Sprite.init(allocator, null, sprite_pos, sprite_size);
    try std.testing.expect(sprite_no_tex.texture == null);
    try std.testing.expect(sprite_no_tex.texture_rect_size.x == 0.0 and sprite_no_tex.texture_rect_size.y == 0.0);


    std.log.info("Sprite test completed.", .{});
}
