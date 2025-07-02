// src/lucie.zig
// Main API for the Lucie Framework

const app = @import("core/application.zig");

pub const Application = app.Application;

// Other public exports will go here
// e.g., pub const Engine = @import("core/engine.zig").Engine;
// pub const log = @import("core/logger.zig");
// ... and so on for other modules
test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.popOrNull().?);
}

const std = @import("std");
