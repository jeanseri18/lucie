// src/graphics/opengl/gl_renderer.zig
// OpenGL specific renderer implementation.

const std = @import("std");
const gl = @import("gl"); // Use the generated OpenGL bindings
const Color = @import("../color.zig").Color;
const Mat4 = @import("../../math/mat4.zig").Mat4;
const Window = @import("../../platform/window.zig").Window; // Import the placeholder Window

// Handles for OpenGL objects
pub const GLShaderHandle = u32;
pub const GLTextureHandle = u32;
pub const GLBufferHandle = u32; // For VBO, EBO
pub const GLVaoHandle = u32;

pub const GLRenderer = struct {
    allocator: std.mem.Allocator,
    // window_handle: ?*anyopaque = null, // e.g. GLFWwindow pointer

    // Stats or capabilities
    gl_version_major: i32 = 0,
    gl_version_minor: i32 = 0,
    max_texture_units: i32 = 0,

    // Current state (simplified)
    current_shader: GLShaderHandle = 0,
    // current_vao: GLVaoHandle = 0,
    gl_loaded: bool = false,

    pub fn init(allocator: std.mem.Allocator, window: *const Window) !GLRenderer {
        std.log.info("Initializing OpenGL Renderer...", .{});

        // Load OpenGL function pointers using the window's getProcAddress
        // The generated gl.zig from zig-opengl typically has a `load` function
        // that takes a context (can often be null or a dummy value if getProcAddress is global)
        // and the getProcAddress function itself.
        // Example: try gl.load(null, window.getProcAddress);
        // The exact signature of gl.load might vary based on the generator version.
        // Let's assume it's: gl.load(user_context: anytype, loader_function: fn(@TypeOf(user_context), [:0]const u8) ?*anyopaque)

        var gl_is_loaded = false;
        if (window.getProcAddress(window, "glClear") != null) { // Basic check if getProcAddress is not always null
            // The context for gl.load is often optional or can be the window itself.
            // For zig-opengl generated file, it's often (load_ctx: anytype, get_proc_address: fn(@TypeOf(load_ctx), [:0]const u8) ?*FunctionPointer)
            // So we pass the window as context for its getProcAddress.
            gl.load(window, window.getProcAddressFn) catch |err| {
                 std.log.warn("OpenGL function loading failed. GLRenderer will operate in no-op mode. Error: {any}", .{err});
                 // Proceeding without GL functions, they will be no-ops or error out if called.
            } else {
                std.log.info("OpenGL functions loaded successfully via window.getProcAddress.", .{});
                gl_is_loaded = true;
            };
        } else {
            std.log.warn("window.getProcAddress seems to be a null provider. OpenGL functions will not be loaded.", .{});
        }


        var renderer = GLRenderer{
            .allocator = allocator,
            .gl_loaded = gl_is_loaded,
        };

        if (renderer.gl_loaded) {
            // Example: Querying GL version (if context is active and functions loaded)
            var major: i32 = 0;
            var minor: i32 = 0;
            gl.getIntegerv(gl.MAJOR_VERSION, &major);
            gl.getIntegerv(gl.MINOR_VERSION, &minor);
            renderer.gl_version_major = major;
            renderer.gl_version_minor = minor;
            std.log.info("OpenGL Version: {d}.{d}", .{major, minor});

            // gl.getIntegerv(gl.MAX_TEXTURE_IMAGE_UNITS, &renderer.max_texture_units);
            // std.log.info("Max texture units: {d}", .{renderer.max_texture_units});

            // Set initial GL state
            gl.enable(gl.DEPTH_TEST);
            gl.enable(gl.CULL_FACE);
            gl.enable(gl.BLEND);
            gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
            std.log.info("Default OpenGL states set.", .{});
        } else {
            std.log.warn("OpenGL not loaded. Renderer will be in a no-op state.", .{});
        }

        return renderer;
    }

    pub fn deinit(self: *GLRenderer) void {
        std.log.info("Deinitializing OpenGL Renderer...", .{});
        // Clean up any global OpenGL resources if this renderer "owns" them.
        // Usually, context destruction is handled by the windowing library.
        _ = self;
    }

    pub fn beginFrame(self: *GLRenderer, clear_color: Color) void {
        if (!self.gl_loaded) {
            std.log.debug("GLRenderer.beginFrame (no-op, GL not loaded)", .{});
            return;
        }
        gl.clearColor(clear_color.r, clear_color.g, clear_color.b, clear_color.a);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        // std.log.debug("GLRenderer.beginFrame (clear: {any})", .{clear_color});
    }

    pub fn endFrame(self: *GLRenderer) void {
        if (!self.gl_loaded) {
            std.log.debug("GLRenderer.endFrame (no-op, GL not loaded)", .{});
            return;
        }
        // Buffer swapping is handled by the windowing system, not directly by renderer.
        // std.log.debug("GLRenderer.endFrame (swap buffers would occur via window system)", .{});
        _ = self;
    }

    pub fn setViewport(self: *GLRenderer, x: i32, y: i32, width: u32, height: u32) void {
        if (!self.gl_loaded) {
            std.log.debug("GLRenderer.setViewport (no-op, GL not loaded)", .{});
            return;
        }
        gl.viewport(x, y, @intCast(i32, width), @intCast(i32, height));
        // std.log.debug("GLRenderer.setViewport ({d},{d}, {d}x{d})", .{x,y,width,height});
    }

    // More specific OpenGL drawing commands would go here
    // e.g., drawTriangles, drawIndexed, etc.

    // pub fn createShader(self: *GLRenderer, vertex_src: []const u8, fragment_src: []const u8) !GLShaderHandle {
    //     // ... compile and link shader ...
    //     return 0;
    // }
    // pub fn useShader(self: *GLRenderer, shader_id: GLShaderHandle) void {
    //     // gl.useProgram(shader_id);
    //     // self.current_shader = shader_id;
    // }
    // pub fn createTexture2D(...) !GLTextureHandle
    // pub fn bindTexture(...)
    // pub fn createVertexBuffer(...) !GLBufferHandle
    // pub fn createIndexBuffer(...) !GLBufferHandle
    // pub fn createVertexArrayObject(...) !GLVaoHandle
    // pub fn bindVao(...)
    // pub fn drawElements(...)
};

