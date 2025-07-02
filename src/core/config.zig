// src/core/config.zig
// Configuration loading and management, e.g., from JSON files.

const std = @import("std");
const json = std.json;
const fs = std.fs;

// Example configuration structure
pub const EngineConfig = struct {
    window_width: u32 = 800,
    window_height: u32 = 600,
    window_title: []const u8 = "Lucie Game",
    target_fps: u32 = 60,
    vsync: bool = true,

    // Example nested configuration
    pub const GraphicsConfig = struct {
        renderer_api: []const u8 = "opengl", // "opengl" or "vulkan"
        msaa_samples: u8 = 4,
    };
    graphics: GraphicsConfig = .{},

    // Function to provide default values if parsing fails or for initialization
    pub fn default() EngineConfig {
        return EngineConfig{};
    }
};

// ConfigManager is responsible for loading and providing access to configuration.
pub const ConfigManager = struct {
    allocator: std.mem.Allocator,
    config: EngineConfig,

    pub fn init(allocator: std.mem.Allocator) ConfigManager {
        return ConfigManager{
            .allocator = allocator,
            .config = EngineConfig.default(), // Start with default config
        };
    }

    pub fn deinit(_: *ConfigManager) void {
        // If config strings were allocated, they'd be freed here.
        // In EngineConfig, strings are literals, so no heap allocation for them by default.
    }

    // Loads configuration from a JSON file.
    pub fn loadFromFile(self: *ConfigManager, file_path: []const u8) !void {
        std.log.info("Loading configuration from: {s}", .{file_path});

        const file = try fs.cwd().openFile(file_path, .{ .mode = .read_only });
        defer file.close();

        // Read the whole file into a buffer.
        // For large config files, streaming might be better.
        const file_contents = try file.readToEndAlloc(self.allocator, 1 * 1024 * 1024); // Max 1MB config
        defer self.allocator.free(file_contents);

        // Parse the JSON.
        // We need to pass an allocator for potential allocations during parsing (e.g. for strings).
        var diagnostics: json.ValidateError = undefined;
        const parsed_config = json.parseFromSlice(EngineConfig, self.allocator, file_contents, .{
            .ignore_unknown_fields = true, // Be flexible with extra fields in JSON
            .diagnostics = &diagnostics,
        });

        if (parsed_config) |cfg| {
            // If EngineConfig fields that are strings were allocated by json.parseFromSlice,
            // we would need to manage their lifetime, potentially by cloning them into
            // self.config using self.allocator if self.config itself isn't using the parse allocator.
            // However, our current EngineConfig uses string literals for defaults.
            // If JSON provides new strings, json.parseFromSlice would allocate them.
            // For simplicity here, we assume string fields in JSON are handled by the parser's allocator
            // and if we need to own them longer than the parsing scope, we'd clone.
            // Let's refine this: if EngineConfig's strings are `[]const u8`, they can point to
            // memory from `file_contents` if not explicitly copied. This is unsafe if `file_contents` is freed.
            // To make it safe, `EngineConfig` should own its strings, or we should copy them.
            // For this example, let's assume `json.parseFromSlice` with an allocator that lives as long as `ConfigManager`
            // or that we copy strings if `EngineConfig` has `[]u8` (owned) fields.
            // The provided example struct uses `[]const u8`, which is fine if they are literals or
            // if their lifetime is managed. `std.json.parseFromSlice` will allocate strings on the
            // provided allocator. So, self.config's strings will be valid as long as that allocator is valid
            // and the memory isn't freed elsewhere.

            // If self.config.window_title was `[]u8` (owned slice), we'd do:
            // self.config.window_title = try self.allocator.dupe(u8, cfg.window_title);
            // And then free the old one if necessary.
            // Since it's `[]const u8` and `json.parseFromSlice` allocates, we must ensure `cfg`'s strings
            // are either copied or their source memory (from the allocator passed to parse) remains valid.
            // The easiest is to assign directly if the allocator for parse is the same as for ConfigManager lifetime.
            self.config = cfg; // This will copy the struct, including slices that point to allocated memory.
            std.log.info("Configuration loaded successfully.", .{});
        } else |err| {
            std.log.err("Failed to parse configuration file: {s}", .{file_path});
            std.log.err("Error: {any}", .{err});
            if (err == error.InvalidJson) {
                std.log.err("JSON validation error at offset {d}: {s}", .{diagnostics.offset, diagnostics.reason});
            }
            // Optionally, fall back to default or propagate error
            return err;
        }
    }

    pub fn get(self: *const ConfigManager) EngineConfig {
        return self.config;
    }
};

test "ConfigManager load and get" {
    const allocator = std.testing.allocator;
    var config_manager = ConfigManager.init(allocator);
    defer config_manager.deinit();

    // Create a dummy config file for testing
    const test_config_path = "test_config.json";
    const test_config_content =
        \\{
        \\  "window_width": 1024,
        \\  "window_height": 768,
        \\  "window_title": "Test Game",
        \\  "target_fps": 120,
        \\  "vsync": false,
        \\  "graphics": {
        \\    "renderer_api": "vulkan",
        \\    "msaa_samples": 8
        \\  }
        \\}
    ;

    var file = try fs.cwd().createFile(test_config_path, .{});
    defer {
        file.close();
        // fs.cwd().deleteFile(test_config_path) catch {}; // Clean up
    }
    try file.writeAll(test_config_content);
    file.close(); // Close before reopening for read in loadFromFile

    // Load the config
    try config_manager.loadFromFile(test_config_path);

    const cfg = config_manager.get();
    try std.testing.expectEqual(@as(u32, 1024), cfg.window_width);
    try std.testing.expectEqual(@as(u32, 768), cfg.window_height);
    try std.testing.expectEqualStrings("Test Game", cfg.window_title);
    try std.testing.expectEqual(@as(u32, 120), cfg.target_fps);
    try std.testing.expectEqual(false, cfg.vsync);
    try std.testing.expectEqualStrings("vulkan", cfg.graphics.renderer_api);
    try std.testing.expectEqual(@as(u8, 8), cfg.graphics.msaa_samples);

    // Clean up the test file
    try fs.cwd().deleteFile(test_config_path);

    // Test loading a non-existent file (should ideally use default or error out)
    // For this test, we expect it to error out as per current loadFromFile implementation.
    const non_existent_path = "non_existent_config.json";
    const load_result = config_manager.loadFromFile(non_existent_path);
    try std.testing.expectError(fs.File.OpenError, load_result);
}

test "Config default values" {
    const allocator = std.testing.allocator;
    var config_manager = ConfigManager.init(allocator);
    defer config_manager.deinit();

    const default_cfg = EngineConfig.default();
    const current_cfg = config_manager.get();

    try std.testing.expectEqual(default_cfg.window_width, current_cfg.window_width);
    try std.testing.expectEqualStrings(default_cfg.window_title, current_cfg.window_title);
    try std.testing.expectEqual(default_cfg.graphics.msaa_samples, current_cfg.graphics.msaa_samples);
}
