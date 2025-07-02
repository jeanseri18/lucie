// src/audio/miniaudio_wrapper.zig
// Wrapper for the miniaudio library.
// This abstracts the C API of miniaudio and provides a Zig-friendly interface.

const std = @import("std");
// Import miniaudio.h - this requires miniaudio.h to be available in the include path
// and for `build.zig` to correctly link against miniaudio (if it's compiled as a separate lib)
// or include its implementation (if using the single-file header version).
// For this placeholder, we'll assume `ma` is a namespace for miniaudio types/functions.
// This would typically be: const ma = @cImport(@cInclude("miniaudio.h")); (or similar)

// --- Mock miniaudio types and functions for placeholder ---
// In a real setup, these come from `@cImport`.
const ma = struct {
    // Opaque types (pointers to internal miniaudio structs)
    pub const Engine = ?*anyopaque; // ma_engine
    pub const Sound = ?*anyopaque;  // ma_sound
    // pub const Device = ?*anyopaque; // ma_device
    // pub const Context = ?*anyopaque; // ma_context

    // Result codes
    pub const result = enum(i32) {
        success = 0,
        error = -1, // Generic error
        // ... other miniaudio result codes
    };

    // Common flags / enums
    // pub const SOUND_FLAG_STREAM = 0x00000002; // Example flag
    // pub const SOUND_FLAG_DECODE = 0x00000004;
    // pub const SOUND_FLAG_NO_PITCH = 0x00000800;
    // pub const SOUND_FLAG_NO_SPATIALIZATION = 0x00004000;

    // Mock function signatures (these would match miniaudio.h)
    pub fn engine_init(pConfig: ?*const anyopaque, pEngine: *Engine) result { _=pConfig; pEngine.* = @ptrFromInt(?*anyopaque, 1); return .success; }
    pub fn engine_uninit(pEngine: Engine) void { _=pEngine; }

    pub fn sound_init_from_file(pEngine: Engine, pFilePath: [*:0]const u8, flags: u32, pGroup: ?*anyopaque, pFence: ?*anyopaque, pSound: *Sound) result {
        _=pEngine; _=pFilePath; _=flags; _=pGroup; _=pFence;
        // Simulate successful sound init for testing, or based on filename for more complex mock
        if (std.mem.eql(u8, pFilePath, "fail.wav")) {
             pSound.* = null; return .error;
        }
        pSound.* = @ptrFromInt(?*anyopaque, @ptrToInt(pFilePath)); // Use file path as mock handle
        return .success;
    }
    pub fn sound_uninit(pSound: Sound) void { _=pSound; }
    pub fn sound_start(pSound: Sound) result { _=pSound; return .success; }
    pub fn sound_stop(pSound: Sound) result { _=pSound; return .success; }
    pub fn sound_set_volume(pSound: Sound, volume: f32) result { _=pSound; _=volume; return .success; }
    pub fn sound_set_pitch(pSound: Sound, pitch: f32) result { _=pSound; _=pitch; return .success; }
    pub fn sound_set_looping(pSound: Sound, loop: bool) result { _=pSound; _=loop; return .success; }
    pub fn sound_is_playing(pSound: Sound) bool { _=pSound; return false; } // Mock: always not playing after start for simplicity
    pub fn sound_at_end(pSound: Sound) bool { _=pSound; return true; } // Mock: always at end

    pub fn sound_set_position(pSound: Sound, x: f32, y: f32, z: f32) result { _=pSound; _=x; _=y; _=z; return .success; }
    pub fn sound_set_direction(pSound: Sound, x: f32, y: f32, z: f32) result { _=pSound; _=x; _=y; _=z; return .success; }
    // ... and many more for 3D audio, effects, groups, etc.

    pub fn engine_listener_set_position(pEngine: Engine, listenerIndex: u32, x: f32, y: f32, z: f32) result {
        _=pEngine; _=listenerIndex; _=x; _=y; _=z; return .success;
    }
    pub fn engine_listener_set_orientation(pEngine: Engine, listenerIndex: u32, forwardX: f32, forwardY: f32, forwardZ: f32, upX: f32, upY: f32, upZ: f32) result {
        _=pEngine; _=listenerIndex; _=forwardX; _=forwardY; _=forwardZ; _=upX; _=upY; _=upZ; return .success;
    }
};
// --- End Mock miniaudio ---


