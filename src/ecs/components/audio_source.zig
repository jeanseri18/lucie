// src/ecs/components/audio_source.zig
// Defines the AudioSource component for playing sounds.

const std = @import("std");

// Placeholder for an audio clip/sound resource handle.
// This would typically be an ID into an audio resource manager.
pub const AudioClipHandle = u32;

pub const AudioSourceComponent = struct {
    clip_handle: AudioClipHandle = 0, // Handle of the audio clip to play

    volume: f32 = 1.0,      // Volume (0.0 to 1.0 typically, but can be >1 for amplification)
    pitch: f32 = 1.0,       // Playback speed/pitch (1.0 = normal)
    looping: bool = false,  // Whether the sound should loop

    // For 3D spatialized audio (if supported by audio engine)
    is_spatialized: bool = false,
    min_distance: f32 = 1.0,    // Distance at which sound is heard at full volume
    max_distance: f32 = 50.0,   // Distance beyond which sound is no longer heard (or significantly attenuated)
    attenuation_model: AttenuationModel = .Logarithmic, // How sound fades with distance

    // Playback state (managed by the audio system, but might be reflected here for queries)
    // is_playing: bool = false,
    // play_time: f32 = 0.0, // Current playback time in seconds

    pub const AttenuationModel = enum {
        None,         // No distance attenuation (e.g., for UI sounds, music)
        Linear,
        Logarithmic,  // More realistic model
        InverseSquare, // Physically accurate for point sources in open space
    };

    pub fn init(clip: AudioClipHandle) AudioSourceComponent {
        return AudioSourceComponent{
            .clip_handle = clip,
        };
    }

    // Methods to control playback (these would typically signal the audio engine)
    // pub fn play(self: *AudioSourceComponent, world: *World) void { ... }
    // pub fn stop(self: *AudioSourceComponent, world: *World) void { ... }
    // pub fn pause(self: *AudioSourceComponent, world: *World) void { ... }
};


test "AudioSourceComponent initialization and default values" {
    const test_clip_handle: AudioClipHandle = 789;
    var audio_source = AudioSourceComponent.init(test_clip_handle);

    try std.testing.expect(audio_source.clip_handle == test_clip_handle);
    try std.testing.expect(audio_source.volume == 1.0);
    try std.testing.expect(audio_source.pitch == 1.0);
    try std.testing.expect(audio_source.looping == false);
    try std.testing.expect(audio_source.is_spatialized == false);
    try std.testing.expect(audio_source.min_distance == 1.0);
    try std.testing.expect(audio_source.max_distance == 50.0);
    try std.testing.expect(audio_source.attenuation_model == .Logarithmic);
    // try std.testing.expect(audio_source.is_playing == false);

    // Test direct struct init
    var audio_source_direct = AudioSourceComponent{
        .clip_handle = 101,
        .volume = 0.5,
        .looping = true,
        .is_spatialized = true,
        .attenuation_model = .InverseSquare,
    };
    try std.testing.expect(audio_source_direct.clip_handle == 101);
    try std.testing.expect(audio_source_direct.volume == 0.5);
    try std.testing.expect(audio_source_direct.looping == true);
    try std.testing.expect(audio_source_direct.attenuation_model == .InverseSquare);

    std.log.info("AudioSourceComponent initialization test completed.", .{});
}

test "AudioSourceComponent AttenuationModel enum" {
    try std.testing.expect(@intFromEnum(AudioSourceComponent.AttenuationModel.None) == 0);
    try std.testing.expect(@intFromEnum(AudioSourceComponent.AttenuationModel.Linear) == 1);
    try std.testing.expect(@intFromEnum(AudioSourceComponent.AttenuationModel.Logarithmic) == 2);
    try std.testing.expect(@intFromEnum(AudioSourceComponent.AttenuationModel.InverseSquare) == 3);

    const model = AudioSourceComponent.AttenuationModel.Linear;
    switch (model) {
        .None, .Linear, .Logarithmic, .InverseSquare => {},
        // No else needed if all members are covered
    }
    std.log.info("AudioSourceComponent AttenuationModel enum test completed.", .{});
}
