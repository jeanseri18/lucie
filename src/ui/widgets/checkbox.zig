// src/ui/widgets/checkbox.zig
// Defines a Checkbox widget.

const std = @import("std");
const Vec2 = @import("../../math/vec2.zig").Vec2;
const Color = @import("../../graphics/color.zig").Color;
const UIContext = @import("../ui_system.zig").UIContext; // For interaction and drawing context
const Rect = @import("button.zig").Rect; // Re-use Rect from button for bounds

// CheckboxWidget (for retained mode) or parameters for IMGUI function.
pub const CheckboxWidget = struct {
    // label: ?[]const u8, // Optional label text next to the checkbox
    // rect: Rect, // Position and size (usually just for the box part)
    // is_checked: bool,

    // --- IMGUI-style function for a checkbox ---
    // `checked_ptr` is an in-out parameter holding the checkbox's state.
    // Returns true if the state of the checkbox changed in this frame.
    pub fn draw(
        ctx: *UIContext,
        id_str: []const u8, // Unique ID for this checkbox instance
        label_opt: ?[]const u8,
        position: Vec2, // Top-left position of the checkbox (box part)
        size: f32, // Size of the square checkbox box
        checked_ptr: *bool, // Pointer to the boolean state this checkbox controls
    ) bool /* state_changed */ {
        _ = id_str; // Used for IMGUI state (hot, active for click interaction)
        var state_changed = false;

        const box_rect = Rect{ .pos = position, .size = Vec2.new(size, size) };
        // Label position would be next to the box, e.g., position.x + size + padding.

        // Interaction logic
        const mouse_pos_raw = ctx.input_manager.getMousePosition();
        const mouse_pos = Vec2.new(mouse_pos_raw.x, mouse_pos_raw.y);
        var is_hot = false; // Is mouse hovering over the clickable area (box + label)

        // Define clickable area (can be just the box, or box + label)
        // For simplicity, let's make only the box clickable, or a slightly larger area around it.
        // If label exists, clickable area might extend to include it.
        const clickable_rect = box_rect; // Simple: only box is clickable.
                                        // More advanced: calculate bounds including label.

        if (clickable_rect.containsPoint(mouse_pos)) {
            is_hot = true;
            // ctx.ui_state.setHot(id_str);
            if (ctx.input_manager.isMouseButtonReleased(.Left)) { // Toggle on release
                // if (ctx.ui_state.isActive(id_str) and ctx.ui_state.isHot(id_str)) { // IMGUI click confirmation
                checked_ptr.* = !checked_ptr.*;
                state_changed = true;
                // }
            }
        }
        // if (ctx.input_manager.isMouseButtonPressed(.Left) and is_hot) {
            // ctx.ui_state.setActive(id_str); // IMGUI: mark as active on press
        // } else if (ctx.input_manager.isMouseButtonReleased(.Left)) {
            // ctx.ui_state.clearActive();
        // }


        // Drawing logic (placeholder)
        // const theme = ctx.theme;
        const box_bg_color = if (is_hot) Color.LightGray else Color.Gray; // theme.checkbox.box_background_hot / _normal
        const box_border_color = Color.Black; // theme.checkbox.box_border
        const check_mark_color = Color.Blue; // theme.checkbox.check_mark_color

        // ctx.current_canvas.drawRect(box_rect.pos.x, box_rect.pos.y, box_rect.size.x, box_rect.size.y, box_bg_color, true);
        // ctx.current_canvas.drawRectBorder(box_rect, 1.0, box_border_color); // Assuming a border drawing function
        std.log.debug("CheckboxWidget.draw: Box at ({d:.0},{d:.0}) size {d:.0} (mock draw)", .{
            position.x, position.y, size
        });

        if (checked_ptr.*) {
            // Draw check mark (e.g., an 'X' or a tick ✔)
            // This requires line drawing or a small glyph/texture.
            // Placeholder: just log it.
            // const p1 = Vec2.new(box_rect.pos.x + size*0.2, box_rect.pos.y + size*0.2);
            // const p2 = Vec2.new(box_rect.pos.x + size*0.8, box_rect.pos.y + size*0.8);
            // ctx.current_canvas.drawLine(p1,p2, check_mark_color, 2.0);
            // const p3 = Vec2.new(box_rect.pos.x + size*0.8, box_rect.pos.y + size*0.2);
            // const p4 = Vec2.new(box_rect.pos.x + size*0.2, box_rect.pos.y + size*0.8);
            // ctx.current_canvas.drawLine(p3,p4, check_mark_color, 2.0);
             std.log.debug("CheckboxWidget.draw: Check mark drawn (is_checked=true) (mock draw)", .{});
        }

        if (label_opt) |label| {
            // const label_pos = Vec2.new(position.x + size + 5.0, position.y + size / 2.0); // Adjust for vertical alignment
            // ctx.current_canvas.drawText(label, label_pos, default_font, default_font_size, default_text_color);
            std.log.debug("CheckboxWidget.draw: Label '{s}' (mock draw)", .{label});
        }

        return state_changed;
    }
};

