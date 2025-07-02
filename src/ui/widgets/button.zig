// src/ui/widgets/button.zig
// Defines a Button widget.

const std = @import("std");
const Vec2 = @import("../../math/vec2.zig").Vec2;
const Color = @import("../../graphics/color.zig").Color;
const UIContext = @import("../ui_system.zig").UIContext; // For interaction and drawing context
// const Canvas = @import("../canvas.zig").Canvas; // For drawing
// const Theme = @import("../style/theme.zig").Theme; // For styling

// Button state (for styling and interaction logic)
pub const ButtonState = enum {
    Normal,
    Hovered,
    Pressed, // Clicked down
    // Disabled,
};

// ButtonWidget struct.
// In an IMGUI, this might not be a persistent struct, but rather function parameters and transient state.
// In a retained mode UI, this would be a node in the UI tree.
// For this placeholder, let's define it as a struct that could be used by either,
// or its fields passed to an IMGUI-style function.
pub const ButtonWidget = struct {
    // id: u64, // Unique ID for state tracking in IMGUI
    label: []const u8,
    rect: Rect, // Position and size in parent's coordinate space

    // State (updated each frame)
    // current_state: ButtonState = .Normal,
    // clicked_this_frame: bool = false,

    // Styling (could come from a Theme or be set per instance)
    // normal_style: ButtonStyle,
    // hovered_style: ButtonStyle,
    // pressed_style: ButtonStyle,

    // Action to perform when clicked
    // on_click_fn: ?fn(button_ptr: *ButtonWidget, user_context: ?*anyopaque) void = null,
    // on_click_context: ?*anyopaque = null,


    // --- IMGUI-style function ---
    // This is a common pattern for immediate mode UIs.
    // Returns true if the button was clicked in this frame.
    pub fn draw(
        ctx: *UIContext, // UIContext from UISystem.beginFrame()
        id_str: []const u8, // Unique identifier string for this button instance
        label_text: []const u8,
        position: Vec2,
        size: Vec2,
        // Optional: custom_style: ?ButtonStyle,
    ) bool {
        _ = id_str; // ID would be used for IMGUI state (hot, active)
        const bounds = Rect{ .pos = position, .size = size };
        var was_clicked = false;
        var current_button_state = ButtonState.Normal;

        // Interaction logic
        const mouse_pos_raw = ctx.input_manager.getMousePosition();
        const mouse_pos = Vec2.new(mouse_pos_raw.x, mouse_pos_raw.y);

        if (bounds.containsPoint(mouse_pos)) {
            current_button_state = .Hovered;
            // ctx.ui_state.setHot(id_str); // IMGUI: mark as hot
            if (ctx.input_manager.isMouseButtonDown(.Left)) {
                current_button_state = .Pressed;
                // ctx.ui_state.setActive(id_str); // IMGUI: mark as active
            }
            if (ctx.input_manager.isMouseButtonReleased(.Left)) {
                // Check if click release was also inside the button
                // if (ctx.ui_state.isActive(id_str) and ctx.ui_state.isHot(id_str)) {
                was_clicked = true;
                // }
            }
        } else {
            // if (ctx.ui_state.isActive(id_str) and ctx.input_manager.isMouseButtonReleased(.Left)) {
                // Click was started on this button but released outside.
                // ctx.ui_state.clearActive(); // IMGUI
            // }
        }

        // Drawing logic (placeholder - uses UISystem's Canvas via UIContext)
        // const style_to_use = getStyleForState(current_button_state, custom_style, ctx.theme);
        var bg_color = Color.Gray; // Default
        switch (current_button_state) {
            .Normal => bg_color = Color.Gray,
            .Hovered => bg_color = Color.LightGray,
            .Pressed => bg_color = Color.DarkGray,
        }

        // Assuming UIContext gives access to a Canvas for drawing.
        // For this placeholder, we'll just log.
        // ctx.current_canvas.drawRect(bounds.pos.x, bounds.pos.y, bounds.size.x, bounds.size.y, bg_color, true);
        // ctx.current_canvas.drawText(label_text, bounds.centerText(label_text, font), text_color, font);
        std.log.debug("ButtonWidget.draw: '{s}' at ({d:.0},{d:.0}), state: {any}, clicked: {b} (mock draw)", .{
            label_text, position.x, position.y, current_button_state, was_clicked
        });

        return was_clicked;
    }
};

