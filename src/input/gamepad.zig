// src/input/gamepad.zig
// Gamepad input handling.

const std = @import("std");

// Gamepad button enum - common layout (e.g., Xbox/PlayStation style)
// Values can be arbitrary, map to underlying library codes.
pub const GamepadButton = enum(u8) {
    // Face buttons
    A = 0, // South button (Xbox A, PS Cross)
    B = 1, // East button (Xbox B, PS Circle)
    X = 2, // West button (Xbox X, PS Square)
    Y = 3, // North button (Xbox Y, PS Triangle)

    // Shoulder buttons
    LeftBumper = 4,
    RightBumper = 5,
    // Triggers are often axes, but can be buttons if only digital input is needed/available
    // LeftTriggerButton,
    // RightTriggerButton,

    // D-pad (can also be axes or individual buttons)
    DpadUp = 6,
    DpadDown = 7,
    DpadLeft = 8,
    DpadRight = 9,

    // Special buttons
    Back = 10,    // Xbox Back, PS Share/Select
    Start = 11,   // Xbox Start, PS Options/Start
    Guide = 12,   // Xbox Guide, PS Home button

    // Stick clicks
    LeftStick = 13,
    RightStick = 14,

    // Misc/Vendor specific
    // Paddle1, Paddle2, Paddle3, Paddle4,
    // TouchpadButton,

    _, // Non-exhaustive

    pub fn count() usize {
        return @typeInfo(GamepadButton).Enum.fields.len;
    }
};

// Gamepad axis enum
pub const GamepadAxis = enum(u8) {
    LeftStickX = 0,
    LeftStickY = 1,
    RightStickX = 2,
    RightStickY = 3,
    LeftTrigger = 4,  // Typically 0 (released) to 1 (fully pressed)
    RightTrigger = 5, // Or -1 to 1 if centered. Gamepad libraries vary.

    _, // Non-exhaustive

    pub fn count() usize {
        return @typeInfo(GamepadAxis).Enum.fields.len;
    }
};


pub const Gamepad = struct {
    id: u8, // ID of the gamepad (0-N)
    is_connected: bool = false,
    // name: []const u8 = "Unknown Gamepad", // Optional: Name/identifier string

    // Button states
    button_states: std.enums.EnumArray(GamepadButton, bool),
    prev_button_states: std.enums.EnumArray(GamepadButton, bool),
    next_button_states: std.enums.EnumArray(GamepadButton, bool),

    // Axis states (values typically -1.0 to 1.0 for sticks, 0.0 to 1.0 for triggers)
    axis_values: std.enums.EnumArray(GamepadAxis, f32),
    // prev_axis_values: std.enums.EnumArray(GamepadAxis, f32), // If axis "pressed/released" needed

    // Deadzone for analog sticks (to prevent drift from minor imperfections)
    // Applied when querying axis values.
    stick_deadzone_left: f32 = 0.15,  // Default typical deadzone
    stick_deadzone_right: f32 = 0.15,
    trigger_threshold: f32 = 0.1, // For treating triggers as "pressed" if value > threshold

    public fn init(gamepad_id: u8) Gamepad {
        return Gamepad{
            .id = gamepad_id,
            .button_states = .{ .A = false }, // All false
            .prev_button_states = .{ .A = false },
            .next_button_states = .{ .A = false },
            .axis_values = .{ .LeftStickX = 0.0 }, // All 0.0
        };
    }

    pub fn prepareFrame(self: *Gamepad) void {
        if (!self.is_connected) return;

        self.prev_button_states = self.button_states;
        self.button_states = self.next_button_states;
        // self.prev_axis_values = self.axis_values; // If tracking axis changes like buttons
    }

    pub fn setConnected(self: *Gamepad, connected_status: bool) void {
        self.is_connected = connected_status;
        if (!connected_status) {
            // Reset states if disconnected
            self.button_states = .{ .A = false };
            self.prev_button_states = .{ .A = false };
            self.next_button_states = .{ .A = false };
            self.axis_values = .{ .LeftStickX = 0.0 };
        }
    }

    pub fn setButtonState(self: *Gamepad, button: GamepadButton, is_pressed: bool) void {
        if (!self.is_connected) return;
        self.next_button_states.set(button, is_pressed);
    }

    pub fn setAxisValue(self: *Gamepad, axis: GamepadAxis, value: f32) void {
        if (!self.is_connected) return;
        // Clamp axis value (e.g. to -1.0 to 1.0 for sticks)
        // This depends on raw input range. Assuming it's already in a good range.
        var clamped_value = value;
        if (axis == .LeftStickX or axis == .LeftStickY or axis == .RightStickX or axis == .RightStickY) {
             clamped_value = std.math.clamp(value, -1.0, 1.0);
        } else if (axis == .LeftTrigger or axis == .RightTrigger) {
             clamped_value = std.math.clamp(value, 0.0, 1.0); // Assuming triggers are 0-1 range
        }
        self.axis_values.set(axis, clamped_value);
    }

    // --- Query methods ---
    pub fn isButtonDown(self: *const Gamepad, button: GamepadButton) bool {
        if (!self.is_connected) return false;
        return self.button_states.get(button);
    }

    pub fn isButtonPressed(self: *const Gamepad, button: GamepadButton) bool {
        if (!self.is_connected) return false;
        return self.button_states.get(button) and !self.prev_button_states.get(button);
    }

    pub fn isButtonReleased(self: *const Gamepad, button: GamepadButton) bool {
        if (!self.is_connected) return false;
        return !self.button_states.get(button) and self.prev_button_states.get(button);
    }

    pub fn getAxisValue(self: *const Gamepad, axis: GamepadAxis) f32 {
        if (!self.is_connected) return 0.0;

        var raw_value = self.axis_values.get(axis);

        // Apply deadzone for sticks
        const deadzone = switch (axis) {
            .LeftStickX, .LeftStickY => self.stick_deadzone_left,
            .RightStickX, .RightStickY => self.stick_deadzone_right,
            else => 0.0, // No deadzone for triggers or other axes by default
        };

        if (std.math.fabs(raw_value) < deadzone) {
            return 0.0;
        }

        // Optional: Remap deadzoned value to full range [0, 1] or [-1, 1]
        // E.g., for a stick axis:
        if (deadzone > 0.0 and (axis == .LeftStickX or axis == .LeftStickY or axis == .RightStickX or axis == .RightStickY)) {
            const sign = if (raw_value > 0) 1.0 else -1.0;
            const normalized_value = (std.math.fabs(raw_value) - deadzone) / (1.0 - deadzone);
            return sign * std.math.clamp(normalized_value, 0.0, 1.0);
        }

        return raw_value;
    }

    // Helper for treating triggers like buttons
    pub fn isLeftTriggerPressed(self: *const Gamepad) bool {
        return self.getAxisValue(.LeftTrigger) > self.trigger_threshold;
    }
    pub fn isRightTriggerPressed(self: *const Gamepad) bool {
        return self.getAxisValue(.RightTrigger) > self.trigger_threshold;
    }
};

