// src/tools/asset_loader.zig
// Utilities for loading game assets (textures, sounds, models, etc.).
// This is a placeholder for what could be a more complex AssetManager system.

const std = @import("std");
const fs = std.fs;

// Placeholder types for loaded assets.
// In a real engine, these would be more specific (e.g., graphics.Texture, audio.SoundClip, graphics.Mesh).
// For now, using opaque pointers or simple structs.
pub const TextureAsset = struct { id: u32, width: u32, height: u32, data_ptr: ?*anyopaque = null /* mock */ };
pub const SoundAsset = struct { id: u32, length_seconds: f32, data_ptr: ?*anyopaque = null /* mock */ };
pub const ModelAsset = struct { id: u32, vertex_count: u32, index_count: u32, data_ptr: ?*anyopaque = null /* mock */ };
// Generic AssetHandle could be used if assets are stored in a central manager.
// pub const AssetHandle = u64;


// AssetLoader provides functions to load different types of assets from files.
// It might interact with specific loaders (e.g., STBImage for textures, dr_wav for audio).
pub const AssetLoader = struct {
    allocator: std.mem.Allocator,
    base_asset_path: []const u8, // Base directory for assets (e.g., "assets/")

    // Optional: Cache for loaded assets to avoid redundant loads.
    // texture_cache: std.StringHashMap(TextureAsset),
    // sound_cache: std.StringHashMap(SoundAsset),

    pub fn init(allocator_param: std.mem.Allocator, asset_dir: []const u8) !AssetLoader {
        // Ensure asset_dir is a valid path and potentially store its absolute form.
        // For now, just store it.
        const owned_asset_path = try allocator_param.dupe(u8, asset_dir);

        return AssetLoader{
            .allocator = allocator_param,
            .base_asset_path = owned_asset_path,
            // .texture_cache = std.StringHashMap(TextureAsset).init(allocator_param),
            // .sound_cache = std.StringHashMap(SoundAsset).init(allocator_param),
        };
    }

    pub fn deinit(self: *AssetLoader) void {
        self.allocator.free(self.base_asset_path);
        // Deinit caches if used
        // self.texture_cache.deinit();
        // self.sound_cache.deinit();
        // TODO: Ensure all cached Asset structs that might own memory are deinitialized/freed.
    }

    fn getFullPath(self: *const AssetLoader, relative_path: []const u8) ![]u8 {
        return fs.path.join(self.allocator, &[_][]const u8{ self.base_asset_path, relative_path });
    }

    // --- Texture Loading ---
    // file_path: relative to base_asset_path (e.g., "textures/player.png")
    pub fn loadTexture(self: *AssetLoader, file_path_rel: []const u8) !TextureAsset {
        const full_path = try self.getFullPath(file_path_rel);
        defer self.allocator.free(full_path);
        std.log.debug("Attempting to load texture: {s}", .{full_path});

        // Check cache first (if implemented)
        // if (self.texture_cache.get(file_path_rel)) |cached_asset| return cached_asset.*;

        // Placeholder: Simulate loading. A real implementation would use a library like stb_image.
        // For stb_image with Zig: @cImport stb_image.h, then use its functions.
        // Example:
        // var width: c_int = 0;
        // var height: c_int = 0;
        // var channels: c_int = 0;
        // const pixels = stbi_load(full_path.ptr, &width, &height, &channels, 4); // Request 4 channels (RGBA)
        // if (pixels == null) {
        //     std.log.err("Failed to load texture '{s}': {s}", .{full_path, stbi_failure_reason()});
        //     return error.TextureLoadFailed;
        // }
        // defer stbi_image_free(pixels);
        // Process pixel data into engine's texture format...
        // const loaded_texture = TextureAsset { .id = generate_unique_id(), .width = width, .height = height, .data_ptr = pixels (needs careful lifetime mgmt) };

        // Mock successful load for placeholder
        if (!std.mem.endsWith(u8, file_path_rel, ".png") and !std.mem.endsWith(u8, file_path_rel, ".jpg")) {
            std.log.warn("Mock AssetLoader: Texture file '{s}' not a .png or .jpg, simulating load failure.", .{file_path_rel});
            return error.TextureLoadFailed;
        }

        // Simulate file access check
        fs.cwd().access(full_path, .{}) catch |err| {
             std.log.err("Mock AssetLoader: File not accessible '{s}': {any}", .{full_path, err});
             return error.FileNotFound;
        };


        std.log.info("Mock-loaded texture: {s} (simulated 128x128)", .{file_path_rel});
        const mock_texture = TextureAsset{ .id = 1, .width = 128, .height = 128 };
        // try self.texture_cache.put(try self.allocator.dupe(u8, file_path_rel), mock_texture);
        return mock_texture;
    }

    // pub fn unloadTexture(self: *AssetLoader, asset: TextureAsset) void { ... }
    // pub fn unloadTextureByPath(self: *AssetLoader, file_path_rel: []const u8) void { ... }


    // --- Sound Loading ---
    pub fn loadSound(self: *AssetLoader, file_path_rel: []const u8) !SoundAsset {
        const full_path = try self.getFullPath(file_path_rel);
        defer self.allocator.free(full_path);
        std.log.debug("Attempting to load sound: {s}", .{full_path});

        // Placeholder: Simulate loading. Real implementation uses audio decoding library (e.g., dr_wav, dr_mp3, or miniaudio's decoders).
        // Example with dr_wav:
        // var channels: c_uint = 0;
        // var sample_rate: c_uint = 0;
        // var total_frame_count: drwav_uint64 = 0;
        // const pcm_data = drwav_open_file_and_read_pcm_frames_f32(full_path.ptr, &channels, &sample_rate, &total_frame_count, null);
        // if (pcm_data == null) return error.SoundLoadFailed;
        // defer drwav_free(pcm_data, null);
        // const length_sec = @intToFloat(f32, total_frame_count) / @intToFloat(f32, sample_rate);

        if (!std.mem.endsWith(u8, file_path_rel, ".wav") and !std.mem.endsWith(u8, file_path_rel, ".mp3")) {
            std.log.warn("Mock AssetLoader: Sound file '{s}' not a .wav or .mp3, simulating load failure.", .{file_path_rel});
            return error.SoundLoadFailed;
        }
        fs.cwd().access(full_path, .{}) catch |err| {
             std.log.err("Mock AssetLoader: File not accessible '{s}': {any}", .{full_path, err});
             return error.FileNotFound;
        };

        std.log.info("Mock-loaded sound: {s} (simulated 5.0s length)", .{file_path_rel});
        return SoundAsset{ .id = 1, .length_seconds = 5.0 };
    }

    // --- Model Loading ---
    // pub fn loadModel(self: *AssetLoader, file_path_rel: []const u8) !ModelAsset {
    //     // Placeholder: Uses libraries like Assimp, cgltf, tinyobjloader etc.
    //     _ = self; _ = file_path_rel;
    //     std.log.info("Mock-loaded model: {s}", .{file_path_rel});
    //     return ModelAsset{ .id = 1, .vertex_count = 100, .index_count = 150 };
    // }

    // --- Generic JSON/Text File Loading ---
    pub fn loadTextFile(self: *AssetLoader, file_path_rel: []const u8) ![]u8 {
        const full_path = try self.getFullPath(file_path_rel);
        defer self.allocator.free(full_path);
        std.log.debug("Loading text file: {s}", .{full_path});

        // Read entire file into a string allocated by self.allocator
        return fs.cwd().readFileAlloc(self.allocator, full_path, std.math.maxInt(usize)); // Max size limit
    }

    // pub fn loadJsonFile(self: *AssetLoader, file_path_rel: []const u8, comptime T: type) !T {
    //     const json_string = try self.loadTextFile(file_path_rel);
    //     defer self.allocator.free(json_string);
    //     return std.json.parseFromSlice(T, self.allocator, json_string, .{});
    // }
};


