// src/graphics/mesh.zig
// 3D Mesh representation (vertices, indices, normals, texcoords).

const std = @import("std");
const Vec2 = @import("../math/vec2.zig").Vec2;
const Vec3 = @import("../math/vec3.zig").Vec3;
const GLBuffer = @import("opengl/gl_buffer.zig").GLBuffer; // Using GLBuffer directly for now
const GLBufferType = @import("opengl/gl_buffer.zig").GLBufferType;
const GLBufferUsage = @import("opengl/gl_buffer.zig").GLBufferUsage;
// const gl = @import("zopengl"); // If VAO setup is done here

// Standard vertex definition for a 3D mesh
// Could be configurable or have multiple types (e.g., PBRVertex)
pub const Vertex = extern struct {
    position: Vec3,
    normal: Vec3,
    tex_coords: Vec2,
    // Optional: tangent: Vec3, bitangent: Vec3, color: Color, bone_ids: [4]u8, bone_weights: [4]f32
};

pub const Mesh = struct {
    allocator: std.mem.Allocator,

    vertices: std.ArrayList(Vertex),
    indices: std.ArrayList(u32), // Using u32 for indices, common for larger meshes

    // GPU resources (OpenGL specific for now)
    vao: u32 = 0, // Vertex Array Object
    vbo: ?GLBuffer = null, // Vertex Buffer Object
    ibo: ?GLBuffer = null, // Index Buffer Object (Element Buffer Object)

    is_uploaded: bool = false, // Flag to check if data is on GPU

    pub fn init(allocator_param: std.mem.Allocator) Mesh {
        return Mesh{
            .allocator = allocator_param,
            .vertices = std.ArrayList(Vertex).init(allocator_param),
            .indices = std.ArrayList(u32).init(allocator_param),
        };
    }

    pub fn deinit(self: *Mesh) void {
        std.log.debug("Deinitializing Mesh...", .{});
        // Free CPU-side data
        self.vertices.deinit();
        self.indices.deinit();

        // Free GPU-side data if uploaded
        if (self.is_uploaded) {
            self.destroyGPUResources();
        }
    }

    pub fn addVertex(self: *Mesh, vertex: Vertex) !void {
        try self.vertices.append(vertex);
        self.is_uploaded = false; // Data changed, needs re-upload
    }

    pub fn addIndex(self: *Mesh, index: u32) !void {
        try self.indices.append(index);
        self.is_uploaded = false;
    }

    pub fn addTriangle(self: *Mesh, i1: u32, i2: u32, i3: u32) !void {
        try self.indices.appendSlice(&[_]u32{i1, i2, i3});
        self.is_uploaded = false;
    }

    // Uploads mesh data to the GPU (VBO, IBO, VAO setup)
    // This requires an active OpenGL context.
    pub fn uploadToGPU(self: *Mesh, usage: GLBufferUsage) !void {
        if (self.vertices.items.len == 0) {
            std.log.warn("Attempting to upload empty mesh to GPU.", .{});
            return; // Or return an error
        }

        std.log.debug("Uploading mesh to GPU: {d} vertices, {d} indices.", .{
            self.vertices.items.len, self.indices.items.len
        });

        // Destroy existing GPU resources if they exist (e.g. re-uploading)
        if (self.is_uploaded) {
            self.destroyGPUResources();
        }

        // Create VBO
        const vbo_data = std.mem.sliceAsBytes(self.vertices.items);
        var new_vbo = try GLBuffer.create(.Vertex, vbo_data.len, vbo_data, usage);
        self.vbo = new_vbo;

        // Create IBO (if indices exist)
        if (self.indices.items.len > 0) {
            const ibo_data = std.mem.sliceAsBytes(self.indices.items);
            var new_ibo = try GLBuffer.create(.Index, ibo_data.len, ibo_data, usage);
            self.ibo = new_ibo;
        }

        // Create and configure VAO
        // gl.genVertexArrays(1, &self.vao);
        // gl.bindVertexArray(self.vao);

        // self.vbo.?.bind();
        // if (self.ibo) |*ibo| ibo.bind();

        // Vertex attribute pointers (match Vertex struct layout)
        // Position
        // gl.enableVertexAttribArray(0);
        // gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "position")));
        // Normal
        // gl.enableVertexAttribArray(1);
        // gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "normal")));
        // TexCoords
        // gl.enableVertexAttribArray(2);
        // gl.vertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "tex_coords")));

        // gl.bindVertexArray(0); // Unbind VAO
        // GLBuffer.unbind(.Vertex); // Unbind VBO
        // if (self.ibo != null) GLBuffer.unbind(.Index); // Unbind IBO

        self.is_uploaded = true;
        std.log.debug("Mesh uploaded to GPU successfully. VAO ID: {d} (mocked)", .{self.vao});
    }

    fn destroyGPUResources(self: *Mesh) void {
        std.log.debug("Destroying GPU resources for mesh (VAO: {d})", .{self.vao});
        // if (self.vao != 0) {
        //     gl.deleteVertexArrays(1, &self.vao);
        //     self.vao = 0;
        // }
        if (self.vbo) |*vbo| {
            vbo.destroy();
            self.vbo = null;
        }
        if (self.ibo) |*ibo| {
            ibo.destroy();
            self.ibo = null;
        }
        self.is_uploaded = false;
    }

    // Binds the VAO for rendering.
    // Assumes mesh is already uploaded.
    pub fn bind(self: *const Mesh) void {
        if (!self.is_uploaded || self.vao == 0) {
            std.log.warn("Attempting to bind mesh VAO that is not uploaded or invalid.", .{});
            return;
        }
        // gl.bindVertexArray(self.vao);
        std.log.debug("Binding mesh VAO (ID: {d} - mocked)", .{self.vao});
    }

    pub fn unbind(_: *const Mesh) void {
        // gl.bindVertexArray(0);
        std.log.debug("Unbinding mesh VAO (bind VAO 0)", .{});
    }

    // Renders the mesh. Assumes VAO is bound and shader is active.
    pub fn draw(self: *const Mesh) void {
        if (!self.is_uploaded) {
            std.log.warn("Attempting to draw mesh that is not uploaded to GPU.", .{});
            return;
        }

        // This function assumes the VAO is already bound by the caller (or Renderer)
        // and the correct shader is active.
        if (self.indices.items.len > 0) {
            // gl.drawElements(gl.TRIANGLES, @intCast(gl.GLsizei, self.indices.items.len), gl.UNSIGNED_INT, null);
             std.log.debug("Drawing mesh elements: {d} indices (mocked call)", .{self.indices.items.len});
        } else if (self.vertices.items.len > 0) {
            // gl.drawArrays(gl.TRIANGLES, 0, @intCast(gl.GLsizei, self.vertices.items.len));
            std.log.debug("Drawing mesh arrays: {d} vertices (mocked call)", .{self.vertices.items.len});
        } else {
            std.log.warn("Attempting to draw mesh with no vertices.", .{});
        }
    }

    // Primitive shapes (static methods for creating simple meshes)
    pub fn createCube(allocator: std.mem.Allocator, size: f32) !Mesh {
        var cube = Mesh.init(allocator);
        const half_size = size * 0.5;

        // Define vertices for a cube (positions, normals, tex_coords)
        // This is a simplified example. A full cube has 24 unique vertices (6 faces * 4 verts)
        // if normals and texcoords are per-face. Or 8 vertices if sharing and normals are averaged.
        // For simplicity, let's define a few indicative vertices.
        // A full cube definition is lengthy.
        const verts_data: []const Vertex = &.{
            // Front face
            .{ .position = Vec3.new(-half_size, -half_size,  half_size), .normal = Vec3.new(0,0,1), .tex_coords = Vec2.new(0,0) },
            .{ .position = Vec3.new( half_size, -half_size,  half_size), .normal = Vec3.new(0,0,1), .tex_coords = Vec2.new(1,0) },
            .{ .position = Vec3.new( half_size,  half_size,  half_size), .normal = Vec3.new(0,0,1), .tex_coords = Vec2.new(1,1) },
            .{ .position = Vec3.new(-half_size,  half_size,  half_size), .normal = Vec3.new(0,0,1), .tex_coords = Vec2.new(0,1) },
            // Back face (example, more needed)
            .{ .position = Vec3.new(-half_size, -half_size, -half_size), .normal = Vec3.new(0,0,-1), .tex_coords = Vec2.new(0,0) },
            .{ .position = Vec3.new( half_size, -half_size, -half_size), .normal = Vec3.new(0,0,-1), .tex_coords = Vec2.new(1,0) },
            .{ .position = Vec3.new( half_size,  half_size, -half_size), .normal = Vec3.new(0,0,-1), .tex_coords = Vec2.new(1,1) },
            .{ .position = Vec3.new(-half_size,  half_size, -half_size), .normal = Vec3.new(0,0,-1), .tex_coords = Vec2.new(0,1) },
        };
        try cube.vertices.appendSlice(verts_data);

        // Define indices for the cube (2 triangles per face * 6 faces = 12 triangles = 36 indices)
        const indices_data: []const u32 = &.{
            0, 1, 2,  0, 2, 3, // Front face
            4, 5, 6,  4, 6, 7, // Back face (example, more needed, ensure correct winding and vertex indices)
            // ... other faces
        };
        try cube.indices.appendSlice(indices_data);

        std.log.info("Created cube mesh (primitive). Verts: {d}, Indices: {d}", .{cube.vertices.items.len, cube.indices.items.len});
        return cube;
    }
};

