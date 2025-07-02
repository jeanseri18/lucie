// src/input/mouse.zig
// Mouse input handling, including position, buttons, and scroll wheel.

const std = @import("std");

// Mouse button enum
pub const MouseButton = enum(u8) {
    Left = 0,
    Right = 1,
    Middle = 2,
    Button4, // Often side/back button
    Button5, // Often side/forward button
    Button6,
    Button7,
    Button8,

    _,

    pub fn count() usize {
        return @typeInfo(MouseButton).Enum.fields.len;
    }
};

pub const Mouse = struct {
    // Current mouse position (e.g., in screen coordinates or window client area coordinates)
    current_x: f32 = 0.0,
    current_y: f32 = 0.0,
    // Previous mouse position (for calculating delta)
    prev_x: f32 = 0.0,
    prev_y: f32 = 0.0,

    // Scroll wheel delta for the current frame
    scroll_x_delta: f32 = 0.0,
    scroll_y_delta: f32 = 0.0, // Most common scroll direction

    // Button states (similar to keyboard)
    button_states: std.enums.EnumArray(MouseButton, bool),
    prev_button_states: std.enums.EnumArray(MouseButton, bool),
    next_button_states: std.enums.EnumArray(MouseButton, bool),

    // Optional: Is mouse cursor currently inside the window client area?
    // is_cursor_in_window: bool = false,

    public fn init() Mouse {
        return Mouse{
            .button_states = .{ .Left = false }, // Initialize all to false
            .prev_button_states = .{ .Left = false },
            .next_button_states = .{ .Left = false },
        };
    }

    // Called at the beginning of each frame.
    pub fn prepareFrame(self: *Mouse) void {
        // Update button states
        self.prev_button_states = self.button_states;
        self.button_states = self.next_button_states;

        // Update previous position for delta calculation
        self.prev_x = self.current_x;
        self.prev_y = self.current_y;

        // Reset scroll delta for the new frame (it's an event, not a persistent state)
        self.scroll_x_delta = 0.0;
        self.scroll_y_delta = 0.0;
    }

    // Called by InputManager when a mouse button event occurs.
    pub fn setButtonState(self: *Mouse, button: MouseButton, is_pressed: bool) void {
        self.next_button_states.set(button, is_pressed);
    }

    // Called by InputManager when mouse moves.
    pub fn updatePosition(self: *Mouse, x: f32, y: f32) void {
        // prev_x, prev_y are updated in prepareFrame.
        // current_x, current_y are updated directly by events.
        self.current_x = x;
        self.current_y = y;
    }

    // Called by InputManager when mouse wheel scrolls.
    // Values are typically small floats representing scroll amount.
    pub fn updateScroll(self: *Mouse, dx: f32, dy: f32) void {
        self.scroll_x_delta += dx;
        self.scroll_y_delta += dy;
    }

    // --- Query methods ---
    pub fn getPosition(self: *const Mouse) struct{x: f32, y: f32} {
        return .{ .x = self.current_x, .y = self.current_y };
    }

    // Returns the change in mouse position since the last frame.
    pub fn getDelta(self: *const Mouse) struct{dx: f32, dy: f32} {
        return .{
            .dx = self.current_x - self.prev_x,
            .dy = self.current_y - self.prev_y,
        };
    }

    pub fn getScrollDelta(self: *const Mouse) struct{dx: f32, dy: f32} {
        return .{ .dx = self.scroll_x_delta, .dy = self.scroll_y_delta };
    }

    pub fn isButtonDown(self: *const Mouse, button: MouseButton) bool {
        return self.button_states.get(button);
    }

    pub fn isButtonPressed(self: *const Mouse, button: MouseButton) bool {
        return self.button_states.get(button) and !self.prev_button_states.get(button);
    }

    pub fn isButtonReleased(self: *const Mouse, button: MouseButton) bool {
        return !self.button_states.get(button) and self.prev_button_states.get(button);
    }
};

