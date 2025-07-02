// src/core/engine.zig
// Main game engine logic will reside here.
// This could include the main loop, scene management, and system updates.

const std = @import("std");

pub const Engine = struct {
    // Engine specific fields
    allocator: std.mem.Allocator,

    // Placeholder for triangle rendering demo
    triangle_mesh: @import("../graphics/opengl/gl_renderer.zig").GLMeshHandle = 0,
    triangle_shader: ?@import("../graphics/shader.zig").Shader = null,


    // TODO: Add other engine components like renderer, physics world, audio engine, etc.

    pub fn init(allocator: std.mem.Allocator) !Engine {
        std.log.info("Initializing Lucie Engine...", .{});
        // TODO: Initialize all subsystems
        return Engine{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Engine) void {
        std.log.info("Deinitializing Lucie Engine...", .{});
        // TODO: Deinitialize all subsystems
        if (self.triangle_shader) |*shader| {
            shader.destroy();
            self.triangle_shader = null;
        }
        // Note: triangle_mesh cleanup would be handled by the renderer that owns it.
        // If the renderer is part of Engine, Engine.deinit would call renderer.deinit(),
        // which would then clean up all meshes including triangle_mesh.
    }

    pub fn run(self: *Engine) !void {
        std.log.info("Lucie Engine run loop starting...", .{});
        // TODO: Implement the main engine loop
        // This would typically involve:
        // 1. Processing input
        // 2. Updating game logic (ECS systems, physics, etc.)
        // 3. Rendering
        // 4. Handling frame timing
        while (true) { // Placeholder for actual running condition
            // Simulate some work
            std.time.sleep(16 * std.time.ns_per_ms); // ~60 FPS
            // TODO: Replace with actual break condition (e.g., window close)
            break;
        }
        std.log.info("Lucie Engine run loop finished.", .{});
    }
};

test "engine initialization and deinitialization" {
    const allocator = std.testing.allocator;
    var engine = try Engine.init(allocator);
    defer engine.deinit();

    // Basic check to ensure init/deinit don't crash
    try std.testing.expect(engine.allocator == allocator);
}
