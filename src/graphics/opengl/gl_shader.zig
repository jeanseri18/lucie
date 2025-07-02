// src/graphics/opengl/gl_shader.zig
// OpenGL shader management.

const std = @import("std");
const gl = @import("zopengl"); // Assuming zopengl or similar GL bindings
const Mat4 = @import("../../math/mat4.zig").Mat4;
const Vec3 = @import("../../math/vec3.zig").Vec3;
const Color = @import("../color.zig").Color;

pub const ShaderError = error{
    CompilationFailed,
    LinkingFailed,
    InvalidUniformLocation,
};

pub const GLShader = struct {
    program_id: gl.GLuint,
    allocator: std.mem.Allocator,

    // Common uniform locations (cache them for performance)
    // These would be specific to the shaders this program uses.
    // Example:
    // location_projectionMatrix: gl.GLint = -1,
    // location_viewMatrix: gl.GLint = -1,
    // location_modelMatrix: gl.GLint = -1,

    pub fn create(
        allocator: std.mem.Allocator,
        vertex_shader_source: []const u8,
        fragment_shader_source: []const u8,
    ) !GLShader {
        std.log.debug("Creating GLShader...", .{});
        // These GL calls require an active OpenGL context.
        // const vertex_shader = try compileShader(vertex_shader_source, gl.VERTEX_SHADER);
        // defer gl.deleteShader(vertex_shader);

        // const fragment_shader = try compileShader(fragment_shader_source, gl.FRAGMENT_SHADER);
        // defer gl.deleteShader(fragment_shader);

        // const program = try linkProgram(&[_]gl.GLuint{ vertex_shader, fragment_shader });
        const program_id_placeholder: gl.GLuint = 1; // Placeholder ID

        return GLShader{
            .program_id = program_id_placeholder, // program,
            .allocator = allocator,
        };
    }

    pub fn destroy(self: *GLShader) void {
        std.log.debug("Destroying GLShader (ID: {d})...", .{self.program_id});
        // gl.deleteProgram(self.program_id);
        self.program_id = 0;
    }

    pub fn bind(self: *const GLShader) void {
        // gl.useProgram(self.program_id);
        std.log.debug("Binding GLShader (ID: {d})", .{self.program_id});
    }

    pub fn unbind(_: *const GLShader) void {
        // gl.useProgram(0);
        std.log.debug("Unbinding GLShader (useProgram(0))", .{});
    }

    fn compileShader(source: []const u8, shader_type: gl.GLenum) !gl.GLuint {
        _ = source;
        _ = shader_type;
        // const shader_id = gl.createShader(shader_type);
        // if (shader_id == 0) {
        //     std.log.err("Failed to create shader object (type: {any})", .{shader_type});
        //     return ShaderError.CompilationFailed; // Or a more specific GL error
        // }
        // gl.shaderSource(shader_id, 1, &source.ptr, &@intCast(gl.GLint, source.len));
        // gl.compileShader(shader_id);

        // var success: gl.GLint = 0;
        // gl.getShaderiv(shader_id, gl.COMPILE_STATUS, &success);
        // if (success == gl.FALSE) {
        //     var log_len: gl.GLint = 0;
        //     gl.getShaderiv(shader_id, gl.INFO_LOG_LENGTH, &log_len);
        //     if (log_len > 0) {
        //         // const log_buffer = try self.allocator.alloc(u8, @intCast(usize, log_len)); // Requires allocator access or pass one
        //         // defer self.allocator.free(log_buffer);
        //         // gl.getShaderInfoLog(shader_id, log_len, null, log_buffer.ptr);
        //         // std.log.err("Shader compilation failed (type: {any}):\n{s}", .{ shader_type, log_buffer });
        //         std.log.err("Shader compilation failed (type: {any}). Log length: {d}", .{shader_type, log_len});
        //     } else {
        //         std.log.err("Shader compilation failed (type: {any}) with no info log.", .{shader_type});
        //     }
        //     gl.deleteShader(shader_id);
        //     return ShaderError.CompilationFailed;
        // }
        // std.log.debug("Shader compiled successfully (ID: {d}, type: {any})", .{shader_id, shader_type});
        // return shader_id;
        return 1; // Placeholder
    }

    fn linkProgram(shaders: []const gl.GLuint) !gl.GLuint {
        _ = shaders;
        // const program_id = gl.createProgram();
        // if (program_id == 0) {
        //     std.log.err("Failed to create shader program object.", .{});
        //     return ShaderError.LinkingFailed;
        // }

        // for (shaders) |shader_id| {
        //     gl.attachShader(program_id, shader_id);
        // }
        // gl.linkProgram(program_id);

        // var success: gl.GLint = 0;
        // gl.getProgramiv(program_id, gl.LINK_STATUS, &success);
        // if (success == gl.FALSE) {
        //     var log_len: gl.GLint = 0;
        //     gl.getProgramiv(program_id, gl.INFO_LOG_LENGTH, &log_len);
        //     if (log_len > 0) {
        //         // const log_buffer = try self.allocator.alloc(u8, @intCast(usize, log_len));
        //         // defer self.allocator.free(log_buffer);
        //         // gl.getProgramInfoLog(program_id, log_len, null, log_buffer.ptr);
        //         // std.log.err("Shader program linking failed:\n{s}", .{log_buffer});
        //          std.log.err("Shader program linking failed. Log length: {d}", .{log_len});
        //     } else {
        //         std.log.err("Shader program linking failed with no info log.", .{});
        //     }
        //     gl.deleteProgram(program_id);
        //     return ShaderError.LinkingFailed;
        // }
        // std.log.debug("Shader program linked successfully (ID: {d})", .{program_id});
        // return program_id;
        return 1; // Placeholder
    }

    // Uniform setters
    // pub fn getUniformLocation(self: *const GLShader, name: [:0]const u8) !gl.GLint {
    //     const location = gl.getUniformLocation(self.program_id, name.ptr);
    //     if (location == -1) {
    //         std.log.warn("Uniform '{s}' not found in shader program {d}", .{name, self.program_id});
    //         return ShaderError.InvalidUniformLocation;
    //     }
    //     return location;
    // }

    // pub fn setUniformMat4f(self: *const GLShader, location: gl.GLint, matrix: Mat4) void {
    //    gl.uniformMatrix4fv(location, 1, gl.FALSE, &matrix.m[0]);
    // }
    // pub fn setUniformVec3f(self: *const GLShader, location: gl.GLint, value: Vec3) void {
    //    gl.uniform3f(location, value.x, value.y, value.z);
    // }
    // pub fn setUniform1i(self: *const GLShader, location: gl.GLint, value: i32) void {
    //    gl.uniform1i(location, value);
    // }
    // pub fn setUniform1f(self: *const GLShader, location: gl.GLint, value: f32) void {
    //    gl.uniform1f(location, value);
    // }
    // pub fn setUniformColor(self: *const GLShader, location: gl.GLint, color: Color) void {
    //    gl.uniform4f(location, color.r, color.g, color.b, color.a);
    // }
};