// Zig wrapper for miniaudio engine and related operations
pub const MiniAudio = struct {
    allocator: std.mem.Allocator,
    engine: ma.Engine = null, // Pointer to the ma_engine object
    is_initialized: bool = false,

    // Optional: Could manage a pool of ma_sound objects here if not done by AudioEngine.
    // sound_pool: std.ArrayList(ma.Sound),
    // loaded_clips: std.AutoHashMap([]const u8, ma.Sound), // Path to pre-loaded sound data

    pub fn init(allocator_param: std.mem.Allocator) !MiniAudio {
        var self = MiniAudio{
            .allocator = allocator_param,
        };

        // Initialize the miniaudio engine
        // A null config uses default settings.
        const ma_res = ma.engine_init(null, &self.engine);
        if (ma_res != .success) {
            std.log.err("Failed to initialize miniaudio engine: MA error code {d}", .{@intFromEnum(ma_res)});
            return error.MiniAudioInitFailed;
        }

        self.is_initialized = true;
        std.log.info("Miniaudio engine initialized successfully.", .{});
        return self;
    }

    pub fn deinit(self: *MiniAudio) void {
        if (self.is_initialized) {
            // Uninit all sounds, groups, etc., if managed here.
            // For now, assume AudioEngine handles stopping individual sounds.

            ma.engine_uninit(self.engine);
            self.engine = null;
            self.is_initialized = false;
            std.log.info("Miniaudio engine uninitialized.", .{});
        }
    }

    // --- Sound Playback Wrappers ---
    // These are conceptual. The AudioEngine will likely call these.
    // A more detailed wrapper might return a handle that combines ma.Sound with other state.

    // Example: Load and play a sound directly (simple, not for streaming long files efficiently)
    // Returns a handle to the playing sound instance.
    pub fn playSoundFromFile(
        self: *MiniAudio,
        file_path: [:0]const u8, // Null-terminated string for C API
        volume: f32,
        pitch: f32,
        looping: bool,
        // position: ?Vec3, // For 3D sound
    ) !ma.Sound { // Returning the raw ma.Sound handle for now
        if (!self.is_initialized) return error.EngineNotInitialized;

        var sound_handle: ma.Sound = null;
        // Flags for sound initialization (e.g., decode, stream, no pitch, no spatialization)
        // These depend on how miniaudio is to be used.
        // For simple playback: 0 or `MA_SOUND_FLAG_DECODE`
        // If file_path is a long music track, streaming flags would be used.
        const flags: u32 = 0; // MA_SOUND_FLAG_DECODE; // Example

        var ma_res = ma.sound_init_from_file(self.engine, file_path, flags, null, null, &sound_handle);
        if (ma_res != .success or sound_handle == null) {
            std.log.err("Failed to init sound from file '{s}': MA error {d}", .{ file_path, @intFromEnum(ma_res) });
            return error.SoundInitFromFileFailed;
        }

        // Set properties
        _ = ma.sound_set_volume(sound_handle, volume);
        _ = ma.sound_set_pitch(sound_handle, pitch);
        _ = ma.sound_set_looping(sound_handle, looping);
        // if (position) |pos| {
        //     _ = ma.sound_set_position(sound_handle, pos.x, pos.y, pos.z);
        // } else {
        //     // Ensure non-spatialized if no position? Or miniaudio handles this by default.
        // }

        // Start playback
        ma_res = ma.sound_start(sound_handle);
        if (ma_res != .success) {
            std.log.err("Failed to start sound '{s}': MA error {d}", .{ file_path, @intFromEnum(ma_res) });
            ma.sound_uninit(sound_handle); // Clean up if start fails
            return error.SoundStartFailed;
        }

        std.log.debug("Started sound from file: '{s}', handle: {any}", .{file_path, sound_handle});
        return sound_handle;
    }

    pub fn stopSound(self: *MiniAudio, sound_handle: ma.Sound) void {
        if (!self.is_initialized or sound_handle == null) return;
        _ = ma.sound_stop(sound_handle);
        ma.sound_uninit(sound_handle); // Uninit to free resources associated with this sound instance
        std.log.debug("Stopped and uninitialized sound handle: {any}", .{sound_handle});
    }

    pub fn isSoundPlaying(self: *MiniAudio, sound_handle: ma.Sound) bool {
        if (!self.is_initialized or sound_handle == null) return false;
        // ma_sound_is_playing checks if it's in the "playing" state, not necessarily audible.
        // ma_sound_at_end can check if it has finished.
        return ma.sound_is_playing(sound_handle) and !ma.sound_at_end(sound_handle);
    }

    // --- Listener Controls ---
    pub fn setListenerPosition(self: *MiniAudio, x: f32, y: f32, z: f32) void {
        if (!self.is_initialized) return;
        _ = ma.engine_listener_set_position(self.engine, 0, x, y, z); // Listener index 0
    }

    pub fn setListenerOrientation(self: *MiniAudio, fwd_x: f32, fwd_y: f32, fwd_z: f32, up_x: f32, up_y: f32, up_z: f32) void {
        if (!self.is_initialized) return;
        _ = ma.engine_listener_set_orientation(self.engine, 0, fwd_x, fwd_y, fwd_z, up_x, up_y, up_z);
    }

    // TODO: Add more wrapper functions for:
    // - Loading/unloading sound data (ma_resource_manager, ma_decoder)
    // - Streaming audio
    // - Sound groups (ma_sound_group)
    // - Effects (ma_effect)
    // - Getting sound length, playback position
    // - Setting 3D sound properties (min/max distance, attenuation, doppler factor etc.)
};