test "Mouse states and events" {
    var mouse = Mouse.init();

    // --- Frame 1 ---
    mouse.prepareFrame(); // prev states = false, current states = false
    // Simulate mouse move and left button press
    mouse.updatePosition(10.0, 20.0);
    mouse.setButtonState(.Left, true);
    mouse.updateScroll(0.0, 1.0); // Scrolled up

    // Check intermediate states (current_x/y are updated immediately)
    try std.testing.expect(mouse.current_x == 10.0 and mouse.current_y == 20.0);
    // Button states are still based on 'current_button_states' which is from prev frame's next
    try std.testing.expect(!mouse.isButtonDown(.Left));


    // --- Frame 2 ---
    mouse.prepareFrame(); // Button states updated, prev_pos updated, scroll reset

    // Position and Delta
    var pos = mouse.getPosition();
    try std.testing.expect(pos.x == 10.0 and pos.y == 20.0);
    var delta = mouse.getDelta(); // Delta from (0,0) to (10,20)
    try std.testing.expect(delta.dx == 10.0 and delta.dy == 20.0);

    // Scroll (was reset by prepareFrame, new events would add to it for *this* frame)
    // The scroll delta from Frame 1 is consumed/queried in Frame 1's logic *after* events.
    // If query happens in Frame 2 *after* prepareFrame, scroll delta is for Frame 2 events.
    // Let's adjust how scroll is tested: it's an event accumulated *within* a frame.
    // So, if `updateScroll` happened in Frame 1, `getScrollDelta` in Frame 1 logic (after events, before prepareFrame for F2)
    // would see it. After `prepareFrame` for F2, it's reset.
    // The `prepareFrame` resets scroll_x/y_delta. So, to test, we need to call updateScroll
    // in the same "conceptual frame" we query it.
    // Let's assume query happens after events, before next prepare.
    // The current test structure has prepareFrame at start of block.
    // So, scroll_delta from Frame 1 is available in `mouse` struct *before* Frame 2's `prepareFrame`.
    // The current `prepareFrame` resets it. Let's test it before it's reset:

    // --- Re-evaluating Frame 1's end / Frame 2's beginning logic for scroll ---
    // At end of Frame 1, after events:
    // mouse.scroll_x_delta == 0.0, mouse.scroll_y_delta == 1.0
    // var scroll_f1 = mouse.getScrollDelta(); // This would be called in Frame 1's game loop
    // try std.testing.expect(scroll_f1.dy == 1.0);

    // Now, after Frame 2's prepareFrame:
    var scroll_f2_start = mouse.getScrollDelta(); // Should be (0,0) as it's reset
    try std.testing.expect(scroll_f2_start.dx == 0.0 and scroll_f2_start.dy == 0.0);


    // Button states
    try std.testing.expect(mouse.isButtonDown(.Left));
    try std.testing.expect(mouse.isButtonPressed(.Left));

    // --- Frame 3 ---
    // Simulate mouse move and button release
    mouse.updatePosition(15.0, 25.0);
    mouse.setButtonState(.Left, false);
    mouse.updateScroll(0.5, 0.0); // Scrolled right

    mouse.prepareFrame();

    pos = mouse.getPosition();
    try std.testing.expect(pos.x == 15.0 and pos.y == 25.0);
    delta = mouse.getDelta(); // Delta from (10,20) to (15,25)
    try std.testing.expect(delta.dx == 5.0 and delta.dy == 5.0);

    var scroll_f3 = mouse.getScrollDelta(); // Will be (0,0) because updateScroll was before prepareFrame
                                            // This means scroll events are for "current frame processing"
                                            // Let's simulate scroll event *after* prepareFrame for Frame 3
    // This is how it would typically be structured:
    // Frame N:
    //   mouse.prepareFrame()
    //   Poll events: mouse.updatePosition(), mouse.setButtonState(), mouse.updateScroll()
    //   Game logic: mouse.getPosition(), mouse.isButtonDown(), mouse.getScrollDelta()

    // So, for Frame 3, after prepareFrame, let's simulate a new scroll event for this frame:
    // (mouse.scroll_x_delta and mouse.scroll_y_delta are currently 0.0)
    mouse.updateScroll(0.25, -0.5); // New scroll for Frame 3
    scroll_f3 = mouse.getScrollDelta();
    try std.testing.expect(scroll_f3.dx == 0.25 and scroll_f3.dy == -0.5);


    try std.testing.expect(!mouse.isButtonDown(.Left));
    try std.testing.expect(mouse.isButtonReleased(.Left));

    std.log.info("Mouse states and events test completed.", .{});
}

test "MouseButton enum count" {
    // std.debug.print("MouseButton enum count: {}\n", .{MouseButton.count()});
    try std.testing.expect(MouseButton.count() >= 3); // At least Left, Right, Middle
}