// Placeholder for Rect and Color (assuming they are defined elsewhere and imported)
// For testing, define minimal versions here.
const Rect = struct {
    pos: Vec2,
    size: Vec2,
    pub fn containsPoint(self: Rect, pt: Vec2) bool {
        return pt.x >= self.pos.x and pt.x <= (self.pos.x + self.size.x) and
               pt.y >= self.pos.y and pt.y <= (self.pos.y + self.size.y);
    }
};
// Using Color from graphics module. Ensure it has common colors like Gray.
// Let's add them to graphics/color.zig for the test.
// (Test assumes Color.Gray, Color.LightGray, Color.DarkGray exist)


test "ButtonWidget.draw function (mocked interaction and drawing)" {
    // Setup mock UIContext and InputManager
    const allocator = std.testing.allocator;
    var dummy_im_storage = @import("../../input/input_manager.zig").InputManager.init(allocator);
    defer dummy_im_storage.deinit();

    var ui_ctx = UIContext{
        .input_manager = &dummy_im_storage,
        .delta_time = 0.016,
        // Other fields like canvas, theme would be set up by UISystem
    };

    const button_pos = Vec2.new(50, 50);
    const button_size = Vec2.new(100, 30);

    // --- Test Case 1: No interaction ---
    dummy_im_storage.prepareFrame(); // Reset input states
    var clicked = ButtonWidget.draw(&ui_ctx, "btn1", "Test Button", button_pos, button_size);
    try std.testing.expect(!clicked);

    // --- Test Case 2: Mouse hover ---
    dummy_im_storage.prepareFrame();
    dummy_im_storage.onMouseMoveEvent(75, 65); // Mouse inside button (50,50) to (150,80)
    clicked = ButtonWidget.draw(&ui_ctx, "btn1", "Test Button", button_pos, button_size);
    try std.testing.expect(!clicked); // Hover doesn't mean click

    // --- Test Case 3: Mouse press and release inside (click) ---
    dummy_im_storage.prepareFrame(); // Prepare for new input state
    dummy_im_storage.onMouseMoveEvent(75, 65);    // Ensure mouse is over button
    dummy_im_storage.onMouseButtonEvent(.Left, true); // Press left button
    // In IMGUI, draw would be called, state becomes Pressed.
    // Then, on next event poll or frame:
    // dummy_im_storage.onMouseButtonEvent(.Left, false); // Release left button
    // This sequence is tricky for unit test without full frame loop.
    // Let's simulate the state `isMouseButtonReleased` would be true for the draw call.
    // The ButtonWidget.draw checks `isMouseButtonReleased`.
    // So, the state should be: prev_mouse_button=true, current_mouse_button=false.
    // To achieve this with current InputManager:
    // Frame A: press event -> next_button_states.Left = true
    // Frame B.prepare: prev=false, current=true (from next of Frame A)
    // Frame B: release event -> next_button_states.Left = false
    // Frame C.prepare: prev=true (from current of Frame B), current=false (from next of Frame B)
    // ButtonWidget.draw in Frame C would see isMouseButtonReleased = true.

    // Simulate state for Frame C where release is detected:
    // 1. Set up prev_button_states for Left = true
    dummy_im_storage.mouse.prev_button_states.set(.Left, true);
    // 2. Set up current_button_states for Left = false (simulating it was just released)
    dummy_im_storage.mouse.button_states.set(.Left, false);
    // 3. Ensure mouse is over button
    dummy_im_storage.mouse.current_x = 75; dummy_im_storage.mouse.current_y = 65;

    clicked = ButtonWidget.draw(&ui_ctx, "btn1", "Test Button", button_pos, button_size);
    try std.testing.expect(clicked);


    // --- Test Case 4: Mouse press inside, release outside (no click) ---
    dummy_im_storage.mouse.prev_button_states.set(.Left, true); // Was pressed
    dummy_im_storage.mouse.button_states.set(.Left, false);    // Now released
    dummy_im_storage.mouse.current_x = 200; dummy_im_storage.mouse.current_y = 200; // Mouse moved outside before release

    clicked = ButtonWidget.draw(&ui_ctx, "btn1", "Test Button", button_pos, button_size);
    try std.testing.expect(!clicked); // Click happened outside


    std.log.info("ButtonWidget.draw test completed.", .{});
}

// Add Gray colors to graphics/color.zig if they don't exist for the test.
// E.g. in `src/graphics/color.zig`:
// pub const Gray = Color{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 1.0 };
// pub const LightGray = Color{ .r = 0.75, .g = 0.75, .b = 0.75, .a = 1.0 };
// pub const DarkGray = Color{ .r = 0.25, .g = 0.25, .b = 0.25, .a = 1.0 };
// The actual test here just logs, doesn't verify colors.
// This comment serves as a reminder for dependencies.
