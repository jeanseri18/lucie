// src/ui/widgets/text.zig
// Defines a Text widget (or Label).

const std = @import("std");
const Vec2 = @import("../../math/vec2.zig").Vec2;
const Color = @import("../../graphics/color.zig").Color;
const UIContext = @import("../ui_system.zig").UIContext; // For drawing context
// const FontHandle = u32; // Placeholder for font resource handle

// TextWidget / LabelWidget struct (for retained mode) or parameters for IMGUI function.
pub const TextWidget = struct {
    // text_content: []const u8,
    // position: Vec2, // Relative to parent or absolute
    // font_handle: ?FontHandle = null, // If null, use default from theme
    // font_size_px: f32 = 16.0, // Default font size
    // text_color: Color = Color.Black, // Default text color (theme might override)
    // text_alignment: Alignment = .Left, // Horizontal alignment
    // vertical_alignment: VerticalAlignment = .Top,

    // pub const Alignment = enum { Left, Center, Right };
    // pub const VerticalAlignment = enum { Top, Middle, Bottom };

    // --- IMGUI-style function for drawing text/label ---
    pub fn draw(
        ctx: *UIContext, // UIContext from UISystem.beginFrame()
        text_content: []const u8,
        position: Vec2,
        // Optional: font_h: ?FontHandle,
        font_size: f32,
        text_color_opt: ?Color,
        // Optional: alignment_h: ?Alignment,
        // Optional: alignment_v: ?VerticalAlignment,
    ) void {
        _ = ctx; // ctx would be used for:
                 // - Getting default font/color from theme if options are null.
                 // - Accessing the Canvas to draw on: ctx.current_canvas.drawText(...).
                 // - Text measurement for alignment: ctx.text_measurer.measure(text, font, size).

        const final_color = text_color_opt orelse Color.Black; // Default to black if not specified

        // Placeholder: Log the drawing call.
        // A real implementation would call canvas.drawText with all parameters.
        std.log.debug("TextWidget.draw: '{s}' at ({d:.0},{d:.0}), size: {d:.1}, color R:{d:.2} (mock draw)", .{
            text_content, position.x, position.y, font_size, final_color.r,
        });

        // Example of how it might interact with a canvas (conceptual):
        // var actual_pos = position;
        // if (alignment_h != null or alignment_v != null) {
        //    const text_dims = ctx.text_measurer.measure(text_content, font_h orelse ctx.theme.default_font, font_size);
        //    if (alignment_h) |h_align| switch (h_align) {
        //        .Center => actual_pos.x -= text_dims.width / 2.0,
        //        .Right => actual_pos.x -= text_dims.width,
        //        else => {},
        //    }
        //    // Similar for vertical alignment...
        // }
        // ctx.current_canvas.drawText(text_content, actual_pos, font_h orelse ctx.theme.default_font, font_size, final_color);
    }
};

test "TextWidget.draw function (mocked drawing)" {
    // Setup mock UIContext
    const allocator = std.testing.allocator; // Not used by TextWidget.draw directly, but UIContext might need it
    var dummy_im_storage = @import("../../input/input_manager.zig").InputManager.init(allocator); // InputManager not really used by static text
    defer dummy_im_storage.deinit();

    var ui_ctx = UIContext{
        .input_manager = &dummy_im_storage, // Placeholder, text doesn't interact with input directly
        .delta_time = 0.016,
        // .current_canvas = &mock_canvas, // A mock canvas would be needed for real drawing tests
        // .theme = &mock_theme,
    };

    const text_pos = Vec2.new(100, 150);
    const text_size: f32 = 24.0;
    const text_val = "Hello, Lucie UI!";

    // Call draw function (currently just logs)
    TextWidget.draw(&ui_ctx, text_val, text_pos, text_size, Color.Blue);

    // Test with default color (null passed for color option)
    TextWidget.draw(&ui_ctx, "Another Label", Vec2.new(20,30), 12.0, null);


    // No specific state to assert for this placeholder test, as it only logs.
    // A real test would check what was drawn to a mock canvas or verify text properties.
    try std.testing.expect(true); // Placeholder assertion
    std.log.info("TextWidget.draw test completed (relies on log output).", .{});
}
