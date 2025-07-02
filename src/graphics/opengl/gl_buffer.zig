// src/graphics/opengl/gl_buffer.zig
// OpenGL buffer management (VBOs, EBOs/IBOs, UBOs).

const std = @import("std");
const gl = @import("zopengl"); // Assuming zopengl or similar GL bindings

pub const BufferError = error{
    CreationFailed,
    AllocationFailed,
    InvalidType,
    InvalidUsage,
    BufferNotBound,
};

pub const GLBufferType = enum {
    Vertex, // Corresponds to gl.ARRAY_BUFFER
    Index,  // Corresponds to gl.ELEMENT_ARRAY_BUFFER
    Uniform, // Corresponds to gl.UNIFORM_BUFFER

    pub fn toGL(self: GLBufferType) gl.GLenum {
        return switch (self) {
            .Vertex => 0, // gl.ARRAY_BUFFER,
            .Index => 1, // gl.ELEMENT_ARRAY_BUFFER,
            .Uniform => 2, // gl.UNIFORM_BUFFER,
        };
    }
};

// BufferUsage hints for OpenGL optimization
pub const GLBufferUsage = enum {
    StaticDraw,  // Data set once, used many times
    DynamicDraw, // Data changed frequently, used many times
    StreamDraw,  // Data set once, used once or few times

    pub fn toGL(self: GLBufferUsage) gl.GLenum {
        return switch (self) {
            .StaticDraw => 0, // gl.STATIC_DRAW,
            .DynamicDraw => 1, // gl.DYNAMIC_DRAW,
            .StreamDraw => 2, // gl.STREAM_DRAW,
        };
    }
};

pub const GLBuffer = struct {
    buffer_id: gl.GLuint,
    buffer_type: GLBufferType,
    size_bytes: usize,
    usage_hint: GLBufferUsage,
    // allocator: std.mem.Allocator, // If any CPU-side copy is kept or for internal ops

    pub fn create(
        // allocator_param: std.mem.Allocator,
        buffer_type_param: GLBufferType,
        size_bytes_param: usize,
        data: ?[]const u8, // Initial data, can be null to allocate uninitialized buffer
        usage_hint_param: GLBufferUsage,
    ) !GLBuffer {
        std.log.debug("Creating GLBuffer: type {any}, size {d} bytes, usage {any}", .{
            buffer_type_param, size_bytes_param, usage_hint_param
        });

        // var id: gl.GLuint = 0;
        // gl.genBuffers(1, &id);
        // if (id == 0) return BufferError.CreationFailed;
        const id_placeholder: gl.GLuint = 1; // Placeholder

        // const gl_type = buffer_type_param.toGL();
        // const gl_usage = usage_hint_param.toGL();
        // const data_ptr: ?*const anyopaque = if (data) |d| d.ptr else null;

        // gl.bindBuffer(gl_type, id);
        // gl.bufferData(gl_type, @intCast(gl.GLsizeiptr, size_bytes_param), data_ptr, gl_usage);
        // gl.bindBuffer(gl_type, 0); // Unbind after configuration

        return GLBuffer{
            .buffer_id = id_placeholder, //id,
            .buffer_type = buffer_type_param,
            .size_bytes = size_bytes_param,
            .usage_hint = usage_hint_param,
            // .allocator = allocator_param,
        };
    }

    pub fn destroy(self: *GLBuffer) void {
        std.log.debug("Destroying GLBuffer (ID: {d}, type: {any})", .{self.buffer_id, self.buffer_type});
        // gl.deleteBuffers(1, &self.buffer_id);
        self.buffer_id = 0;
    }

    pub fn bind(self: *const GLBuffer) void {
        // gl.bindBuffer(self.buffer_type.toGL(), self.buffer_id);
        std.log.debug("Binding GLBuffer (ID: {d}, type: {any})", .{self.buffer_id, self.buffer_type});
    }

    pub fn unbind(buffer_type: GLBufferType) void {
        // gl.bindBuffer(buffer_type.toGL(), 0);
        std.log.debug("Unbinding GLBuffer (type: {any})", .{buffer_type});
    }

    // Updates a sub-region of the buffer. Buffer must be bound.
    pub fn updateData(self: *const GLBuffer, offset_bytes: usize, data: []const u8) !void {
        if (offset_bytes + data.len > self.size_bytes) {
            std.log.err("Buffer update out of bounds. Offset: {d}, DataLen: {d}, BufferSize: {d}", .{
                offset_bytes, data.len, self.size_bytes});
            return BufferError.AllocationFailed; // Or a more specific error like OutOfBounds
        }
        // Ensure buffer is bound before calling, or bind it here.
        // For safety, this function could take a 'is_bound_externally' flag or always bind/unbind.
        // Assuming it's bound by the caller for this example.
        // gl.bufferSubData(self.buffer_type.toGL(), @intCast(gl.GLintptr, offset_bytes), @intCast(gl.GLsizeiptr, data.len), data.ptr);
        std.log.debug("Updating GLBuffer (ID: {d}) at offset {d} with {d} bytes.", .{self.buffer_id, offset_bytes, data.len});
    }

    // Reallocates the entire buffer (like glBufferData). Buffer must be bound.
    pub fn setData(self: *GLBuffer, size_bytes_param: usize, data: ?[]const u8, usage_hint_param: GLBufferUsage) !void {
        // gl.bufferData(self.buffer_type.toGL(), @intCast(gl.GLsizeiptr, size_bytes_param), if (data) |d| d.ptr else null, usage_hint_param.toGL());
        self.size_bytes = size_bytes_param;
        self.usage_hint = usage_hint_param;
        std.log.debug("Setting data for GLBuffer (ID: {d}), new size {d} bytes, usage {any}", .{self.buffer_id, size_bytes_param, usage_hint_param});
    }
};