test "Gamepad states and events" {
    var gamepad = Gamepad.init(0);
    gamepad.setConnected(true); // Connect the gamepad for testing

    // --- Frame 1 ---
    gamepad.prepareFrame();
    // Simulate button A press and Left Stick X movement
    gamepad.setButtonState(.A, true);
    gamepad.setAxisValue(.LeftStickX, 0.8);

    // --- Frame 2 ---
    gamepad.prepareFrame();
    try std.testing.expect(gamepad.isButtonDown(.A));
    try std.testing.expect(gamepad.isButtonPressed(.A));
    try std.testing.expect(std.math.approxEqAbs(gamepad.getAxisValue(.LeftStickX), 0.8, 0.001) or
                           (0.8 > gamepad.stick_deadzone_left and gamepad.getAxisValue(.LeftStickX) > 0.0) ); // Check with deadzone logic


    // --- Frame 3 (Button A released, stick moved) ---
    gamepad.setButtonState(.A, false);
    gamepad.setAxisValue(.LeftStickX, -0.1); // Inside deadzone if default 0.15

    gamepad.prepareFrame();
    try std.testing.expect(!gamepad.isButtonDown(.A));
    try std.testing.expect(gamepad.isButtonReleased(.A));
    // Test deadzone: -0.1 should be treated as 0.0 if deadzone is 0.15
    try std.testing.expect(std.math.approxEqAbs(gamepad.getAxisValue(.LeftStickX), 0.0, 0.001));

    // Test axis value outside deadzone but remapped
    gamepad.setAxisValue(.LeftStickX, 0.5); // Raw value 0.5
    // If deadzone is 0.15, range is 0.85. (0.5 - 0.15) / 0.85 = 0.35 / 0.85 approx 0.4117
    const expected_remapped = (0.5 - gamepad.stick_deadzone_left) / (1.0 - gamepad.stick_deadzone_left);
    try std.testing.expect(std.math.approxEqAbs(gamepad.getAxisValue(.LeftStickX), expected_remapped, 0.001));


    // Test disconnection
    gamepad.setConnected(false);
    try std.testing.expect(!gamepad.is_connected);
    try std.testing.expect(!gamepad.isButtonDown(.A)); // Should be false when disconnected
    try std.testing.expect(gamepad.getAxisValue(.LeftStickX) == 0.0); // Should be 0 when disconnected

    std.log.info("Gamepad states and events test completed.", .{});
}

test "GamepadButton and GamepadAxis enum counts" {
    // std.debug.print("GamepadButton enum count: {}\n", .{GamepadButton.count()});
    // std.debug.print("GamepadAxis enum count: {}\n", .{GamepadAxis.count()});
    try std.testing.expect(GamepadButton.count() >= 14); // Check against defined common buttons
    try std.testing.expect(GamepadAxis.count() >= 6);   // Check against defined common axes
}