test "CheckboxWidget.draw function (mocked interaction and drawing)" {
    const allocator = std.testing.allocator;
    var dummy_im_storage = @import("../../input/input_manager.zig").InputManager.init(allocator);
    defer dummy_im_storage.deinit();

    var ui_ctx = UIContext{
        .input_manager = &dummy_im_storage,
        .delta_time = 0.016,
    };

    var is_checked_state: bool = false;
    const cb_pos = Vec2.new(30, 70);
    const cb_size: f32 = 16.0; // Typical checkbox size

    // --- Test Case 1: Draw, no interaction, state unchanged ---
    dummy_im_storage.prepareFrame();
    var changed = CheckboxWidget.draw(&ui_ctx, "cb1", "Enable Feature", cb_pos, cb_size, &is_checked_state);
    try std.testing.expect(!changed);
    try std.testing.expect(is_checked_state == false);

    // --- Test Case 2: Click to check (simulate mouse release over checkbox) ---
    // To simulate isMouseButtonReleased: prev=true, current=false
    dummy_im_storage.prepareFrame();
    dummy_im_storage.mouse.prev_button_states.set(.Left, true); // Was pressed
    dummy_im_storage.mouse.button_states.set(.Left, false);    // Now released
    dummy_im_storage.mouse.current_x = cb_pos.x + cb_size / 2.0; // Mouse over checkbox
    dummy_im_storage.mouse.current_y = cb_pos.y + cb_size / 2.0;

    changed = CheckboxWidget.draw(&ui_ctx, "cb1", "Enable Feature", cb_pos, cb_size, &is_checked_state);
    try std.testing.expect(changed);
    try std.testing.expect(is_checked_state == true); // State toggled to true

    // --- Test Case 3: Click again to uncheck ---
    dummy_im_storage.prepareFrame();
    dummy_im_storage.mouse.prev_button_states.set(.Left, true);
    dummy_im_storage.mouse.button_states.set(.Left, false);
    dummy_im_storage.mouse.current_x = cb_pos.x + cb_size / 2.0;
    dummy_im_storage.mouse.current_y = cb_pos.y + cb_size / 2.0;

    changed = CheckboxWidget.draw(&ui_ctx, "cb1", "Enable Feature", cb_pos, cb_size, &is_checked_state);
    try std.testing.expect(changed);
    try std.testing.expect(is_checked_state == false); // State toggled back to false

    // --- Test Case 4: Mouse release outside (no change) ---
    is_checked_state = true; // Reset to true for this test
    dummy_im_storage.prepareFrame();
    dummy_im_storage.mouse.prev_button_states.set(.Left, true); // Was pressed
    dummy_im_storage.mouse.button_states.set(.Left, false);    // Now released
    dummy_im_storage.mouse.current_x = 0; dummy_im_storage.mouse.current_y = 0; // Mouse outside

    changed = CheckboxWidget.draw(&ui_ctx, "cb1", "Enable Feature", cb_pos, cb_size, &is_checked_state);
    try std.testing.expect(!changed);
    try std.testing.expect(is_checked_state == true); // State should not change

    std.log.info("CheckboxWidget.draw test completed.", .{});
}

// Add Gray, LightGray, Black, Blue to graphics/color.zig if not present for mock drawing logs.
// pub const Gray = Color{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 1.0 };
// pub const LightGray = Color{ .r = 0.75, .g = 0.75, .b = 0.75, .a = 1.0 };
// pub const Black = Color{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 };
// pub const Blue = Color{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 };