// Dummy GL bindings for compilation
const gl = struct {
    const _GLuint = u32;
    const _GLenum = u32;
    const _GLsizei = i32;
    // pub const TRIANGLES: GLenum = 0x0004;
    // pub const UNSIGNED_INT: GLenum = 0x1405;
    // pub const FLOAT: GLenum = 0x1406;
    // pub const FALSE: u8 = 0;

    // pub fn genVertexArrays(n: i32, arrays: *GLuint) void { _=n; arrays.* = 1; } // Mock VAO ID
    // pub fn deleteVertexArrays(n: i32, arrays: *const GLuint) void { _=n; _=arrays; }
    // pub fn bindVertexArray(array: GLuint) void { _=array; }
    // pub fn enableVertexAttribArray(index: GLuint) void { _=index; }
    // pub fn vertexAttribPointer(index: GLuint, size: i32, type: GLenum, normalized: u8, stride: i32, pointer: ?*const anyopaque) void {
    //     _=index; _=size; _=type; _=normalized; _=stride; _=pointer;
    // }
    // pub fn drawArrays(mode: GLenum, first: i32, count: i32) void { _=mode; _=first; _=count; }
    // pub fn drawElements(mode: GLenum, count: i32, type: GLenum, indices: ?*const anyopaque) void {
    //     _=mode; _=count; _=type; _=indices;
    // }
};

