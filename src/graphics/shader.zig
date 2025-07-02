// src/graphics/shader.zig
// Placeholder for shader management.

const std = @import("std");
const gl = @import("gl"); // For GL types if used in struct, e.g. GLShaderHandle
const GLRenderer = @import("opengl/gl_renderer.zig"); // For GL types

pub const ShaderError = error{
    CompilationFailed,
    LinkingFailed,
    FileNotFound,
    InvalidUniform,
    NotInitialized,
};

pub const Shader = struct {
    allocator: std.mem.Allocator,
    program_id: GLRenderer.GLShaderHandle, // Placeholder, would be GLuint
    vertex_shader_path: []const u8,
    fragment_shader_path: []const u8,
    initialized: bool = false,

    // Placeholder create function
    pub fn createFromFile(
        allocator: std.mem.Allocator,
        vertex_path: []const u8,
        fragment_path: []const u8,
        // In a real scenario, this would take a GLRenderer or similar context
        // to compile and link shaders using gl.createShader, gl.compileShader, etc.
    ) !Shader {
        std.log.info("Shader: Creating from files (placeholder) - Vertex: {s}, Fragment: {s}", .{ vertex_path, fragment_path });

        // TODO: Actual shader loading, compilation, and linking:
        // 1. Read vertex shader source from vertex_path
        // 2. Read fragment shader source from fragment_path
        // 3. gl.createShader(gl.VERTEX_SHADER), gl.shaderSource, gl.compileShader, check status
        // 4. gl.createShader(gl.FRAGMENT_SHADER), gl.shaderSource, gl.compileShader, check status
        // 5. gl.createProgram, gl.attachShader (vertex), gl.attachShader (fragment), gl.linkProgram, check status
        // 6. gl.deleteShader (vertex_handle), gl.deleteShader (fragment_handle) after linking

        // For placeholder, just store paths and a dummy ID.
        const prog_id: GLRenderer.GLShaderHandle = 1; // Dummy program ID

        return Shader{
            .allocator = allocator,
            .program_id = prog_id,
            .vertex_shader_path = try allocator.dupe(u8, vertex_path),
            .fragment_shader_path = try allocator.dupe(u8, fragment_path),
            .initialized = true,
        };
    }

    pub fn destroy(self: *Shader) void {
        if (!self.initialized) return;
        std.log.info("Shader: Destroying (placeholder) - Program ID: {d}, Vertex: {s}, Fragment: {s}", .{
            self.program_id, self.vertex_shader_path, self.fragment_shader_path,
        });
        // TODO: Actual shader deletion: gl.deleteProgram(self.program_id)
        self.allocator.free(self.vertex_shader_path);
        self.allocator.free(self.fragment_shader_path);
        self.initialized = false;
    }

    pub fn use(self: Shader) void {
        if (!self.initialized) {
            std.log.warn("Shader: Attempted to use uninitialized shader.", .{});
            return;
        }
        std.log.debug("Shader: Using program ID {d} (placeholder)", .{self.program_id});
        // TODO: Actual shader usage: gl.useProgram(self.program_id)
    }

    // Placeholder uniform setters
    // pub fn setUniformMat4(self: Shader, name: [:0]const u8, matrix: Mat4) void {
    //     if (!self.initialized) return;
    //     // TODO: gl.getUniformLocation, gl.uniformMatrix4fv
    //     std.log.debug("Shader: Setting Mat4 uniform '{s}' (placeholder)", .{name});
    // }
    // pub fn setUniformVec3(self: Shader, name: [:0]const u8, vector: Vec3) void { ... }
    // pub fn setUniformFloat(self: Shader, name: [:0]const u8, value: f32) void { ... }
    // pub fn setUniformInt(self: Shader, name: [:0]const u8, value: i32) void { ... }
};

test "Shader placeholder create, use, destroy" {
    const allocator = std.testing.allocator;
    var shader = try Shader.createFromFile(allocator, "test.vert", "test.frag");
    defer shader.destroy();

    try std.testing.expect(shader.initialized);
    try std.testing.expectEqualStrings("test.vert", shader.vertex_shader_path);
    try std.testing.expect(shader.program_id != 0); // Dummy ID is 1

    shader.use(); // Should log

    // Test destroy idempotency
    shader.destroy();
    try std.testing.expect(!shader.initialized);
    shader.destroy(); // Should do nothing
}
