// src/core/time.zig
// Time management utilities for the engine.
// This includes delta time, timers, and frame rate control.

const std = @import("std");

pub const TimeManager = struct {
    last_frame_time: i64,
    current_time: i64,
    delta_time: f32, // Delta time in seconds

    target_fps: u32,
    frame_duration_ns: i64, // Target frame duration in nanoseconds

    pub fn init(target_fps_param: u32) TimeManager {
        const now = std.time.nanoTimestamp();
        var tm = TimeManager{
            .last_frame_time = now,
            .current_time = now,
            .delta_time = 0.0,
            .target_fps = target_fps_param,
            .frame_duration_ns = if (target_fps_param == 0) 0 else std.time.ns_per_s / target_fps_param,
        };
        tm.update(); // Initial update to set times
        return tm;
    }

    pub fn update(self: *TimeManager) void {
        self.last_frame_time = self.current_time;
        self.current_time = std.time.nanoTimestamp();
        const dt_ns = self.current_time - self.last_frame_time;
        self.delta_time = @intToFloat(f32, dt_ns) / @intToFloat(f32, std.time.ns_per_s);
    }

    // Call at the end of a frame to potentially sleep and meet target FPS
    pub fn capFrameRate(self: *TimeManager) void {
        if (self.target_fps == 0) return; // No FPS cap

        const frame_end_time = std.time.nanoTimestamp();
        const work_time_ns = frame_end_time - self.current_time;
        const sleep_time_ns = self.frame_duration_ns - work_time_ns;

        if (sleep_time_ns > 0) {
            std.time.sleep(@intCast(u64, sleep_time_ns));
        }
        // After sleeping (or not), update current_time for the next frame's delta_time calculation
        // This helps in making delta_time more accurate to the capped frame rate.
        // However, the `update` method called at the beginning of the next frame will overwrite this.
        // A more common pattern is to call `update` at the START of the frame loop.
        // The sleep happens at the END.
    }

    pub fn getDeltaTime(self: *const TimeManager) f32 {
        return self.delta_time;
    }

    pub fn getElapsedTime(self: *const TimeManager, start_time: i64) f32 {
        return @intToFloat(f32, self.current_time - start_time) / @intToFloat(f32, std.time.ns_per_s);
    }

    pub fn getTimestamp(self: *const TimeManager) i64 {
        return self.current_time;
    }
};

// Global timer instance (optional, could be part of Engine)
// var global_time_manager: TimeManager = undefined;

// pub fn initGlobalTimer(target_fps: u32) void {
//     global_time_manager = TimeManager.init(target_fps);
// }

// pub fn updateGlobalTimer() void {
//     global_time_manager.update();
// }

// pub fn capGlobalFrameRate() void {
//     global_time_manager.capFrameRate();
// }

// pub fn getGlobalDeltaTime() f32 {
//     return global_time_manager.getDeltaTime();
// }


test "TimeManager functionality" {
    var tm = TimeManager.init(60); // Target 60 FPS

    // Simulate a few frames
    for (0..5) |_| {
        tm.update();
        std.testing.expect(tm.getDeltaTime() >= 0.0); // Delta time should be non-negative

        // Simulate some work
        std.time.sleep(10 * std.time.ns_per_ms); // Simulate 10ms of work

        tm.capFrameRate(); // Attempt to cap frame rate
    }

    const start = tm.getTimestamp();
    std.time.sleep(50 * std.time.ns_per_ms); // Sleep for 50ms
    tm.update(); // Update time after sleep
    const elapsed = tm.getElapsedTime(start);

    // Check if elapsed time is roughly 0.05 seconds
    // Allow for some tolerance due to sleep inaccuracies
    try std.testing.expect(elapsed > 0.045 and elapsed < 0.055);
}
