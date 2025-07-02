// src/audio/audio_engine.zig
// Main audio engine: initializes audio backend, manages sounds and music.

const std = @import("std");
const MiniAudio = @import("miniaudio_wrapper.zig").MiniAudio; // Using the wrapper for miniaudio
const AudioSourceComponent = @import("../ecs/components/audio_source.zig").AudioSourceComponent; // For source properties
const AudioClipHandle = @import("../ecs/components/audio_source.zig").AudioClipHandle;
const Vec3 = @import("../math/vec3.zig").Vec3; // For 3D audio positions
// const AudioListener = @import("audio_listener.zig").AudioListener; // For 3D audio

// Max number of concurrent sound instances (voices) the engine can play.
// This is a common limitation in audio engines.
const MAX_PLAYING_SOUNDS = 256; // Example value

// Represents an active sound being played by the engine.
// This is different from an AudioSourceComponent, which is a definition/request.
// An PlayingSound is a live instance.
pub const PlayingSound = struct {
    // sound_handle: MiniAudio.SoundHandle, // Handle from miniaudio for this playing instance
    clip_handle: AudioClipHandle, // Original clip that was played
    // entity_id: ?Entity, // Entity that owns this sound (if spatialized from a component)

    is_active: bool = false,
    is_looping: bool = false,
    volume: f32 = 1.0,
    pitch: f32 = 1.0,
    // current_play_time: f32 = 0.0, // Tracked by miniaudio mostly

    // For 3D sounds
    is_spatialized: bool = false,
    position: Vec3 = Vec3.zero(),
    // min_distance: f32 = 1.0,
    // max_distance: f32 = 50.0,
    // attenuation: AudioSourceComponent.AttenuationModel = .Logarithmic,

    // Internal ID for this playing sound slot
    slot_id: usize,

    // TODO: Add reference to the miniaudio sound object (`ma_sound`) if needed for direct manipulation.
    // For now, assume miniaudio_wrapper handles this via its own sound handles.
};


