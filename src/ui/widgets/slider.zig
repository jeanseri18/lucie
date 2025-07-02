// src/ui/widgets/slider.zig
// Defines a Slider widget for selecting a value within a range.

const std = @import("std");
const Vec2 = @import("../../math/vec2.zig").Vec2;
const Color = @import("../../graphics/color.zig").Color;
const UIContext = @import("../ui_system.zig").UIContext; // For interaction and drawing context
const Rect = @import("button.zig").Rect; // Re-use Rect from button for bounds

// SliderWidget (for retained mode) or parameters for IMGUI function.
pub const SliderWidget = struct {
    // value: f32, // Current value of the slider
    // min_value: f32 = 0.0,
    // max_value: f32 = 1.0,
    // orientation: Orientation = .Horizontal,
    // rect: Rect, // Position and size

    // pub const Orientation = enum { Horizontal, Vertical };

    // --- IMGUI-style function for a slider ---
    // Returns the new value if it changed, otherwise null.
    // `current_value_ptr` is an in-out parameter holding the slider's state.
    pub fn draw(
        ctx: *UIContext,
        id_str: []const u8, // Unique ID for this slider instance
        label_opt: ?[]const u8, // Optional label text
        position: Vec2,
        length: f32, // Length of the slider track (width if horizontal, height if vertical)
        thickness: f32, // Thickness of the slider track and handle
        current_value_ptr: *f32, // Pointer to the value this slider controls
        min_val: f32,
        max_val: f32,
        orientation: enum {Horizontal, Vertical} = .Horizontal,
    ) bool /* value_changed */ {
        _ = id_str; // Used for IMGUI state (is_active, etc.)
        var value_changed = false;
        const current_value = current_value_ptr.*;

        const track_rect = if (orientation == .Horizontal)
            Rect{ .pos = position, .size = Vec2.new(length, thickness) }
        else
            Rect{ .pos = position, .size = Vec2.new(thickness, length) };

        // Calculate handle properties
        const value_range = max_val - min_val;
        const normalized_value = if (value_range == 0) 0.0 else (current_value - min_val) / value_range;

        const handle_size = thickness; // Square handle for simplicity
        var handle_pos: Vec2 = undefined;

        if (orientation == .Horizontal) {
            const track_inner_length = length - handle_size; // Space handle can move in
            handle_pos.x = track_rect.pos.x + normalized_value * track_inner_length;
            handle_pos.y = track_rect.pos.y; // Centered on track thickness (or aligned)
        } else { // Vertical
            const track_inner_length = length - handle_size;
            handle_pos.x = track_rect.pos.x;
            handle_pos.y = track_rect.pos.y + (1.0 - normalized_value) * track_inner_length; // Y typically grows downwards
        }
        const handle_rect = Rect{ .pos = handle_pos, .size = Vec2.new(handle_size, handle_size) };

        // Interaction logic
        const mouse_pos_raw = ctx.input_manager.getMousePosition();
        const mouse_pos = Vec2.new(mouse_pos_raw.x, mouse_pos_raw.y);
        var is_active_on_this_slider = false; // Placeholder for IMGUI active state check on this ID

        // Check if mouse click starts on the handle or track (simplified to track for now)
        if (ctx.input_manager.isMouseButtonPressed(.Left)) {
            if (track_rect.containsPoint(mouse_pos) or handle_rect.containsPoint(mouse_pos)) {
                // ctx.ui_state.setActive(id_str); // IMGUI: this slider becomes active
                is_active_on_this_slider = true; // Simulate becoming active for this interaction
            }
        }

        // If this slider is active (mouse button held down on it)
        // if (ctx.ui_state.isActive(id_str)) { // IMGUI state check
        // For placeholder, use our simulated `is_active_on_this_slider` or if mouse is simply down.
        if (is_active_on_this_slider or ctx.input_manager.isMouseButtonDown(.Left)) { // Simplified: if mouse down and was initially on it
            var new_normalized_value: f32 = 0.0;
            if (orientation == .Horizontal) {
                const track_inner_length = length - handle_size;
                const mouse_relative_x = mouse_pos.x - track_rect.pos.x - (handle_size / 2.0);
                new_normalized_value = if (track_inner_length == 0) 0.0 else mouse_relative_x / track_inner_length;
            } else { // Vertical
                const track_inner_length = length - handle_size;
                const mouse_relative_y = mouse_pos.y - track_rect.pos.y - (handle_size / 2.0);
                new_normalized_value = 1.0 - (if (track_inner_length == 0) 0.0 else mouse_relative_y / track_inner_length);
            }

            const new_value = min_val + std.math.clamp(new_normalized_value, 0.0, 1.0) * value_range;
            if (new_value != current_value) {
                current_value_ptr.* = new_value;
                value_changed = true;
            }
        }
        // if (ctx.input_manager.isMouseButtonReleased(.Left)) {
            // ctx.ui_state.clearActive(); // IMGUI: clear active ID
        // }


        // Drawing logic (placeholder)
        // const theme = ctx.theme;
        const track_color = Color.DarkGray; // theme.slider.track_color;
        const handle_color = Color.LightGray; // theme.slider.handle_color;
        // if (ctx.ui_state.isHot(id_str) or ctx.ui_state.isActive(id_str)) handle_color = theme.slider.handle_hover_color;

        // ctx.current_canvas.drawRect(track_rect.pos.x, track_rect.pos.y, track_rect.size.x, track_rect.size.y, track_color, true);
        // ctx.current_canvas.drawRect(handle_rect.pos.x, handle_rect.pos.y, handle_rect.size.x, handle_rect.size.y, handle_color, true);
        std.log.debug("SliderWidget.draw: Track at ({d:.0},{d:.0}) size ({d:.0},{d:.0}) (mock draw)", .{
            track_rect.pos.x, track_rect.pos.y, track_rect.size.x, track_rect.size.y
        });
         std.log.debug("SliderWidget.draw: Handle at ({d:.0},{d:.0}) size ({d:.0},{d:.0}) (mock draw)", .{
            handle_rect.pos.x, handle_rect.pos.y, handle_rect.size.x, handle_rect.size.y
        });

        if (label_opt) |label| {
            // Draw label text and current value
            // const label_pos = ...;
            // ctx.current_canvas.drawText(label, label_pos, ...);
            // const value_text = std.fmt.allocPrint(ctx.allocator, "{d:.2}", .{current_value_ptr.*}) catch "err";
            // defer ctx.allocator.free(value_text);
            // ctx.current_canvas.drawText(value_text, value_text_pos, ...);
            std.log.debug("SliderWidget.draw: Label '{s}', Value: {d:.2f} (mock draw)", .{label, current_value_ptr.*});
        }

        return value_changed;
    }
};