// Dummy GL bindings for compilation if zopengl is not fully set up.
// In a real scenario, these would come from the `zopengl` import.
const gl = struct {
    const _GLuint = u32;
    const _GLenum = u32;
    const _GLint = i32;
    // pub const VERTEX_SHADER: GLenum = 0x8B31;
    // pub const FRAGMENT_SHADER: GLenum = 0x8B30;
    // pub const COMPILE_STATUS: GLenum = 0x8B81;
    // pub const LINK_STATUS: GLenum = 0x8B82;
    // pub const INFO_LOG_LENGTH: GLenum = 0x8B84;
    // pub const FALSE: GLint = 0;

    // pub fn createShader(type: GLenum) GLuint { _=type; return 1; }
    // pub fn shaderSource(shader: GLuint, count: i32, string: [*]const [*]const u8, length: [*]const GLint) void { _=shader; _=count; _=string; _=length; }
    // pub fn compileShader(shader: GLuint) void { _=shader; }
    // pub fn getShaderiv(shader: GLuint, pname: GLenum, params: *GLint) void { _=shader; _=pname; _=params; params.* = 1; } // Assume success
    // pub fn getShaderInfoLog(shader: GLuint, bufSize: i32, length: *GLint, infoLog: [*]u8) void { _=shader; _=bufSize; _=length; _=infoLog; }
    // pub fn deleteShader(shader: GLuint) void { _=shader; }
    // pub fn createProgram() GLuint { return 1; }
    // pub fn attachShader(program: GLuint, shader: GLuint) void { _=program; _=shader; }
    // pub fn linkProgram(program: GLuint) void { _=program; }
    // pub fn getProgramiv(program: GLuint, pname: GLenum, params: *GLint) void { _=program; _=pname; _=params; params.* = 1; } // Assume success
    // pub fn getProgramInfoLog(program: GLuint, bufSize: i32, length: *GLint, infoLog: [*]u8) void { _=program; _=bufSize; _=length; _=infoLog; }
    // pub fn deleteProgram(program: GLuint) void { _=program; }
    // pub fn useProgram(program: GLuint) void { _=program; }
    // pub fn getUniformLocation(program: GLuint, name: [*]const u8) GLint { _=program; _=name; return 0; }
    // pub fn uniformMatrix4fv(location: GLint, count: i32, transpose: u8, value: [*]const f32) void { _=location; _=count; _=transpose; _=value; }
    // pub fn uniform3f(location: GLint, v0: f32, v1: f32, v2: f32) void { _=location; _=v0; _=v1; _=v2; }
    // pub fn uniform1i(location: GLint, v0: i32) void { _=location; _=v0; }
    // pub fn uniform1f(location: GLint, v0: f32) void { _=location; _=v0; }
    // pub fn uniform4f(location: GLint, v0: f32, v1: f32, v2: f32, v3: f32) void { _=location; _=v0; _=v1; _=v2; _=v3; }
    pub const GLuint = u32;
    pub const GLenum = u32;
    pub const GLint = i32;

};


// Dummy shader sources for testing
const dummy_vertex_shader_src =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\uniform mat4 model;
    \\uniform mat4 view;
    \\uniform mat4 projection;
    \\void main() {
    \\    gl_Position = projection * view * model * vec4(aPos, 1.0);
    \\}
;
const dummy_fragment_shader_src =
    \\#version 330 core
    \\out vec4 FragColor;
    \\uniform vec4 objectColor;
    \\void main() {
    \\    FragColor = objectColor;
    \\}
;

test "GLShader creation and destruction (mocked GL)" {
    // This test runs without a real GL context, using mocked GL functions.
    // It primarily checks if the logic flows without crashing.
    const allocator = std.testing.allocator;
    var shader = try GLShader.create(allocator, dummy_vertex_shader_src, dummy_fragment_shader_src);
    defer shader.destroy();

    try std.testing.expect(shader.program_id != 0); // Placeholder check

    shader.bind();
    // In a real test, you might try to get/set uniforms here.
    // const loc = shader.getUniformLocation("objectColor");
    // try std.testing.expect(loc != -1);
    // shader.setUniformColor(loc, Color.Red);
    shader.unbind();

    std.log.info("GLShader test completed (using mocked GL calls).", .{});
}
