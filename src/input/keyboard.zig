// src/input/keyboard.zig
// Keyboard input handling, including key states.

const std = @import("std");

// Key enum - represents all supported keyboard keys.
// This can be quite large. Often maps to an underlying library's key codes (e.g., GLFW, SDL).
// For this placeholder, a small subset.
// Values can be arbitrary but should be unique.
pub const Key = enum(u16) { // u16 to accommodate many keys
    Unknown = 0,

    // Letters
    A, B, C, D, E, F, G, H, I, J, K, L, M,
    N, O, P, Q, R, S, T, U, V, W, X, Y, Z,

    // Numbers
    Num0, Num1, Num2, Num3, Num4, Num5, Num6, Num7, Num8, Num9,

    // Function keys
    F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,

    // Control keys
    Space, Enter, Escape, Tab, ShiftLeft, ShiftRight,
    CtrlLeft, CtrlRight, AltLeft, AltRight, SuperLeft, SuperRight, // Super/Win/Cmd key
    Backspace, Delete, Insert,
    Home, End, PageUp, PageDown,

    // Arrow keys
    Up, Down, Left, Right,

    // Numpad
    Kp0, Kp1, Kp2, Kp3, Kp4, Kp5, Kp6, Kp7, Kp8, Kp9,
    KpDecimal, KpDivide, KpMultiply, KpSubtract, KpAdd, KpEnter, KpEqual,

    // Symbols
    Apostrophe, Comma, Minus, Period, Slash, Semicolon, Equal,
    BracketLeft, Backslash, BracketRight, GraveAccent, // `

    // Special
    CapsLock, ScrollLock, NumLock, PrintScreen, Pause, Menu,

    _, // Catch-all for unassigned values, makes the enum non-exhaustive

    pub fn count() usize {
        // This needs to be the actual number of variants for array sizing.
        // `std.meta.fields(Key).len` can get this at comptime.
        return @typeInfo(Key).Enum.fields.len;
    }
};


pub const Keyboard = struct {
    // Stores the state of each key for the current frame.
    key_states: std.enums.EnumArray(Key, bool),
    // Stores the state of each key from the previous frame.
    prev_key_states: std.enums.EnumArray(Key, bool),
    // Stores the "next" state of keys as events come in during a frame.
    // `prepareFrame` will copy this to `key_states`.
    next_key_states: std.enums.EnumArray(Key, bool),

    public fn init() Keyboard {
        return Keyboard{
            .key_states = .{ .A = false }, // Initialize all to false
            .prev_key_states = .{ .A = false },
            .next_key_states = .{ .A = false },
        };
    }

    // Called at the beginning of each frame.
    // Copies current states to previous states, and next states to current states.
    pub fn prepareFrame(self: *Keyboard) void {
        self.prev_key_states = self.key_states;
        self.key_states = self.next_key_states;
        // `next_key_states` remains as is, events during this frame will modify it.
        // Or, if events only set `key_states` directly, then `next_key_states` isn't needed.
        // Let's assume events modify `next_key_states` for clarity of state transitions.
    }

    // Called by InputManager when a key event occurs.
    // Updates the `next_key_states` which will be processed in the next `prepareFrame`.
    pub fn setKeyState(self: *Keyboard, key: Key, is_pressed: bool) void {
        // Ensure key is within bounds if not using EnumArray or if Key can be invalid.
        // EnumArray handles this by design.
        self.next_key_states.set(key, is_pressed);
    }

    // Returns true if the key is currently held down.
    pub fn isKeyDown(self: *const Keyboard, key: Key) bool {
        return self.key_states.get(key);
    }

    // Returns true if the key was just pressed in this frame.
    // (Was up last frame, is down this frame)
    pub fn isKeyPressed(self: *const Keyboard, key: Key) bool {
        return self.key_states.get(key) and !self.prev_key_states.get(key);
    }

    // Returns true if the key was just released in this frame.
    // (Was down last frame, is up this frame)
    pub fn isKeyReleased(self: *const Keyboard, key: Key) bool {
        return !self.key_states.get(key) and self.prev_key_states.get(key);
    }
};

test "Keyboard key states" {
    var keyboard = Keyboard.init();

    // --- Frame 1 ---
    keyboard.prepareFrame(); // prev=false, current=false, next=false (initially)

    // Simulate key press event for 'A'
    keyboard.setKeyState(.A, true); // next_key_states.A = true

    // At this point in Frame 1, after event but before next prepareFrame:
    // isKeyDown(.A) should be false (checks current_states)
    // isKeyPressed(.A) should be false (current=false, prev=false)
    try std.testing.expect(!keyboard.isKeyDown(.A));
    try std.testing.expect(!keyboard.isKeyPressed(.A));


    // --- Frame 2 ---
    keyboard.prepareFrame(); // prev_key_states.A = false (from current_states of F1)
                             // key_states.A = true (from next_key_states of F1)
                             // next_key_states.A remains true (or could be reset if desired)

    // Check states in Frame 2's update loop
    try std.testing.expect(keyboard.isKeyDown(.A));      // A is down
    try std.testing.expect(keyboard.isKeyPressed(.A));   // A was pressed (up last frame, down this frame)
    try std.testing.expect(!keyboard.isKeyReleased(.A)); // A was not released


    // --- Frame 3 (A still held) ---
    // No new event for A, so next_key_states.A is still true (from previous setKeyState)
    // Or, if events are polled every frame: setKeyState(.A, true) would be called again.
    // Let's assume setKeyState reflects the *current event state*. If no event, state persists in next_*.
    // If key 'A' is still held, the windowing system would report it as pressed.
    keyboard.setKeyState(.A, true); // Event: A is still pressed

    keyboard.prepareFrame(); // prev_key_states.A = true (from current_states of F2)
                             // key_states.A = true (from next_key_states of F2)

    try std.testing.expect(keyboard.isKeyDown(.A));      // A is still down
    try std.testing.expect(!keyboard.isKeyPressed(.A));  // A was not *just* pressed (was already down)
    try std.testing.expect(!keyboard.isKeyReleased(.A));


    // --- Frame 4 (A released) ---
    keyboard.setKeyState(.A, false); // Event: A is released

    keyboard.prepareFrame(); // prev_key_states.A = true
                             // key_states.A = false

    try std.testing.expect(!keyboard.isKeyDown(.A));     // A is now up
    try std.testing.expect(!keyboard.isKeyPressed(.A));  // A was not pressed
    try std.testing.expect(keyboard.isKeyReleased(.A));  // A was released (was down, now up)

    // --- Frame 5 (A still released) ---
    keyboard.setKeyState(.A, false); // Event: A is still not pressed

    keyboard.prepareFrame(); // prev_key_states.A = false
                             // key_states.A = false

    try std.testing.expect(!keyboard.isKeyDown(.A));
    try std.testing.expect(!keyboard.isKeyPressed(.A));
    try std.testing.expect(!keyboard.isKeyReleased(.A)); // Was not *just* released

    std.log.info("Keyboard key states test completed.", .{});
}

test "Key enum count" {
    // This is a basic check. The actual count depends on the number of variants defined.
    // std.debug.print("Key enum count: {}\n", .{Key.count()});
    try std.testing.expect(Key.count() > 50); // Expecting a reasonable number of keys
}
