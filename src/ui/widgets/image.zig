// src/ui/widgets/image.zig
// Defines an Image widget for displaying textures.

const std = @import("std");
const Vec2 = @import("../../math/vec2.zig").Vec2;
const Color = @import("../../graphics/color.zig").Color; // For tint color
const UIContext = @import("../ui_system.zig").UIContext; // For drawing context
// const TextureHandle = u32; // Placeholder for texture resource handle, matches ecs/components/sprite.zig
const Rect = @import("button.zig").Rect; // Re-use Rect from button for bounds and source_rect

// ImageWidget (for retained mode) or parameters for IMGUI function.
pub const ImageWidget = struct {
    // texture_handle: TextureHandle,
    // rect: Rect, // Position and size on UI canvas
    // source_rect_opt: ?Rect = null, // Optional sub-rectangle of the texture to display (in texture's pixel coords)
    // tint_color: Color = Color.White, // Tint color applied to the texture
    // aspect_ratio_mode: AspectRatioMode = .Stretch, // How to handle aspect ratio if widget size and texture size differ

    // pub const AspectRatioMode = enum {
    //     Stretch,        // Stretch texture to fill widget rect
    //     Fit,            // Fit texture within widget rect, maintaining aspect ratio (letterboxing/pillarboxing)
    //     Fill,           // Fill widget rect with texture, maintaining aspect ratio (cropping may occur)
    //     Tile,           // Tile the texture if widget rect is larger
    // };

    // --- IMGUI-style function for drawing an image ---
    pub fn draw(
        ctx: *UIContext,
        // id_str: []const u8, // ID might be needed if image is interactive (e.g., clickable)
        texture_handle: u32, // Using u32 as placeholder TextureHandle
        position: Vec2,
        size_opt: ?Vec2, // Optional size. If null, might use texture's native size or require explicit size.
                         // For this placeholder, let's assume size must be provided or defaults to a fixed value if null.
        source_rect_opt: ?Rect, // Sub-rectangle of the texture (in texture's pixel coordinates)
        tint_color_opt: ?Color,
    ) void {
        _ = ctx; // ctx would be used for:
                 // - Accessing the Canvas: ctx.current_canvas.drawTexture(...).
                 // - Getting texture dimensions from texture_handle if size_opt is null.
                 // - Theme defaults for tint if tint_color_opt is null.

        const display_size = size_opt orelse Vec2.new(32, 32); // Default to 32x32 if no size given (placeholder)
        const final_tint = tint_color_opt orelse Color.White;

        // Placeholder: Log the drawing call.
        // A real implementation would call canvas.drawTexture with all parameters.
        std.log.debug("ImageWidget.draw: TextureHandle {d} at ({d:.0},{d:.0}) size ({d:.0},{d:.0}), tint R:{d:.2} (mock draw)", .{
            texture_handle, position.x, position.y, display_size.x, display_size.y, final_tint.r,
        });
        if (source_rect_opt) |sr| {
            std.log.debug("  SourceRect: pos({d:.0},{d:.0}) size({d:.0},{d:.0}) (mock draw)", .{
                sr.pos.x, sr.pos.y, sr.size.x, sr.size.y
            });
        }

        // Example of how it might interact with a canvas (conceptual):
        // var actual_draw_size = display_size;
        // var actual_source_rect = source_rect_opt;
        //
        // if (size_opt == null and actual_source_rect == null) {
        //    // Use full texture size if no size and no source_rect specified
        //    // const tex_dims = ctx.texture_manager.getDimensions(texture_handle);
        //    // actual_draw_size = tex_dims;
        // }
        //
        // // Handle aspect ratio modes if implemented...
        //
        // ctx.current_canvas.drawTexture(texture_handle, position, actual_draw_size, actual_source_rect, final_tint);
    }
};

test "ImageWidget.draw function (mocked drawing)" {
    const allocator = std.testing.allocator;
    var dummy_im_storage = @import("../../input/input_manager.zig").InputManager.init(allocator);
    defer dummy_im_storage.deinit();

    var ui_ctx = UIContext{
        .input_manager = &dummy_im_storage, // Not used by static image, but part of context
        .delta_time = 0.016,
        // .current_canvas = &mock_canvas,
        // .theme = &mock_theme,
        // .texture_manager = &mock_texture_manager, // For getting texture info
    };

    const img_pos = Vec2.new(200, 100);
    const test_texture_handle: u32 = 12345;

    // --- Test Case 1: Draw with specified size and default tint ---
    const img_size = Vec2.new(64, 64);
    ImageWidget.draw(&ui_ctx, test_texture_handle, img_pos, img_size, null, null);
    // Log should show texture 12345, pos (200,100), size (64,64), white tint.

    // --- Test Case 2: Draw with default size, custom tint, and source rectangle ---
    const custom_tint = Color.new(1.0, 0.8, 0.8, 0.9); // Light reddish tint
    const source_rect = Rect{ .pos = Vec2.new(0,0), .size = Vec2.new(16,16) }; // Top-left 16x16 part of texture
    ImageWidget.draw(&ui_ctx, 777, Vec2.new(10,10), null, source_rect, custom_tint);
    // Log should show texture 777, pos (10,10), default size (e.g. 32x32), source_rect, custom_tint.


    // No specific state to assert for this placeholder test, as it only logs.
    try std.testing.expect(true); // Placeholder assertion
    std.log.info("ImageWidget.draw test completed (relies on log output).", .{});
}
