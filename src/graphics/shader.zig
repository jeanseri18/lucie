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
        gl_is_loaded: bool, // Parameter to indicate if GL context is available
    ) !Shader {
        std.log.info("Shader: Creating from files - Vertex: {s}, Fragment: {s}. GL Loaded: {any}", .{ vertex_path, fragment_path, gl_is_loaded });

        // Placeholder for shader source code
        // In a real app, this would use std.fs to read files.
        // For sandbox, we'll use dummy sources.
        const dummy_vertex_src =
            \\#version 330 core
            \\layout (location = 0) in vec3 aPos;
            \\void main() {
            \\    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
            \\};
        const dummy_fragment_src =
            \\#version 330 core
            \\out vec4 FragColor;
            \\void main() {
            \\    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
            \\};

        var prog_id: GLRenderer.GLShaderHandle = 0; // Default to 0 if not loaded

        if (gl_is_loaded) {
            // 1. Compile Vertex Shader
            const vertex_shader = gl.createShader(gl.VERTEX_SHADER);
            if (vertex_shader == 0) return ShaderError.CompilationFailed; // Failed to create shader object
            var v_src_ptr = dummy_vertex_src.ptr;
            gl.shaderSource(vertex_shader, 1, &v_src_ptr, null);
            gl.compileShader(vertex_shader);

            var success: gl.GLint = 0;
            var info_log_buf: [512]u8 = undefined;
            gl.getShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
            if (success == gl.FALSE) {
                gl.getShaderInfoLog(vertex_shader, 512, null, &info_log_buf);
                std.log.err("Vertex shader compilation failed for {s}:\n{s}", .{ vertex_path, info_log_buf });
                gl.deleteShader(vertex_shader);
                return ShaderError.CompilationFailed;
            }

            // 2. Compile Fragment Shader
            const fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
            if (fragment_shader == 0) { // Failed to create shader object
                gl.deleteShader(vertex_shader); // Clean up vertex shader
                return ShaderError.CompilationFailed;
            }
            var f_src_ptr = dummy_fragment_src.ptr;
            gl.shaderSource(fragment_shader, 1, &f_src_ptr, null);
            gl.compileShader(fragment_shader);

            gl.getShaderiv(fragment_shader, gl.COMPILE_STATUS, &success);
            if (success == gl.FALSE) {
                gl.getShaderInfoLog(fragment_shader, 512, null, &info_log_buf);
                std.log.err("Fragment shader compilation failed for {s}:\n{s}", .{ fragment_path, info_log_buf });
                gl.deleteShader(vertex_shader);
                gl.deleteShader(fragment_shader);
                return ShaderError.CompilationFailed;
            }

            // 3. Link Shader Program
            prog_id = gl.createProgram();
            if (prog_id == 0) { // Failed to create program object
                gl.deleteShader(vertex_shader);
                gl.deleteShader(fragment_shader);
                return ShaderError.LinkingFailed;
            }
            gl.attachShader(prog_id, vertex_shader);
            gl.attachShader(prog_id, fragment_shader);
            gl.linkProgram(prog_id);

            gl.getProgramiv(prog_id, gl.LINK_STATUS, &success);
            if (success == gl.FALSE) {
                gl.getProgramInfoLog(prog_id, 512, null, &info_log_buf);
                std.log.err("Shader program linking failed for {s} & {s}:\n{s}", .{ vertex_path, fragment_path, info_log_buf });
                gl.deleteShader(vertex_shader);
                gl.deleteShader(fragment_shader);
                gl.deleteProgram(prog_id);
                return ShaderError.LinkingFailed;
            }

            // Shaders are linked, no longer need individual objects
            gl.deleteShader(vertex_shader);
            gl.deleteShader(fragment_shader);
            std.log.info("Shader: Successfully compiled and linked program ID {d}", .{prog_id});
        } else {
            std.log.warn("Shader: GL not loaded, using dummy program ID for {s}, {s}", .{vertex_path, fragment_path});
            prog_id = 999; // Dummy ID for non-GL mode
        }

        return Shader{
            .allocator = allocator,
            .program_id = prog_id,
            .vertex_shader_path = try allocator.dupe(u8, vertex_path),
            .fragment_shader_path = try allocator.dupe(u8, fragment_path),
            .initialized = true, // Initialized even if GL is not loaded (uses dummy ID)
        };
    }

    pub fn destroy(self: *Shader, gl_is_loaded: bool) void {
        if (!self.initialized) return;

        if (gl_is_loaded and self.program_id != 0 and self.program_id != 999) { // 999 is dummy ID
            std.log.info("Shader: Destroying program ID {d}", .{self.program_id});
            gl.deleteProgram(self.program_id);
        } else {
             std.log.info("Shader: Destroying (placeholder or no GL) - Vertex: {s}, Fragment: {s}", .{
                self.vertex_shader_path, self.fragment_shader_path,
            });
        }
        self.allocator.free(self.vertex_shader_path);
        self.allocator.free(self.fragment_shader_path);
        self.program_id = 0;
        self.initialized = false;
    }

    pub fn use(self: Shader, gl_is_loaded: bool) void {
        if (!self.initialized) {
            std.log.warn("Shader: Attempted to use uninitialized shader.", .{});
            return;
        }
        if (gl_is_loaded and self.program_id != 0 and self.program_id != 999) {
            // std.log.debug("Shader: Using program ID {d}", .{self.program_id});
            gl.useProgram(self.program_id);
        } else {
            std.log.debug("Shader: Using program ID {d} (placeholder or no GL)", .{self.program_id});
        }
    }

    // Placeholder uniform setters, these would also need gl_is_loaded
    pub fn getUniformLocation(self: Shader, gl_is_loaded: bool, name: [:0]const u8) i32 {
        if (!self.initialized or !gl_is_loaded or self.program_id == 0 or self.program_id == 999) {
            std.log.debug("Shader.getUniformLocation (no-op, shader not ready or GL not loaded): {s}", .{name});
            return -1;
        }
        const loc = gl.getUniformLocation(self.program_id, name.ptr);
        // if (loc == -1) {
        //     std.log.warn("Shader: Uniform '{s}' not found in program {d}", .{ name, self.program_id });
        // }
        return loc;
    }

    pub fn setUniformMat4(self: Shader, gl_is_loaded: bool, name: [:0]const u8, matrix: *const @import("../math/mat4.zig").Mat4) void {
        if (!self.initialized or !gl_is_loaded or self.program_id == 0 or self.program_id == 999) {
             std.log.debug("Shader.setUniformMat4 (no-op, shader not ready or GL not loaded): {s}", .{name});
            return;
        }
        const loc = self.getUniformLocation(gl_is_loaded, name);
        if (loc != -1) {
            // std.log.debug("Shader: Setting Mat4 uniform '{s}' at loc {d}", .{name, loc});
            gl.uniformMatrix4fv(loc, 1, gl.FALSE, &matrix.cols[0].x);
        }
    }

    pub fn setUniformVec3(self: Shader, gl_is_loaded: bool, name: [:0]const u8, vector: @import("../math/vec3.zig").Vec3) void {
         if (!self.initialized or !gl_is_loaded or self.program_id == 0 or self.program_id == 999) {
            std.log.debug("Shader.setUniformVec3 (no-op, shader not ready or GL not loaded): {s}", .{name});
            return;
        }
        const loc = self.getUniformLocation(gl_is_loaded, name);
        if (loc != -1) {
            gl.uniform3f(loc, vector.x, vector.y, vector.z);
        }
    }

    pub fn setUniformFloat(self: Shader, gl_is_loaded: bool, name: [:0]const u8, value: f32) void {
        if (!self.initialized or !gl_is_loaded or self.program_id == 0 or self.program_id == 999) {
            std.log.debug("Shader.setUniformFloat (no-op, shader not ready or GL not loaded): {s}", .{name});
            return;
        }
        const loc = self.getUniformLocation(gl_is_loaded, name);
        if (loc != -1) {
            gl.uniform1f(loc, value);
        }
    }

    pub fn setUniformInt(self: Shader, gl_is_loaded: bool, name: [:0]const u8, value: i32) void {
        if (!self.initialized or !gl_is_loaded or self.program_id == 0 or self.program_id == 999) {
            std.log.debug("Shader.setUniformInt (no-op, shader not ready or GL not loaded): {s}", .{name});
            return;
        }
        const loc = self.getUniformLocation(gl_is_loaded, name);
        if (loc != -1) {
            gl.uniform1i(loc, value);
        }
    }
};

test "Shader placeholder create, use, destroy" {
    const allocator = std.testing.allocator;
    // Test with gl_is_loaded = false, as we don't have a real GL context in tests
    const gl_is_loaded_for_test = false;
    var shader = try Shader.createFromFile(allocator, "test.vert", "test.frag", gl_is_loaded_for_test);
    defer shader.destroy(gl_is_loaded_for_test);

    try std.testing.expect(shader.initialized);
    try std.testing.expectEqualStrings("test.vert", shader.vertex_shader_path);
    // When gl_is_loaded is false, it should get the dummy ID (e.g., 999)
    try std.testing.expect(shader.program_id == 999 or shader.program_id == 0);


    shader.use(gl_is_loaded_for_test); // Should log

    // Test destroy idempotency
    shader.destroy(gl_is_loaded_for_test);
    try std.testing.expect(!shader.initialized);
    shader.destroy(gl_is_loaded_for_test); // Should do nothing
}
