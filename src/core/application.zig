// src/core/application.zig
// Application wrapper - manages the engine and windowing.

const std = @import("std");
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
    pub fn render(self: *Application) !void {
        if (!self.isRunning()) return;

        // TODO: Tell the engine to render
        // try self.engine.render();

        // TODO: Swap window buffers
        // swapWindowBuffers(self.window);
    }

    // Example main loop structure (could be part of a run method)
    // pub fn run(self: *Application) !void {
    //     while (self.isRunning()) {
    //         try self.update();
    //         try self.render();
    //     }
    // }
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