test "Mesh creation and data management" {
    const allocator = std.testing.allocator;
    var mesh = Mesh.init(allocator);
    defer mesh.deinit();

    // Add some vertices and indices
    try mesh.addVertex(.{ .position = Vec3.new(0,0,0), .normal = Vec3.new(0,0,1), .tex_coords = Vec2.new(0,0) });
    try mesh.addVertex(.{ .position = Vec3.new(1,0,0), .normal = Vec3.new(0,0,1), .tex_coords = Vec2.new(1,0) });
    try mesh.addVertex(.{ .position = Vec3.new(0,1,0), .normal = Vec3.new(0,0,1), .tex_coords = Vec2.new(0,1) });
    try mesh.addTriangle(0, 1, 2);

    try std.testing.expect(mesh.vertices.items.len == 3);
    try std.testing.expect(mesh.indices.items.len == 3);
    try std.testing.expect(!mesh.is_uploaded);

    // Simulate GPU upload (mocked GL calls)
    // In a real test with GL context, this would create actual GPU resources.
    try mesh.uploadToGPU(.StaticDraw);
    try std.testing.expect(mesh.is_uploaded);
    try std.testing.expect(mesh.vbo != null);
    try std.testing.expect(mesh.ibo != null);
    // try std.testing.expect(mesh.vao != 0); // VAO ID would be non-zero

    mesh.bind(); // Mocked bind
    mesh.draw(); // Mocked draw
    Mesh.unbind(&mesh); // Mocked unbind

    // Test re-upload (e.g. after adding more data)
    try mesh.addVertex(.{ .position = Vec3.new(1,1,0), .normal = Vec3.new(0,0,1), .tex_coords = Vec2.new(1,1) });
    try std.testing.expect(!mesh.is_uploaded); // Should be marked dirty
    try mesh.uploadToGPU(.StaticDraw); // Re-uploads
    try std.testing.expect(mesh.is_uploaded);


    std.log.info("Mesh test completed (using mocked GL calls).", .{});
}

test "Mesh primitive creation (Cube)" {
    const allocator = std.testing.allocator;
    var cube_mesh = try Mesh.createCube(allocator, 1.0);
    defer cube_mesh.deinit();

    try std.testing.expect(cube_mesh.vertices.items.len > 0);
    try std.testing.expect(cube_mesh.indices.items.len > 0);

    // Optionally, upload and "render" the cube
    try cube_mesh.uploadToGPU(.StaticDraw);
    cube_mesh.bind();
    cube_mesh.draw();
    Mesh.unbind(&cube_mesh);

    std.log.info("Cube primitive mesh test completed.", .{});
}
