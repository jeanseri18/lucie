// src/core/logger.zig
// Logging system with different levels (info, warn, error, debug).

const std = @import("std");

// LogLevel enum defines the severity of a log message.
pub const LogLevel = enum {
    Debug,
    Info,
    Warn,
    Error,

    pub fn toString(self: LogLevel) []const u8 {
        return switch (self) {
            .Debug => "DEBUG",
            .Info => "INFO",
            .Warn => "WARN",
            .Error => "ERROR",
        };
    }
};

// Logger struct - currently a placeholder for a more advanced logger.
// For now, it wraps std.log.
// A more advanced logger might support:
// - Multiple output streams (console, file, network)
// - Log formatting
// - Runtime log level filtering
// - Thread safety (std.log is thread-safe)
pub const Logger = struct {
    min_level: LogLevel,
    // allocator: std.mem.Allocator, // If logger needs to allocate for formatting

    // Initializes the logger with a minimum log level.
    // pub fn init(allocator: std.mem.Allocator, min_level: LogLevel) Logger {
    //     return Logger{ .allocator = allocator, .min_level = min_level };
    // }
    // pub fn deinit(self: *Logger) void {
    //     // Free any resources if necessary
    // }

    // For simplicity, using a global min_level for now, similar to std.log's behavior.
    // A Logger instance could hold its own level.
    // This example will just use std.log directly, which has its own global log level.

    // Helper to get current time as string for logs
    // fn getTimestampString(buffer: []u8) ![]u8 {
    //     const now = std.time.timestamp();
    //     const tm = std.time.epochToCalendar(now);
    //     return try std.fmt.bufPrint(buffer, "{04}-{:02}-{:02} {:02}:{:02}:{:02}", .{
    //         tm.year, tm.month, tm.day, tm.hour, tm.minute, tm.second
    //     });
    // }
};

// Global log functions that use std.log.
// std.log already provides levels like .debug, .info, .warn, .err.
// We can create convenience functions or use std.log directly.

// Example of setting the global log level for std.log
pub fn setLogLevel(level: std.log.Level) void {
    std.log.default_level = level;
}

// Wrapper functions (optional, as std.log can be used directly)
pub fn debug(comptime fmt: []const u8, args: anytype) void {
    std.log.debug(fmt, args);
}

pub fn info(comptime fmt: []const u8, args: anytype) void {
    std.log.info(fmt, args);
}

pub fn warn(comptime fmt: []const u8, args: anytype) void {
    std.log.warn(fmt, args);
}

pub fn err(comptime fmt: []const u8, args: anytype) void {
    std.log.err(fmt, args);
}

// Example of a custom log function that could be part of a Logger struct
// if we were not just wrapping std.log.
// pub fn log(self: *const Logger, level: LogLevel, comptime fmt: []const u8, args: anytype) void {
//     if (@intFromEnum(level) < @intFromEnum(self.min_level)) {
//         return; // Skip logging if below min_level
//     }
//
//     // Basic timestamp and level prefix
//     // var time_buf: [32]u8 = undefined;
//     // const time_str = getTimestampString(&time_buf) catch "NO_TIME";
//     // std.debug.print("{s} [{s}] ", .{time_str, level.toString()});
//
//     // Using std.log which handles its own formatting and output stream (stderr by default)
//     switch (level) {
//         .Debug => std.log.debug(fmt, args),
//         .Info => std.log.info(fmt, args),
//         .Warn => std.log.warn(fmt, args),
//         .Error => std.log.err(fmt, args),
//     }
// }

test "Logger basic functionality" {
    // Store the original log level
    const original_level = std.log.default_level;
    defer std.log.default_level = original_level; // Restore original level

    // Test that messages are printed (visual check or capture stdout/stderr if testing framework supports it)
    // For now, this test mainly ensures the functions compile and run without crashing.

    setLogLevel(.debug); // Set level to debug to see all messages
    std.debug.print("\n--- Logger Test Start ---\n", .{});
    debug("This is a debug message: {d}", .{123});
    info("This is an info message: {s}", .{"hello"});
    warn("This is a warning message: {bool}", .{true});
    err("This is an error message: {any}", .{std.fmt.fmt_ptr(@ptrToInt(undefined))});
    std.debug.print("--- Logger Test End ---\n", .{});

    // Test filtering (std.log does this based on std.log.default_level)
    setLogLevel(.warn); // Only warn and error messages should appear now
    std.debug.print("\n--- Logger Test (Filtered to WARN) ---\n", .{});
    debug("This debug message should NOT be visible.", .{});
    info("This info message should NOT be visible.", .{});
    warn("This warning message SHOULD be visible.", .{});
    err("This error message SHOULD be visible.", .{});
    std.debug.print("--- Logger Test (Filtered to WARN) End ---\n", .{});

    // A simple expectation: these calls should not panic.
    try std.testing.expect(true);
}

test "LogLevel toString" {
    try std.testing.expectEqualStrings("DEBUG", LogLevel.Debug.toString());
    try std.testing.expectEqualStrings("INFO", LogLevel.Info.toString());
    try std.testing.expectEqualStrings("WARN", LogLevel.Warn.toString());
    try std.testing.expectEqualStrings("ERROR", LogLevel.Error.toString());
}