test "AssetLoader initialization and path joining" {
    const allocator = std.testing.allocator;
    const base_path = "my_game_assets";
    var loader = try AssetLoader.init(allocator, base_path);
    defer loader.deinit();

    try std.testing.expectEqualStrings(base_path, loader.base_asset_path);

    const rel_path = "textures/player.png";
    const expected_full_path_str = try fs.path.join(allocator, &[_][]const u8{base_path, rel_path});
    defer allocator.free(expected_full_path_str);

    const actual_full_path = try loader.getFullPath(rel_path);
    defer allocator.free(actual_full_path);
    try std.testing.expectEqualStrings(expected_full_path_str, actual_full_path);

    std.log.info("AssetLoader init and path joining test completed.", .{});
}

test "AssetLoader mock loading functions" {
    const allocator = std.testing.allocator;
    // Create dummy asset directory and files for testing file access simulation
    const test_asset_base = "./temp_test_assets_loader";
    try fs.cwd().makeDir(test_asset_base);
    defer fs.cwd().deleteTree(test_asset_base) catch {}; // Cleanup

    const tex_dir = try fs.path.join(allocator, &[_][]const u8{test_asset_base, "textures"});
    defer allocator.free(tex_dir);
    try fs.cwd().makeDir(tex_dir);
    const sound_dir = try fs.path.join(allocator, &[_][]const u8{test_asset_base, "sounds"});
    defer allocator.free(sound_dir);
    try fs.cwd().makeDir(sound_dir);

    // Create dummy files
    var dummy_tex_file = try fs.cwd().createFile(try fs.path.join(allocator, &[_][]const u8{tex_dir, "dummy.png"}), .{});
    dummy_tex_file.close();
    var dummy_sound_file = try fs.cwd().createFile(try fs.path.join(allocator, &[_][]const u8{sound_dir, "dummy.wav"}), .{});
    dummy_sound_file.close();
    var dummy_text_file_path = try fs.path.join(allocator, &[_][]const u8{test_asset_base, "data.txt"});
    defer allocator.free(dummy_text_file_path);
    var dummy_text_file = try fs.cwd().createFile(dummy_text_file_path, .{});
    try dummy_text_file.writeAll("Hello AssetLoader!");
    dummy_text_file.close();


    var loader = try AssetLoader.init(allocator, test_asset_base);
    defer loader.deinit();

    // Test texture loading (mocked)
    const tex_asset = try loader.loadTexture("textures/dummy.png");
    try std.testing.expect(tex_asset.id == 1); // Mock ID
    try std.testing.expect(tex_asset.width == 128); // Mocked dimensions

    const tex_fail_ext = loader.loadTexture("textures/dummy.bmp"); // Wrong extension for mock
    try std.testing.expectError(error.TextureLoadFailed, tex_fail_ext);
    const tex_fail_path = loader.loadTexture("textures/nonexistent.png"); // File not found by mock's access check
    try std.testing.expectError(error.FileNotFound, tex_fail_path);


    // Test sound loading (mocked)
    const sound_asset = try loader.loadSound("sounds/dummy.wav");
    try std.testing.expect(sound_asset.id == 1);
    try std.testing.expect(sound_asset.length_seconds == 5.0);

    // Test text file loading
    const text_content = try loader.loadTextFile("data.txt");
    defer allocator.free(text_content);
    try std.testing.expectEqualStrings("Hello AssetLoader!", text_content);

    std.log.info("AssetLoader mock loading functions test completed.", .{});
}
