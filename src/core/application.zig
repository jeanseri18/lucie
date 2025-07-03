// src/core/application.zig
// Application wrapper - manages the engine and windowing.

const std = @import("std");
const math = std.math; // Added for sin/cos
const Engine = @import("engine.zig").Engine; // Assuming engine.zig is in the same directory

pub const Application = struct {
    allocator: std.mem.Allocator,
    engine: Engine,
    is_running: bool,

    // TODO: Add window management (e.g., using a library like GLFW or SDL)
    // window: ?*WindowLibrary.Window = null,

    pub fn init(allocator: std.mem.Allocator) !Application {
        std.log.info("Initializing Application...", .{});

        // For now, we'll use a general purpose allocator passed in.
        // Later, we might want specific allocators for different parts of the app.
        var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
        const app_allocator = general_purpose_allocator.allocator();

        // Initialize the engine
        var engine_instance = try Engine.init(app_allocator);

        // TODO: Initialize windowing system here
        // For example:
        // try initWindowingSystem();
        // self.window = try createWindow("Lucie Game", 800, 600);

        return Application{
            .allocator = app_allocator, // Store the allocator being used
            .engine = engine_instance,
            .is_running = true, // Set to true once window is successfully created
        };
    }

    pub fn deinit(self: *Application) void {
        std.log.info("Deinitializing Application...", .{});
        self.engine.deinit();

        // TODO: Deinitialize windowing system and destroy window
        // if (self.window) |win| {
        //     destroyWindow(win);
        // }
        // deinitWindowingSystem();

        // If we used GeneralPurposeAllocator, we need to check for leaks
        // and free it.
        // This is a bit simplified; in a real app, the allocator passed to init()
        // would be responsible for its own lifecycle.
        // Here, we assume Application 'owns' the GPA if it creates it.
        // However, the current init takes an allocator, so the creator of Application
        // is responsible for the allocator it passes.
        // If Application created its own allocator internally (like GPA above), it should free it.
        // For now, let's assume the allocator passed to init is managed externally.
        // If the allocator field was a GPA directly:
        // const gpa = self.allocator; // Assuming allocator is the GPA struct itself
        // const leaked = gpa.deinit();
        // if (leaked) {
        //     std.log.err("Memory leak detected in application allocator!", .{});
        // }
        std.log.info("Application deinitialized.", .{});
    }

    pub fn isRunning(self: *const Application) bool {
        // TODO: This should also check if the window is trying to close
        // return self.is_running and !windowShouldClose(self.window);
        return self.is_running;
    }

    pub fn stop(self: *Application) void {
        self.is_running = false;
    }

    // Placeholder for main loop update
    pub fn update(self: *Application) !void {
        if (!self.isRunning()) return;

        // TODO: Poll window events
        // pollWindowEvents();

        // TODO: Process input

        // TODO: Update engine (which in turn updates game systems)
        // try self.engine.update();
        // For now, let's imagine a simple stop condition
        // like a key press, which would be handled by an input system.
        // If input.isKeyPressed(Key.Escape) { self.stop(); }
    }

    // Placeholder for rendering
    pub fn render(self: *Application, renderer: *const anyopaque, window: *const anyopaque) !void {
        if (!self.isRunning()) return;
        _ = renderer; // Placeholder
        _ = window; // Placeholder

        // TODO: Tell the engine to render (which would use the renderer)
        // try self.engine.render(renderer);

        // TODO: Swap window buffers (now done in run loop)
        // window.swapBuffers();
    }

    pub fn run(self: *Application) !void {
        std.log.info("Application run loop starting...", .{});

        // Create placeholder window
        var window = try @import("../platform/window.zig").Window.createAppWindow(
            self.allocator,
            "Lucie Engine Placeholder",
            800,
            600,
        );
        // Modify max_poll_count for a shorter test run if desired
        // @ptrCast(*@import("../platform/window.zig").AppWindow, @alignCast(@alignOf(@import("../platform/window.zig").AppWindow), window.ptr)).max_poll_count_before_close = 300;

        defer window.destroy();

        // Initialize renderer
        var renderer = try @import("../graphics/opengl/gl_renderer.zig").GLRenderer.init(
            self.allocator,
            &window,
        );
        defer renderer.deinit();

        // Initialize Camera
        var camera = @import("../graphics/camera.zig").Camera.initDefault(self.allocator);
        camera.position = .{ .x = 0, .y = 0.5, .z = 3.0 }; // Slightly different starting pos

        var total_time: f32 = 0.0; // For simple animation

        // Main loop
        while (!window.shouldClose() and self.isRunning()) { // Check both app state and window state
            // Poll events
            window.pollEvents();

            // Application-level update (game logic, physics, etc.)
            // try self.update(); // For now, update doesn't do much

            // Rendering
            const clear_color = @import("../graphics/color.zig").Color.CornflowerBlue;
            renderer.beginFrame(clear_color);

            const window_size = window.getSize();
            renderer.setViewport(0, 0, window_size.width, window_size.height);

            // try self.engine.render(&renderer); // If engine handles drawing calls
            // For now, direct render calls or placeholders would go here.

            // Conceptual triangle drawing (placeholders)
            // This would normally be done once, or if mesh data changes.
            // For this test, we might do it every frame or just once.
            // Let's do it once for simplicity.
            if (self.engine.triangle_mesh == 0) { // Assuming Engine stores handles, 0 for uninit
                 const vertices = [_]@import("../graphics/vertex.zig").VertexPC{
                    .{ .position = .{ .x = -0.5, .y = -0.5, .z = 0.0 }, .color = .{ .x = 1, .y = 0, .z = 0, .w = 1 } },
                    .{ .position = .{ .x =  0.5, .y = -0.5, .z = 0.0 }, .color = .{ .x = 0, .y = 1, .z = 0, .w = 1 } },
                    .{ .position = .{ .x =  0.0, .y =  0.5, .z = 0.0 }, .color = .{ .x = 0, .y = 0, .z = 1, .w = 1 } },
                };
                const indices = [_]u32{ 0, 1, 2 };
                self.engine.triangle_mesh = renderer.createMesh(&vertices, &indices) catch |err| {
                    std.log.err("Failed to create triangle mesh (placeholder): {any}", .{err});
                    0 // error case
                };
                if (self.engine.triangle_shader == null) {
                    self.engine.triangle_shader = @import("../graphics/shader.zig").Shader.createFromFile(
                        self.allocator, "shaders/simple.vert", "shaders/simple.frag"
                    ) catch |err| {
                         std.log.err("Failed to create triangle shader (placeholder): {any}", .{err});
                         null
                    };
                }
            }

            if (self.engine.triangle_mesh != 0 and self.engine.triangle_shader != null) {
                const shader = self.engine.triangle_shader.?;
                shader.use(renderer.gl_loaded); // Use the shader

                // Update camera aspect ratio based on window size
                camera.aspect_ratio = @intToFloat(f32, window_size.width) / @intToFloat(f32, window_size.height);

                // Simple camera animation: orbit around origin
                total_time += 0.016; // assume ~60 FPS for dt
                camera.position.x = math.sin(total_time) * 3.0;
                camera.position.z = math.cos(total_time) * 3.0;
                camera.lookAt( .{ .x=0,.y=0,.z=0}, .{ .x=0,.y=1,.z=0});


                const view_matrix = camera.getViewMatrix();
                const proj_matrix = camera.getProjectionMatrix();

                // Model matrix (identity for now, placing triangle at origin)
                const model_matrix = @import("../math/mat4.zig").Mat4.identity();

                shader.setUniformMat4(renderer.gl_loaded, "u_model", &model_matrix);
                shader.setUniformMat4(renderer.gl_loaded, "u_view", &view_matrix);
                shader.setUniformMat4(renderer.gl_loaded, "u_projection", &proj_matrix);

                renderer.drawMesh(self.engine.triangle_mesh, shader);
            }

            renderer.endFrame();

            // Swap buffers
            window.swapBuffers();
        }
        std.log.info("Application run loop finished.", .{});
    }
};

test "application initialization and deinitialization" {
    // Use testing allocator for tests
    const allocator = std.testing.allocator;
    var app = try Application.init(allocator);
    defer app.deinit();

    // Basic check
    try std.testing.expect(app.isRunning());
    app.stop();
    try std.testing.expect(!app.isRunning());
}

// Basic "Hello World" example usage, similar to the one in the problem description
// This would typically be in an examples/ directory, not in the core Application file.
// pub fn main() !void {
//     var app = try Application.init(std.heap.page_allocator); // Example using page_allocator
//     defer app.deinit();
//
//     while (app.isRunning()) {
//         try app.update();
//         try app.render();
//         // For a simple console app without a window, we might need to manually stop.
//         // In a real game, window events or input would control this.
//         // For this test-like main, let's run for a few frames.
//         // var i: u32 = 0;
//         // if (i > 5) app.stop();
//         // i += 1;
//         // Let's just stop it immediately for this placeholder
//         app.stop();
//     }
// }
