// src/input/input_manager.zig
// Manages all input sources (keyboard, mouse, gamepad).

const std = @import("std");
const Keyboard = @import("keyboard.zig").Keyboard;
const Mouse = @import("mouse.zig").Mouse;
const Gamepad = @import("gamepad.zig").Gamepad; // Assuming Gamepad struct definition
const Key = @import("keyboard.zig").Key; // For Key enum
const MouseButton = @import("mouse.zig").MouseButton; // For MouseButton enum

// Max number of gamepads supported (can be configured)
const MAX_GAMEPADS = 4;

pub const InputManager = struct {
    allocator: std.mem.Allocator,

    keyboard: Keyboard,
    mouse: Mouse,
    gamepads: [MAX_GAMEPADS]Gamepad, // Array of gamepad states

    // Optional: For text input events
    // text_input_buffer: std.ArrayList(u8), // Buffer for characters entered this frame

    // Optional: Window focus state
    // is_window_focused: bool = true,

    pub fn init(allocator_param: std.mem.Allocator) InputManager {
        std.log.debug("Initializing InputManager...", .{});
        var self = InputManager{
            .allocator = allocator_param,
            .keyboard = Keyboard.init(),
            .mouse = Mouse.init(),
            .gamepads = undefined, // Needs to be initialized in a loop
            // .text_input_buffer = std.ArrayList(u8).init(allocator_param),
        };

        // Initialize gamepads
        for (self.gamepads) |*pad, i| {
            pad.* = Gamepad.init(@intCast(u8, i)); // Pass gamepad ID
        }
        return self;
    }

    pub fn deinit(self: *InputManager) void {
        std.log.debug("Deinitializing InputManager...", .{});
        // self.text_input_buffer.deinit();
        // Keyboard and Mouse might not need deinit if they don't allocate.
        // Gamepads also, unless they hold allocated resources.
        _ = self; // For now, no explicit deinit needed for sub-modules if they are simple structs.
    }

    // Called at the beginning of each frame to update current state from previous frame's state.
    // This is crucial for `isKeyPressed` / `isKeyReleased` logic.
    pub fn prepareFrame(self: *InputManager) void {
        self.keyboard.prepareFrame();
        self.mouse.prepareFrame();
        for (self.gamepads) |*pad| {
            pad.prepareFrame();
        }
        // self.text_input_buffer.shrinkRetainingCapacity(0); // Clear text input from last frame
    }

    // Event handling methods (called by the application/windowing system)
    // These update the 'next_state' of keys/buttons. `prepareFrame` then copies next_state to current_state.

    pub fn onKeyEvent(self: *InputManager, key: Key, is_pressed: bool) void {
        self.keyboard.setKeyState(key, is_pressed);
    }

    pub fn onMouseButtonEvent(self: *InputManager, button: MouseButton, is_pressed: bool) void {
        self.mouse.setButtonState(button, is_pressed);
    }

    pub fn onMouseMoveEvent(self: *InputManager, x: f32, y: f32) void {
        self.mouse.updatePosition(x, y);
    }

    pub fn onMouseWheelEvent(self: *InputManager, scroll_x: f32, scroll_y: f32) void {
        self.mouse.updateScroll(scroll_x, scroll_y);
    }

    // pub fn onTextInputEvent(self: *InputManager, text_codepoint: u21) void {
    //     // Convert codepoint to UTF-8 and append to buffer
    //     var buf: [4]u8 = undefined;
    //     const len = std.unicode.utf8Encode(text_codepoint, &buf) catch 0;
    //     if (len > 0) {
    //         self.text_input_buffer.appendSlice(buf[0..len]) catch {};
    //     }
    // }

    pub fn onGamepadConnectEvent(self: *InputManager, gamepad_id: u8, is_connected: bool) void {
        if (gamepad_id < MAX_GAMEPADS) {
            self.gamepads[gamepad_id].setConnected(is_connected);
            const status_str = if (is_connected) "connected" else "disconnected";
            std.log.info("Gamepad {d} {s}", .{gamepad_id, status_str});
        }
    }

    pub fn onGamepadButtonEvent(self: *InputManager, gamepad_id: u8, button: Gamepad.Button, is_pressed: bool) void {
        if (gamepad_id < MAX_GAMEPADS and self.gamepads[gamepad_id].is_connected) {
            self.gamepads[gamepad_id].setButtonState(button, is_pressed);
        }
    }

    pub fn onGamepadAxisEvent(self: *InputManager, gamepad_id: u8, axis: Gamepad.Axis, value: f32) void {
         if (gamepad_id < MAX_GAMEPADS and self.gamepads[gamepad_id].is_connected) {
            self.gamepads[gamepad_id].setAxisValue(axis, value);
        }
    }

    // --- Query methods ---
    // Keyboard
    pub fn isKeyDown(self: *const InputManager, key: Key) bool {
        return self.keyboard.isKeyDown(key);
    }
    pub fn isKeyPressed(self: *const InputManager, key: Key) bool {
        return self.keyboard.isKeyPressed(key);
    }
    pub fn isKeyReleased(self: *const InputManager, key: Key) bool {
        return self.keyboard.isKeyReleased(key);
    }

    // Mouse
    pub fn getMousePosition(self: *const InputManager) struct{x: f32, y: f32} {
        return self.mouse.getPosition();
    }
    pub fn getMouseDelta(self: *const InputManager) struct{dx: f32, dy: f32} {
        return self.mouse.getDelta();
    }
    pub fn getMouseScrollDelta(self: *const InputManager) struct{dx: f32, dy: f32} {
        return self.mouse.getScrollDelta();
    }
    pub fn isMouseButtonDown(self: *const InputManager, button: MouseButton) bool {
        return self.mouse.isButtonDown(button);
    }
    pub fn isMouseButtonPressed(self: *const InputManager, button: MouseButton) bool {
        return self.mouse.isButtonPressed(button);
    }
    pub fn isMouseButtonReleased(self: *const InputManager, button: MouseButton) bool {
        return self.mouse.isButtonReleased(button);
    }

    // Gamepad
    pub fn isGamepadConnected(self: *const InputManager, gamepad_id: u8) bool {
        return gamepad_id < MAX_GAMEPADS and self.gamepads[gamepad_id].is_connected;
    }
    pub fn isGamepadButtonDown(self: *const InputManager, gamepad_id: u8, button: Gamepad.Button) bool {
        if (!self.isGamepadConnected(gamepad_id)) return false;
        return self.gamepads[gamepad_id].isButtonDown(button);
    }
    pub fn isGamepadButtonPressed(self: *const InputManager, gamepad_id: u8, button: Gamepad.Button) bool {
        if (!self.isGamepadConnected(gamepad_id)) return false;
        return self.gamepads[gamepad_id].isButtonPressed(button);
    }
    pub fn isGamepadButtonReleased(self: *const InputManager, gamepad_id: u8, button: Gamepad.Button) bool {
        if (!self.isGamepadConnected(gamepad_id)) return false;
        return self.gamepads[gamepad_id].isButtonReleased(button);
    }
    pub fn getGamepadAxisValue(self: *const InputManager, gamepad_id: u8, axis: Gamepad.Axis) f32 {
        if (!self.isGamepadConnected(gamepad_id)) return 0.0;
        return self.gamepads[gamepad_id].getAxisValue(axis);
    }

    // pub fn getTextInput(self: *const InputManager) []const u8 {
    //     return self.text_input_buffer.items;
    // }
};