pub const AudioEngine = struct {
    allocator: std.mem.Allocator,
    miniaudio: MiniAudio, // The underlying miniaudio instance

    // Pool of playing sound instances.
    // When a sound finishes, its slot can be reused.
    playing_sounds_pool: [MAX_PLAYING_SOUNDS]PlayingSound,
    active_sound_count: usize = 0,

    // Global properties
    master_volume: f32 = 1.0,
    // current_listener: AudioListener = AudioListener.default(), // For 3D audio

    pub fn init(allocator_param: std.mem.Allocator) !AudioEngine {
        std.log.debug("Initializing AudioEngine...", .{});
        var ma_instance = try MiniAudio.init(allocator_param);

        var self = AudioEngine{
            .allocator = allocator_param,
            .miniaudio = ma_instance,
            .playing_sounds_pool = undefined,
        };

        // Initialize the playing sounds pool
        for (self.playing_sounds_pool) |*sound_slot, i| {
            sound_slot.* = PlayingSound { .slot_id = i }; // Mark as inactive, set slot_id
        }

        std.log.info("AudioEngine initialized successfully using miniaudio.", .{});
        return self;
    }

    pub fn deinit(self: *AudioEngine) void {
        std.log.debug("Deinitializing AudioEngine...", .{});
        // Stop all sounds
        self.stopAllSounds();

        self.miniaudio.deinit();
        // Pool items don't need individual deinit unless PlayingSound allocates memory.
    }

    // Called periodically (e.g., once per frame) to update sound states,
    // manage finished sounds, update 3D positions, etc.
    pub fn update(self: *AudioEngine /*, listener_pos: Vec3, listener_orientation: Mat4 */) void {
        // Update listener position for 3D audio (if miniaudio needs it per frame)
        // self.miniaudio.setListenerPosition(self.current_listener.position, ...);

        // Iterate active sounds
        var i: usize = 0;
        while (i < MAX_PLAYING_SOUNDS) : (i += 1) {
            var sound_slot = &self.playing_sounds_pool[i];
            if (sound_slot.is_active) {
                // Check if miniaudio sound instance has finished playing
                // if (self.miniaudio.isSoundPlaying(sound_slot.sound_handle) == false) {
                //    std.log.debug("Sound slot {d} (clip {any}) finished playing.", .{i, sound_slot.clip_handle});
                //    sound_slot.is_active = false; // Free up the slot
                //    self.active_sound_count -=1;
                //    // Optionally, release the miniaudio sound handle from the wrapper
                //    // self.miniaudio.releaseSound(sound_slot.sound_handle);
                // } else {
                //    // If spatialized, update its position if it moved
                //    if (sound_slot.is_spatialized) {
                //        // self.miniaudio.setSoundPosition(sound_slot.sound_handle, sound_slot.position);
                //    }
                //    // Update volume/pitch if changed dynamically
                //    // self.miniaudio.setSoundVolume(sound_slot.sound_handle, sound_slot.volume * self.master_volume);
                //    // self.miniaudio.setSoundPitch(sound_slot.sound_handle, sound_slot.pitch);
                // }
            }
        }
        // This loop is a placeholder. Actual management depends on miniaudio_wrapper's capabilities.
        // The wrapper might handle finished sounds internally or provide callbacks.
    }

    fn findFreePlayingSoundSlot(self: *AudioEngine) ?*PlayingSound {
        if (self.active_sound_count >= MAX_PLAYING_SOUNDS) {
            std.log.warn("AudioEngine: No free sound slots available (max {d} reached).", .{MAX_PLAYING_SOUNDS});
            return null;
        }
        for (self.playing_sounds_pool) |*slot, i| {
            if (!slot.is_active) {
                self.active_sound_count += 1;
                slot.is_active = true; // Mark as active immediately
                std.log.debug("Found free sound slot: {d}", .{i});
                return slot;
            }
        }
        return null; // Should not happen if active_sound_count is correct
    }

    // --- Playback Control ---

    // Play a sound based on an AudioSourceComponent's properties.
    // This is a high-level function typically called by an audio system or game logic.
    pub fn playSoundFromComponent(
        self: *AudioEngine,
        source_comp: *const AudioSourceComponent,
        // entity_id_param: ?Entity, // If linking PlayingSound back to entity
        position_3d: ?Vec3, // World position for spatialized sounds
    ) void {
        if (source_comp.clip_handle == 0) { // Assuming 0 is invalid handle
            std.log.warn("Attempted to play sound with invalid clip_handle (0).", .{});
            return;
        }

        var playing_sound_slot = self.findFreePlayingSoundSlot() orelse return;

        // Configure the playing sound instance from the component
        playing_sound_slot.clip_handle = source_comp.clip_handle;
        // playing_sound_slot.entity_id = entity_id_param;
        playing_sound_slot.is_looping = source_comp.looping;
        playing_sound_slot.volume = source_comp.volume;
        playing_sound_slot.pitch = source_comp.pitch;
        playing_sound_slot.is_spatialized = source_comp.is_spatialized;

        if (source_comp.is_spatialized and position_3d != null) {
            playing_sound_slot.position = position_3d.?;
            // playing_sound_slot.min_distance = source_comp.min_distance;
            // playing_sound_slot.max_distance = source_comp.max_distance;
            // playing_sound_slot.attenuation = source_comp.attenuation_model;
        } else {
            playing_sound_slot.is_spatialized = false; // Ensure not spatialized if no position
        }

        std.log.debug("Requesting play for clip {any} in slot {d}. Spatialized: {b}, Loop: {b}, Vol: {d:.2}, Pitch: {d:.2}", .{
            playing_sound_slot.clip_handle,
            playing_sound_slot.slot_id,
            playing_sound_slot.is_spatialized,
            playing_sound_slot.is_looping,
            playing_sound_slot.volume,
            playing_sound_slot.pitch,
        });

        // TODO: Call miniaudio_wrapper to actually play the sound.
        // This would involve:
        // 1. Getting a `ma_sound` object from miniaudio, possibly from a pool in the wrapper.
        // 2. Loading the audio data for `clip_handle` into it (if not already loaded/cached).
        // 3. Setting its properties (volume, pitch, looping, 3D position if spatialized).
        // 4. Starting playback.
        // 5. Storing the `ma_sound` handle/reference in `playing_sound_slot.sound_handle`.

        // Example placeholder call:
        // playing_sound_slot.sound_handle = self.miniaudio.playSound(
        //     playing_sound_slot.clip_handle,
        //     playing_sound_slot.volume * self.master_volume,
        //     playing_sound_slot.pitch,
        //     playing_sound_slot.is_looping,
        //     if (playing_sound_slot.is_spatialized) playing_sound_slot.position else null,
        //     // ... other 3D params ...
        // ) catch |err| {
        //     std.log.err("Failed to play sound clip {any}: {any}", .{playing_sound_slot.clip_handle, err});
        //     playing_sound_slot.is_active = false; // Free slot on failure
        //     self.active_sound_count -=1;
        //     return;
        // };
        // std.log.info("AudioEngine: Started sound in slot {d} with handle {any}", .{playing_sound_slot.slot_id, playing_sound_slot.sound_handle});
    }

    // Play a sound by its clip handle directly (non-component based)
    pub fn playSound2D(self: *AudioEngine, clip: AudioClipHandle, volume: f32, pitch: f32, looping: bool) void {
        // Simplified version of playSoundFromComponent for 2D sounds.
        // Create a temporary AudioSourceComponent-like struct or pass params directly.
        const temp_source = AudioSourceComponent {
            .clip_handle = clip,
            .volume = volume,
            .pitch = pitch,
            .looping = looping,
            .is_spatialized = false,
        };
        self.playSoundFromComponent(&temp_source, null);
    }

    pub fn playSound3D(self: *AudioEngine, clip: AudioClipHandle, position: Vec3, volume: f32, pitch: f32, looping: bool, min_dist: f32, max_dist: f32) void {
        const temp_source = AudioSourceComponent {
            .clip_handle = clip,
            .volume = volume,
            .pitch = pitch,
            .looping = looping,
            .is_spatialized = true,
            .min_distance = min_dist,
            .max_distance = max_dist,
        };
         self.playSoundFromComponent(&temp_source, position);
    }


    pub fn stopAllSounds(self: *AudioEngine) void {
        std.log.info("AudioEngine: Stopping all sounds.", .{});
        for (self.playing_sounds_pool) |*slot| {
            if (slot.is_active) {
                // self.miniaudio.stopSound(slot.sound_handle);
                slot.is_active = false;
            }
        }
        self.active_sound_count = 0;
    }

    // pub fn setMasterVolume(self: *AudioEngine, volume: f32) void {
    //     self.master_volume = std.math.clamp(volume, 0.0, 1.0); // Or allow >1 for boost
    //     // TODO: Update volume of all currently playing sounds if miniaudio supports global/group volume
    //     // or iterate and set individually.
    // }

    // --- Resource Loading (Conceptual - often handled by AssetManager) ---
    // The AudioEngine might expose methods to load/unload clips via miniaudio_wrapper.
    // pub fn loadClip(self: *AudioEngine, file_path: []const u8) !AudioClipHandle {
    //     return self.miniaudio.loadClipFromFile(file_path);
    // }
    // pub fn unloadClip(self: *AudioEngine, clip_handle: AudioClipHandle) void {
    //     self.miniaudio.unloadClip(clip_handle);
    // }
};