test "SliderWidget.draw function (mocked interaction and drawing)" {
    const allocator = std.testing.allocator;
    var dummy_im_storage = @import("../../input/input_manager.zig").InputManager.init(allocator);
    defer dummy_im_storage.deinit();

    var ui_ctx = UIContext{
        .input_manager = &dummy_im_storage,
        .delta_time = 0.016,
    };

    var slider_val: f32 = 0.5;
    const slider_pos = Vec2.new(10, 10);
    const slider_len: f32 = 200.0;
    const slider_thick: f32 = 20.0;

    // --- Test Case 1: Draw without interaction ---
    dummy_im_storage.prepareFrame();
    var changed = SliderWidget.draw(&ui_ctx, "slider1", "Volume", slider_pos, slider_len, slider_thick, &slider_val, 0.0, 1.0);
    try std.testing.expect(!changed);
    try std.testing.expect(slider_val == 0.5); // Value shouldn't change

    // --- Test Case 2: Simulate dragging the slider handle ---
    // To simulate dragging, we need to:
    // 1. Mouse press event over the slider.
    // 2. Mouse move event to a new position.
    // 3. The SliderWidget.draw call should then update `slider_val`.

    // Frame A: Mouse presses on the slider (e.g., at current handle position)
    dummy_im_storage.prepareFrame();
    // Calculate where 0.5 value handle is: 10 (pos.x) + 0.5 * (200 - 20) (track_inner_len) = 10 + 0.5 * 180 = 10 + 90 = 100
    dummy_im_storage.onMouseMoveEvent(100, slider_pos.y + slider_thick / 2.0); // Mouse on handle
    dummy_im_storage.onMouseButtonEvent(.Left, true); // Press button

    // Call draw - this might set an "active" state in a real IMGUI.
    // For this test, the interaction logic inside draw() checks `isMouseButtonDown`.
    changed = SliderWidget.draw(&ui_ctx, "slider1", "Volume", slider_pos, slider_len, slider_thick, &slider_val, 0.0, 1.0);
    // Value might change here if click itself updates, or if it's purely drag based.
    // Current logic updates if mouse is down and over the component.
    // So, if clicking at 0.5, value should remain 0.5 if mouse is exactly on handle center.
    // Let's assume the click itself (if on track) can set initial value.
    // Click at x=60 (slider_pos.x + 50). Handle size is 20.
    // mouse_relative_x = 60 - 10 - 10 = 40. track_inner_length = 200 - 20 = 180.
    // new_norm_val = 40 / 180 = 0.222...
    dummy_im_storage.prepareFrame(); // Process the press
    dummy_im_storage.onMouseMoveEvent(slider_pos.x + 50, slider_pos.y + slider_thick / 2.0); // Click at x=60
    // mouse is still down from previous event in InputManager's next_state, which becomes current_state here.
    // So, isMouseButtonDown(.Left) will be true.
    changed = SliderWidget.draw(&ui_ctx, "slider1", "Volume", slider_pos, slider_len, slider_thick, &slider_val, 0.0, 1.0);

    try std.testing.expect(changed);
    const expected_val_after_click = 0.0 + std.math.clamp( (50.0 - (slider_thick/2.0)) / (slider_len - slider_thick) , 0.0, 1.0) * (1.0 - 0.0);
    try std.testing.expect(std.math.approxEqAbs(slider_val, expected_val_after_click, 0.01));


    // Frame B: Mouse (still pressed) moves to a new position, changing the value
    dummy_im_storage.prepareFrame(); // Process previous frame's events
    // Mouse is still considered down. Move mouse to change value.
    // Target new value: 0.8. Target raw_x = 10 + 0.8 * 180 + 10 (handle_half_size) = 10 + 144 + 10 = 164
    dummy_im_storage.onMouseMoveEvent(164, slider_pos.y + slider_thick / 2.0);

    changed = SliderWidget.draw(&ui_ctx, "slider1", "Volume", slider_pos, slider_len, slider_thick, &slider_val, 0.0, 1.0);
    try std.testing.expect(changed);
    try std.testing.expect(std.math.approxEqAbs(slider_val, 0.8, 0.01));

    // Frame C: Mouse released
    dummy_im_storage.prepareFrame();
    dummy_im_storage.onMouseButtonEvent(.Left, false); // Release button
    // Call draw again, value shouldn't change from release event itself
    changed = SliderWidget.draw(&ui_ctx, "slider1", "Volume", slider_pos, slider_len, slider_thick, &slider_val, 0.0, 1.0);
    try std.testing.expect(!changed); // No change on release if mouse hasn't moved
    try std.testing.expect(std.math.approxEqAbs(slider_val, 0.8, 0.01)); // Value remains


    std.log.info("SliderWidget.draw test completed.", .{});
}

// Add DarkGray, LightGray to graphics/color.zig if not present for mock drawing logs.
// pub const DarkGray = Color{ .r = 0.25, .g = 0.25, .b = 0.25, .a = 1.0 };
// pub const LightGray = Color{ .r = 0.75, .g = 0.75, .b = 0.75, .a = 1.0 };