test "InputManager initialization" {
    const allocator = std.testing.allocator;
    var input_manager = InputManager.init(allocator);
    defer input_manager.deinit();

    // Check if sub-modules are initialized (basic check)
    try std.testing.expect(input_manager.keyboard.key_states.count() > 0); // Assuming Keyboard keys are non-zero
    try std.testing.expect(input_manager.mouse.current_x == 0.0);
    try std.testing.expect(input_manager.gamepads[0].id == 0);
    try std.testing.expect(input_manager.gamepads[MAX_GAMEPADS-1].id == MAX_GAMEPADS-1);

    std.log.info("InputManager initialization test completed.", .{});
}

test "InputManager event processing and state querying" {
    const allocator = std.testing.allocator;
    var im = InputManager.init(allocator);
    defer im.deinit();

    // --- Frame 1 ---
    im.prepareFrame();
    // Simulate 'A' key press event
    im.onKeyEvent(.A, true);
    // Simulate mouse button 1 press event
    im.onMouseButtonEvent(.Left, true);
    // Simulate mouse move
    im.onMouseMoveEvent(100.0, 200.0);
    // Simulate gamepad 0 button A press
    im.onGamepadConnectEvent(0, true); // Connect gamepad 0
    im.onGamepadButtonEvent(0, .A, true);


    // At this point, 'next_state' is updated. 'current_state' is still from previous frame (all false/zero).
    // isKeyDown/Pressed should reflect 'next_state' if called mid-frame after event, OR reflect 'current_state'
    // if called after prepareFrame(). This depends on design.
    // The Keyboard/Mouse structs use `isKeyDown` on `current_state` and `isKeyPressed` by comparing current and previous.
    // So, after events but before next `prepareFrame`, `isKeyDown` will be false, `isKeyPressed` will be false.
    // This means query methods are typically used in the *next* frame's update loop, after prepareFrame().

    // --- Frame 2 ---
    im.prepareFrame(); // current_state now reflects frame 1's events.

    // Keyboard checks
    try std.testing.expect(im.isKeyDown(.A));
    try std.testing.expect(im.isKeyPressed(.A)); // Pressed in this frame (transitioned from up to down)
    try std.testing.expect(!im.isKeyReleased(.A));
    try std.testing.expect(!im.isKeyDown(.B));

    // Mouse checks
    try std.testing.expect(im.isMouseButtonDown(.Left));
    try std.testing.expect(im.isMouseButtonPressed(.Left));
    const mouse_pos = im.getMousePosition();
    try std.testing.expect(mouse_pos.x == 100.0 and mouse_pos.y == 200.0);
    // Mouse delta would be (100,200) if previous was (0,0)

    // Gamepad checks
    try std.testing.expect(im.isGamepadConnected(0));
    try std.testing.expect(im.isGamepadButtonDown(0, .A));
    try std.testing.expect(im.isGamepadButtonPressed(0, .A));


    // --- Frame 3 ---
    // Simulate 'A' key release, Mouse button 1 release, Gamepad button A release
    // Mouse moves again
    im.onKeyEvent(.A, false);
    im.onMouseButtonEvent(.Left, false);
    im.onGamepadButtonEvent(0, .A, false);
    im.onMouseMoveEvent(110.0, 220.0);

    im.prepareFrame(); // current_state updated for frame 3 logic

    // Keyboard checks
    try std.testing.expect(!im.isKeyDown(.A));      // A is now up
    try std.testing.expect(!im.isKeyPressed(.A));   // A was down, now up (not a new press)
    try std.testing.expect(im.isKeyReleased(.A)); // A was released this frame

    // Mouse checks
    try std.testing.expect(!im.isMouseButtonDown(.Left));
    try std.testing.expect(!im.isMouseButtonPressed(.Left));
    try std.testing.expect(im.isMouseButtonReleased(.Left));
    const new_mouse_pos = im.getMousePosition();
    try std.testing.expect(new_mouse_pos.x == 110.0 and new_mouse_pos.y == 220.0);
    const mouse_delta = im.getMouseDelta();
    try std.testing.expect(mouse_delta.dx == 10.0 and mouse_delta.dy == 20.0);

    // Gamepad checks
    try std.testing.expect(!im.isGamepadButtonDown(0, .A));
    try std.testing.expect(im.isGamepadButtonReleased(0, .A));

    std.log.info("InputManager event processing and state querying test completed.", .{});
}