test "GLRenderer placeholder initialization with placeholder window" {
    // This test uses the placeholder AppWindow.
    // Since AppWindow.getProcAddress returns null, GL functions won't actually load.
    // This tests the renderer's behavior in such a scenario.
    const allocator = std.testing.allocator;
    var window = try Window.createAppWindow(allocator, "Test GLRenderer Window", 100, 100);
    defer window.destroy();

    var renderer = try GLRenderer.init(allocator, &window);
    defer renderer.deinit();

    // Check default values or simple non-GL state
    try std.testing.expect(!renderer.gl_loaded); // Expect GL to not be loaded with placeholder
    try std.testing.expect(renderer.allocator == allocator);

    // Simulate frame lifecycle calls
    renderer.beginFrame(Color.Black);
    renderer.setViewport(0,0, 800, 600);
    renderer.endFrame();

    std.log.info("GLRenderer test completed (no actual GL calls invoked).", .{});
}

// Note on OpenGL bindings:
// The `gl.zig` file was generated by `zig-opengl` and provides the bindings.
// It's added as a module named "gl" in `build.zig`.
// To use these bindings, an OpenGL context must be created (usually by a windowing library
// like GLFW or SDL), and then the OpenGL function pointers must be loaded.
// The generated `gl.zig` typically includes a `load` function for this purpose,
// which needs a function like `glfwGetProcAddress` to be passed to it.
// Example:
// var window = try Window.create(...); // Assuming a windowing library
// try gl.load(window.context, window.getProcAddress); // Simplified example
// After this, OpenGL functions from the `gl` module can be called.