test "AudioEngine initialization and deinitialization" {
    const allocator = std.testing.allocator;
    var audio_engine = AudioEngine.init(allocator) catch |err| {
        std.log.err("AudioEngine init failed in test: {any}", .{err});
        // If miniaudio fails to init (e.g. no audio device), this test might fail here.
        // For robust testing, might need a mock miniaudio or ensure test runner has audio.
        // For now, assume it can initialize.
        return; // Skip test if init fails
    };
    defer audio_engine.deinit();

    try std.testing.expect(audio_engine.miniaudio.is_initialized); // Check wrapper's state
    try std.testing.expect(audio_engine.active_sound_count == 0);
    try std.testing.expect(audio_engine.playing_sounds_pool[0].is_active == false);

    std.log.info("AudioEngine initialization and deinitialization test completed.", .{});
}

test "AudioEngine playSound (mocked actual playback)" {
    const allocator = std.testing.allocator;
    var audio_engine = AudioEngine.init(allocator) catch return; // Skip if no audio device
    defer audio_engine.deinit();

    const clip1: AudioClipHandle = 1; // Dummy handle

    // Play a 2D sound
    audio_engine.playSound2D(clip1, 0.8, 1.0, false);
    try std.testing.expect(audio_engine.active_sound_count == 1);
    var found_sound = false;
    for (audio_engine.playing_sounds_pool) |*slot| {
        if (slot.is_active and slot.clip_handle == clip1 and !slot.is_spatialized) {
            try std.testing.expect(std.math.approxEqAbs(slot.volume, 0.8, 0.01));
            found_sound = true;
            break;
        }
    }
    try std.testing.expect(found_sound);

    // Play a 3D sound
    const clip2: AudioClipHandle = 2;
    audio_engine.playSound3D(clip2, Vec3.new(1,2,3), 0.5, 1.1, true, 1.0, 100.0);
    try std.testing.expect(audio_engine.active_sound_count == 2);
    // ... similar checks for the 3D sound properties ...

    // Test finding a free slot when some are active
    const slot = audio_engine.findFreePlayingSoundSlot();
    try std.testing.expect(slot != null); // Should find a slot if MAX_PLAYING_SOUNDS not reached
    if (slot) |s| {
        s.is_active = false; // Manually free it for test consistency
        audio_engine.active_sound_count -=1;
    }


    // Test stopping sounds
    audio_engine.stopAllSounds();
    try std.testing.expect(audio_engine.active_sound_count == 0);
    for (audio_engine.playing_sounds_pool) |*s| {
        try std.testing.expect(!s.is_active);
    }

    std.log.info("AudioEngine playSound test completed.", .{});
}

