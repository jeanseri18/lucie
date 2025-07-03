// src/graphics/opengl/gl_renderer.zig
// OpenGL specific renderer implementation.

const std = @import("std");
const gl = @import("gl"); // Use the generated OpenGL bindings
const Color = @import("../color.zig").Color;
const Mat4 = @import("../../math/mat4.zig").Mat4;
const Window = @import("../../platform/window.zig").Window; // Import the placeholder Window
const Vertex = @import("../vertex.zig").VertexPC; // Using VertexPC for simplicity
const Shader = @import("../shader.zig").Shader; // Import placeholder Shader

// Handles for OpenGL objects
pub const GLShaderHandle = u32;
pub const GLTextureHandle = u32;
pub const GLBufferHandle = u32; // For VBO, EBO
pub const GLVaoHandle = u32;

// GLMeshHandle will be an index/ID into a list of GLOwnedMesh objects
pub const GLMeshHandle = u32;

const GLOwnedMesh = struct {
    vao: GLVaoHandle = 0,
    vbo: GLBufferHandle = 0,
    ebo: GLBufferHandle = 0,
    index_count: u32 = 0,
    // Other relevant data like vertex_count, material_id etc. could be stored here
};

pub const GLRenderer = struct {
    allocator: std.mem.Allocator,

    // Store created GL mesh resources
    // Using an ArrayList for dynamic storage. In a real engine, a more sophisticated
    // resource manager or a fixed-size pool might be used for GLMeshHandle.
    // For placeholder, a simple map from handle to GLOwnedMesh.
    // Handles could be generational or simply map keys.
    // Let's use an ArenaAllocator for GLOwnedMesh instances if we use pointers,
    // or an ArrayList of GLOwnedMesh if handles are indices.
    // For simplicity, using an IDH (ID Handle) map approach conceptually.
    // next_mesh_handle will be the key.
    // This is a simplified resource management for now.
    meshes: std.AutoHashMap(GLMeshHandle, GLOwnedMesh),
    next_mesh_handle: GLMeshHandle = 1,

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


        var meshes_map = std.AutoHashMap(GLMeshHandle, GLOwnedMesh).init(allocator);

        var renderer = GLRenderer{
            .allocator = allocator,
            .gl_loaded = gl_is_loaded,
            .meshes = meshes_map,
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

        // Destroy any remaining meshes
        var mesh_iter = self.meshes.valueIterator();
        while (mesh_iter.next()) |mesh_data| {
            if (self.gl_loaded) {
                // Assuming GLOwnedMesh stores actual GL handles
                gl.deleteVertexArrays(1, &mesh_data.vao);
                var buffers_to_delete = [_]GLBufferHandle{mesh_data.vbo, mesh_data.ebo};
                gl.deleteBuffers(buffers_to_delete.len, &buffers_to_delete);
                 std.log.debug("Deinit: Destroyed VAO: {d}, VBO: {d}, EBO: {d}", .{mesh_data.vao, mesh_data.vbo, mesh_data.ebo});
            }
        }
        self.meshes.deinit(); // Deinitialize the hash map itself

        // Clean up any other global OpenGL resources if this renderer "owns" them.
        // Usually, context destruction is handled by the windowing library.
        std.log.info("OpenGL Renderer deinitialized.", .{});
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

    // Placeholder Mesh functions
    pub fn createMesh(
        self: *GLRenderer,
        vertices: []const Vertex,
        indices: []const u32
    ) !GLMeshHandle { // Can return error.OpenGLOperationFailed or map insertion error
        const handle = self.next_mesh_handle;
        self.next_mesh_handle += 1;

        if (!self.gl_loaded) {
            std.log.warn("GLRenderer.createMesh (GL not loaded), returning dummy handle {d}", .{handle});
            // Store a dummy mesh entry so destroyMesh doesn't try to access a non-existent key
            // or make destroyMesh check for key existence.
            // For now, we'll let destroyMesh handle missing keys gracefully if gl_loaded is false.
            return handle;
        }

        std.log.info("GLRenderer: Creating GL mesh - Vertices: {d}, Indices: {d}", .{ vertices.len, indices.len });

        var vao: GLVaoHandle = 0;
        var vbo: GLBufferHandle = 0;
        var ebo: GLBufferHandle = 0;

        // 1. Generate and bind VAO
        gl.genVertexArrays(1, &vao);
        if (vao == 0) { std.log.err("Failed to generate VAO", .{}); return error.OpenGLOperationFailed; }
        gl.bindVertexArray(vao);

        // 2. Generate, bind, and buffer VBO (Vertex Buffer Object)
        gl.genBuffers(1, &vbo);
        if (vbo == 0) { std.log.err("Failed to generate VBO", .{}); gl.deleteVertexArrays(1, &vao); return error.OpenGLOperationFailed; }
        gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
        gl.bufferData(gl.ARRAY_BUFFER, @sizeOf([]const Vertex) * vertices.len, @ptrCast(*const anyopaque, vertices.ptr), gl.STATIC_DRAW);

        // 3. Generate, bind, and buffer EBO (Element Buffer Object)
        if (indices.len > 0) {
            gl.genBuffers(1, &ebo);
            if (ebo == 0) {
                std.log.err("Failed to generate EBO", .{});
                gl.deleteBuffers(1, &vbo);
                gl.deleteVertexArrays(1, &vao);
                return error.OpenGLOperationFailed;
            }
            gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
            gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf([]const u32) * indices.len, @ptrCast(*const anyopaque, indices.ptr), gl.STATIC_DRAW);
        }

        // 4. Setup vertex attributes for VertexPC (Position, Color)
        // Position attribute
        gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @intToPtr(*const anyopaque, @offsetOf(Vertex, "position")));
        gl.enableVertexAttribArray(0);
        // Color attribute
        gl.vertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @intToPtr(*const anyopaque, @offsetOf(Vertex, "color")));
        gl.enableVertexAttribArray(1);

        // 5. Unbind VAO (good practice, prevents accidental modification)
        gl.bindVertexArray(0);
        // Unbind VBO and EBO after VAO is unbound (VAO remembers EBO binding)
        gl.bindBuffer(gl.ARRAY_BUFFER, 0);
        if (ebo != 0) {
            gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
        }


        const owned_mesh = GLOwnedMesh {
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo,
            .index_count = @intCast(u32, indices.len),
        };

        self.meshes.put(handle, owned_mesh) catch |err| {
            std.log.err("Failed to store mesh data: {any}", .{err});
            // Clean up already created GL objects if map insertion fails
            gl.deleteVertexArrays(1, &vao);
            var buffers_to_delete = [_]GLBufferHandle{vbo, ebo};
            var num_buffers_to_delete: u32 = if (ebo == 0) 1 else 2;
            gl.deleteBuffers(num_buffers_to_delete, &buffers_to_delete);
            return err; // Propagate map error
        };

        std.log.info("GL Mesh created successfully. VAO: {d}, VBO: {d}, EBO: {d}, Handle: {d}", .{vao, vbo, ebo, handle});
        return handle;
    }

    pub fn drawMesh(self: *const GLRenderer, handle: GLMeshHandle, shader: Shader) void {
        if (!self.gl_loaded) {
            std.log.debug("GLRenderer.drawMesh (no-op, GL not loaded), handle: {d}", .{handle});
            return;
        }

        const mesh_data = self.meshes.get(handle) orelse {
            std.log.warn("GLRenderer.drawMesh: Attempted to draw non-existent mesh handle {d}", .{handle});
            return;
        };

        // Shader should be used by the caller before setting uniforms and drawing
        // shader.use(self.gl_loaded); // Or ensure it's part of a material system

        gl.bindVertexArray(mesh_data.vao);
        if (mesh_data.index_count > 0) {
            gl.drawElements(gl.TRIANGLES, mesh_data.index_count, gl.UNSIGNED_INT, null);
        } else {
            // This assumes non-indexed drawing if index_count is 0.
            // Need vertex_count in GLOwnedMesh for this. For now, only indexed.
            std.log.warn("GLRenderer.drawMesh: Mesh handle {d} has 0 indices, cannot draw.", .{handle});
        }
        gl.bindVertexArray(0); // Unbind VAO
    }

    pub fn destroyMesh(self: *GLRenderer, handle: GLMeshHandle) void {
        if (!self.gl_loaded) {
            std.log.debug("GLRenderer.destroyMesh (no-op, GL not loaded), handle: {d}", .{handle});
            return;
        }

        if (self.meshes.fetchRemove(handle)) |removed_mesh_entry| {
            const mesh_data = removed_mesh_entry.value;
            std.log.info("GLRenderer: Destroying GL Mesh - Handle: {d}, VAO: {d}, VBO: {d}, EBO: {d}", .{
                handle, mesh_data.vao, mesh_data.vbo, mesh_data.ebo
            });
            gl.deleteVertexArrays(1, &mesh_data.vao);
            var buffers_to_delete: [2]GLBufferHandle = .{ mesh_data.vbo, 0 };
            var num_buffers_to_delete: u32 = 1;
            if (mesh_data.ebo != 0) {
                buffers_to_delete[1] = mesh_data.ebo;
                num_buffers_to_delete = 2;
            }
            gl.deleteBuffers(num_buffers_to_delete, &buffers_to_delete[0]);
        } else {
            std.log.warn("GLRenderer.destroyMesh: Attempted to destroy non-existent mesh handle {d}", .{handle});
        }
    }
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