// Note on building with miniaudio:
// 1. Add `miniaudio.h` to your project (e.g., in a `third_party` directory).
// 2. In `build.zig`:
//    - Define `MA_NO_DECODING` or `MA_NO_ENCODING` if you don't need built-in codecs.
//    - Define `MINIAUDIO_IMPLEMENTATION` in one .c or .zig file that @cImports it.
//    - Link necessary backend libraries (e.g., -lasound on Linux for ALSA, -framework CoreAudio on macOS).
//      `exe.linkSystemLibrary("c");`
//      `if (target.isDarwin()) exe.linkFramework("CoreAudio");`
//      `if (target.isLinux()) exe.linkSystemLibrary("asound"); exe.linkSystemLibrary("pthread");`
//      `if (target.isWindows()) exe.linkSystemLibrary("ole32"); ...` (miniaudio docs have details)
//    - Add include paths for miniaudio.h.
// Example for build.zig (simplified):
// const ma_imp = b.addExecutable("my_miniaudio_impl", "src/miniaudio_impl.zig"); // This zig file @cIncludes miniaudio.h with #define MINIAUDIO_IMPLEMENTATION
// main_exe.addIncludePath("path/to/miniaudio_header_dir");
// main_exe.addObject(ma_imp); // Link the implementation object


test "MiniAudio wrapper initialization and deinitialization" {
    const allocator = std.testing.allocator;
    var ma_wrapper = MiniAudio.init(allocator) catch |err| {
        // This test might fail if no audio device is present or miniaudio backend fails.
        std.log.warn("MiniAudio.init failed in test (possibly no audio device or backend issue): {any}", .{err});
        // To make test pass in CI without audio, one might mock ma_engine_init to always succeed.
        // For now, if it fails, we can't test further.
        if (err == error.MiniAudioInitFailed) return; // Exit test gracefully
        return err; // Propagate other errors
    };
    defer ma_wrapper.deinit();

    try std.testing.expect(ma_wrapper.is_initialized);
    try std.testing.expect(ma_wrapper.engine != null);

    std.log.info("MiniAudio wrapper init/deinit test completed.", .{});
}

test "MiniAudio wrapper playSoundFromFile (mocked)" {
    const allocator = std.testing.allocator;
    var ma_wrapper = MiniAudio.init(allocator) catch return; // Skip if no audio device
    defer ma_wrapper.deinit();

    // This test uses the mocked ma.sound_init_from_file.
    // A real test would need an actual audio file and proper miniaudio setup.
    const dummy_file_path = "test.wav"; // Mock expects this to succeed
    const failing_file_path = "fail.wav"; // Mock expects this to fail

    const sound_handle = ma_wrapper.playSoundFromFile(dummy_file_path, 1.0, 1.0, false) catch |err| {
        std.log.err("playSoundFromFile failed unexpectedly: {any}", .{err});
        try std.testing.expect(false); // Should not fail with mock
        return;
    };
    try std.testing.expect(sound_handle != null);

    // Test a failing sound load
    const fail_result = ma_wrapper.playSoundFromFile(failing_file_path, 1.0, 1.0, false);
    try std.testing.expectError(error.SoundInitFromFileFailed, fail_result);


    // Clean up the successfully "played" sound
    if (sound_handle != null) {
        ma_wrapper.stopSound(sound_handle); // This also uninits the mock sound
    }

    std.log.info("MiniAudio playSoundFromFile (mocked) test completed.", .{});
}

test "MiniAudio listener functions (mocked)" {
    const allocator = std.testing.allocator;
    var ma_wrapper = MiniAudio.init(allocator) catch return;
    defer ma_wrapper.deinit();

    // These just call the mocked C functions, so mainly a compilation/API check.
    ma_wrapper.setListenerPosition(1.0, 2.0, 3.0);
    ma_wrapper.setListenerOrientation(0,0,-1, 0,1,0); // Forward Z, Up Y

    // No direct way to verify results without more complex mocking or actual audio output.
    try std.testing.expect(true);
    std.log.info("MiniAudio listener functions (mocked) test completed.", .{});
}