// Dummy GL bindings for compilation
const gl = struct {
    const _GLuint = u32;
    const _GLenum = u32;
    // pub const ARRAY_BUFFER: GLenum = 0x8892;
    // pub const ELEMENT_ARRAY_BUFFER: GLenum = 0x8893;
    // pub const UNIFORM_BUFFER: GLenum = 0x8A11;
    // pub const STATIC_DRAW: GLenum = 0x88E4;
    // pub const DYNAMIC_DRAW: GLenum = 0x88E8;
    // pub const STREAM_DRAW: GLenum = 0x88E0;

    // pub fn genBuffers(n: i32, buffers: *GLuint) void { _=n; buffers.* = 1; } // Mock creation
    // pub fn deleteBuffers(n: i32, buffers: *const GLuint) void { _=n; _=buffers; }
    // pub fn bindBuffer(target: GLenum, buffer: GLuint) void { _=target; _=buffer; }
    // pub fn bufferData(target: GLenum, size: isize, data: ?[*]const anyopaque, usage: GLenum) void {
    //     _=target; _=size; _=data; _=usage;
    // }
    // pub fn bufferSubData(target: GLenum, offset: isize, size: isize, data: [*]const anyopaque) void {
    //    _=target; _=offset; _=size; _=data;
    // }
    pub const GLuint = u32;
    pub const GLenum = u32;
    pub const GLsizeiptr = isize; // Or usize, depending on zopengl definitions
    pub const GLintptr = isize;
};

test "GLBuffer creation and operations (mocked GL)" {
    const allocator = std.testing.allocator;

    // Vertex Buffer
    const vertices: []const f32 = &.{
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
         0.0,  0.5, 0.0,
    };
    const vertex_data = std.mem.sliceAsBytes(vertices);
    var vbo = try GLBuffer.create(.Vertex, vertex_data.len, vertex_data, .StaticDraw);
    defer vbo.destroy();

    try std.testing.expect(vbo.buffer_id != 0);
    try std.testing.expect(vbo.buffer_type == .Vertex);
    try std.testing.expect(vbo.size_bytes == vertex_data.len);

    vbo.bind();
    // Simulate updating part of the buffer
    const updated_vertices: []const f32 = &.{ 0.1, 0.2, 0.3 };
    const updated_vertex_data = std.mem.sliceAsBytes(updated_vertices);
    if (vbo.size_bytes >= updated_vertex_data.len) { // Ensure space
         try vbo.updateData(0, updated_vertex_data);
    }
    GLBuffer.unbind(.Vertex);


    // Index Buffer
    const indices: []const u16 = &.{0, 1, 2};
    const index_data = std.mem.sliceAsBytes(indices);
    var ibo = try GLBuffer.create(.Index, index_data.len, index_data, .StaticDraw);
    defer ibo.destroy();
    try std.testing.expect(ibo.buffer_type == .Index);

    ibo.bind();
    GLBuffer.unbind(.Index);

    std.log.info("GLBuffer test completed (using mocked GL calls).", .{});
}

test "GLBufferType and GLBufferUsage toGL mapping" {
    // These tests would be more meaningful if gl constants were actual values.
    // For now, they just ensure the functions can be called.
    _ = GLBufferType.Vertex.toGL();
    _ = GLBufferType.Index.toGL();
    _ = GLBufferType.Uniform.toGL();
    _ = GLBufferUsage.StaticDraw.toGL();
    _ = GLBufferUsage.DynamicDraw.toGL();
    _ = GLBufferUsage.StreamDraw.toGL();
    try std.testing.expect(true); // Placeholder
}