test "AudioEngine sound slot management" {
    const allocator = std.testing.allocator;
    var audio_engine = AudioEngine.init(allocator) catch return;
    defer audio_engine.deinit();

    // Fill up all sound slots
    var i: usize = 0;
    while (i < MAX_PLAYING_SOUNDS) : (i += 1) {
        // Use playSound2D which calls findFreePlayingSoundSlot
        audio_engine.playSound2D(@intCast(AudioClipHandle, i + 1), 1.0, 1.0, false);
    }
    try std.testing.expectEqual(@as(usize, MAX_PLAYING_SOUNDS), audio_engine.active_sound_count);

    // Try to play one more, should fail or be ignored
    audio_engine.playSound2D(MAX_PLAYING_SOUNDS + 1, 1.0, 1.0, false);
    try std.testing.expectEqual(@as(usize, MAX_PLAYING_SOUNDS), audio_engine.active_sound_count); // Still max

    // Simulate one sound finishing (manually for this test, as update() is placeholder)
    if (MAX_PLAYING_SOUNDS > 0) {
        audio_engine.playing_sounds_pool[0].is_active = false;
        audio_engine.active_sound_count -= 1;
    }

    // Now, playing a new sound should succeed
    audio_engine.playSound2D(MAX_PLAYING_SOUNDS + 2, 1.0, 1.0, false);
    if (MAX_PLAYING_SOUNDS > 0) { // Only if slots were actually available
        try std.testing.expectEqual(@as(usize, MAX_PLAYING_SOUNDS), audio_engine.active_sound_count);
        // Check if the first slot was reused
        try std.testing.expect(audio_engine.playing_sounds_pool[0].is_active);
        try std.testing.expect(audio_engine.playing_sounds_pool[0].clip_handle == MAX_PLAYING_SOUNDS + 2);
    }


    std.log.info("AudioEngine sound slot management test completed.", .{});
}
