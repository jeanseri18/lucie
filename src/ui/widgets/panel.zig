// src/ui/widgets/panel.zig
// Defines a Panel widget, a container for other UI elements.

const std = @import("std");
const Vec2 = @import("../../math/vec2.zig").Vec2;
const Color = @import("../../graphics/color.zig").Color;
const UIContext = @import("../ui_system.zig").UIContext; // For drawing context
// const Layout = @import("../layout/layout_manager.zig").LayoutType; // If panel has layout type

// PanelWidget struct (for retained mode) or parameters for IMGUI function group.
// A panel is primarily a visual container, possibly with a background and border.
// It might also manage a layout for its child elements.
pub const PanelWidget = struct {
    // rect: Rect, // Position and size
    // background_color: ?Color = null, // If null, might be transparent or use theme default
    // border_color: ?Color = null,
    // border_thickness: f32 = 0.0,
    //
    // children: std.ArrayList(*anyopaque), // Pointers to child widgets (type-erased for retained mode)
    // layout_type: Layout = .None, // How children are arranged

    // --- IMGUI-style functions for a panel ---
    // An IMGUI panel is often defined by `beginPanel` and `endPanel` calls,
    // and widgets created between them are considered children.

    // Begins a panel region. Subsequent UI elements are drawn relative to this panel
    // and might be clipped by its bounds.
    // Returns a context or state for drawing within the panel.
    pub fn begin(
        ctx: *UIContext, // Parent UIContext
        id_str: []const u8, // Unique ID for the panel
        position: Vec2,
        size: Vec2,
        background_color_opt: ?Color,
        // Optional: border_color_opt: ?Color,
        // Optional: border_thickness_opt: f32,
        // Optional: title: ?[]const u8,
    ) PanelContext /* or bool to indicate if visible/open */ {
        _ = id_str; // Used for IMGUI state, e.g., scroll position, collapsed state
        _ = ctx;    // Parent context used for drawing, input, theme

        // 1. Draw panel background (and border, title bar if any)
        //    This would use ctx.current_canvas.
        if (background_color_opt) |bg_color| {
            // ctx.current_canvas.drawRect(position.x, position.y, size.x, size.y, bg_color, true);
            std.log.debug("Panel.begin: Draw background for '{s}' at ({d:.0},{d:.0}) size ({d:.0},{d:.0}), color R:{d:.2} (mock draw)", .{
                id_str, position.x, position.y, size.x, size.y, bg_color.r,
            });
        } else {
             std.log.debug("Panel.begin: Panel '{s}' at ({d:.0},{d:.0}) size ({d:.0},{d:.0}) (no explicit background) (mock draw)", .{
                id_str, position.x, position.y, size.x, size.y,
            });
        }

        // 2. Set up drawing context for children:
        //    - New coordinate system (origin at panel's top-left content area).
        //    - Clipping rectangle to panel's content bounds.
        //    - Scissor test for GPU rendering.
        //    This would modify a copy of `ctx` or a sub-context.
        var panel_ctx = PanelContext{
            .parent_context = ctx,
            .content_offset = position, // Simplified: children draw relative to panel's origin for now
                                        // A real panel would have padding, title bar height etc.
            .content_size = size,
        };

        // For IMGUI, push panel ID to stack, set new drawing region/offset.
        // ctx.imgui_state.pushPanel(id_str, position, size);

        return panel_ctx;
    }

    // Ends a panel region, restoring previous drawing context.
    pub fn end(panel_context: *PanelContext) void {
        // For IMGUI, pop panel ID from stack, restore drawing region/offset.
        // panel_context.parent_context.imgui_state.popPanel();
        _ = panel_context; // Mark as used
        std.log.debug("Panel.end (mock)", .{});
    }
};

// Context for drawing child elements within a panel.
// This would carry transformed coordinates, clipping info, etc.
pub const PanelContext = struct {
    parent_context: *UIContext,
    content_offset: Vec2, // Top-left of the panel's content area in parent coordinates
    content_size: Vec2,
    // current_cursor_pos: Vec2, // For auto-layout within the panel (IMGUI style)
    // scroll_offset: Vec2, // If panel is scrollable
};

// Helper function to draw a button *within* a panel context.
// This demonstrates how child widget functions would use the PanelContext.
pub fn panelButton(
    pctx: *PanelContext, // Context from PanelWidget.begin()
    id_str: []const u8,
    label_text: []const u8,
    local_pos: Vec2, // Position relative to panel's content area
    size: Vec2,
) bool {
    // Transform local_pos to screen/parent coordinates
    const screen_pos = pctx.content_offset.add(local_pos);

    // TODO: Clipping - check if button rect (screen_pos, size) is within pctx.content_size.
    // If not, don't draw or interact. This is simplified for now.

    // Call the global ButtonWidget.draw using the parent UIContext.
    return @import("button.zig").ButtonWidget.draw(
        pctx.parent_context,
        id_str,
        label_text,
        screen_pos,
        size
    );
}


test "PanelWidget.begin and PanelWidget.end (mocked)" {
    const allocator = std.testing.allocator;
    var dummy_im_storage = @import("../../input/input_manager.zig").InputManager.init(allocator);
    defer dummy_im_storage.deinit();

    var parent_ui_ctx = UIContext{
        .input_manager = &dummy_im_storage,
        .delta_time = 0.016,
    };

    const panel_pos = Vec2.new(20, 30);
    const panel_size = Vec2.new(200, 150);

    // Begin panel
    var panel_ctx = PanelWidget.begin(&parent_ui_ctx, "myPanel", panel_pos, panel_size, Color.LightBlue);

    // Check panel context properties (simplified)
    try std.testing.expect(panel_ctx.parent_context == &parent_ui_ctx);
    try std.testing.expect(panel_ctx.content_offset.eql(panel_pos));
    try std.testing.expect(panel_ctx.content_size.eql(panel_size));

    // Simulate drawing a child widget within the panel
    // This uses the panelButton helper which calls the main ButtonWidget.draw.
    const button_local_pos = Vec2.new(10, 10); // Relative to panel's content area
    const button_sz = Vec2.new(80, 25);
    _ = panelButton(&panel_ctx, "panelBtn1", "Inside Panel", button_local_pos, button_sz);
    // Log output from ButtonWidget.draw should show screen position:
    // (20+10, 30+10) = (30,40)

    // End panel
    PanelWidget.end(&panel_ctx);

    // No specific state to assert for panel itself in this mock test, relies on logs.
    try std.testing.expect(true);
    std.log.info("PanelWidget begin/end test completed (relies on log output).", .{});
}

// Add Color.LightBlue to graphics/color.zig for test if not present:
// pub const LightBlue = Color{ .r = 0.68, .g = 0.85, .b = 0.90, .a = 1.0 };
