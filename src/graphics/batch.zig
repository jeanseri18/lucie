// src/graphics/batch.zig
// Sprite batching system for efficient rendering of many sprites.

const std = @import("std");
const Sprite = @import("sprite.zig").Sprite;
const GLTexture = @import("opengl/gl_texture.zig").GLTexture; // Or a generic texture handle
const GLShader = @import("opengl/gl_shader.zig").GLShader;   // Or a generic shader handle
const GLBuffer = @import("opengl/gl_buffer.zig").GLBuffer;
const GLBufferType = @import("opengl/gl_buffer.zig").GLBufferType;
const GLBufferUsage = @import("opengl/gl_buffer.zig").GLBufferUsage;
const Color = @import("color.zig").Color;
const Mat4 = @import("../math/mat4.zig").Mat4;
const Vec2 = @import("../math/vec2.zig").Vec2;
const Vec3 = @import("../math/vec3.zig").Vec3;

// Represents a single vertex for a sprite quad.
// Could be part of the batch renderer or a shared graphics types file.
pub const SpriteVertex = extern struct {
    position: Vec3,    // x, y, z (z for layering if needed, or 0 for 2D)
    color: Color,      // r, g, b, a
    tex_coords: Vec2,  // u, v

    // Optional: texture_id (for multi-texture batching / texture arrays)
    // tex_id: f32,
};

// Configuration for the SpriteBatcher
pub const SpriteBatcherConfig = struct {
    max_sprites: usize = 1000, // Max sprites per batch before flushing
    // TODO: Add other config options like custom shader, etc.
};

pub const SpriteBatcher = struct {
    allocator: std.mem.Allocator,
    config: SpriteBatcherConfig,

    vertices: std.ArrayList(SpriteVertex), // CPU-side buffer for vertex data
    // indices: std.ArrayList(u32), // CPU-side buffer for index data (if needed, often can be calculated)

    vbo: GLBuffer, // Vertex Buffer Object
    // ibo: ?GLBuffer = null, // Index Buffer Object (optional, can draw quads directly)
    vao: u32 = 0, // Vertex Array Object (OpenGL specific)

    shader: ?*GLShader = null, // Shader used for rendering this batch
    current_texture: ?*GLTexture = null, // Current texture being batched (for single texture batching)

    // For multi-texture batching (more advanced)
    // texture_slots: [MAX_TEXTURE_SLOTS]u32,
    // texture_count: usize = 0,

    draw_calls: usize = 0,
    sprite_count_in_batch: usize = 0,

    // Matrices
    projection_matrix: Mat4,
    view_matrix: Mat4,

    is_active: bool = false, // If begin() has been called

    pub fn init(allocator_param: std.mem.Allocator, config_param: SpriteBatcherConfig, initial_shader: ?*GLShader) !SpriteBatcher {
        std.log.debug("Initializing SpriteBatcher with max_sprites: {d}", .{config_param.max_sprites});
        var self = SpriteBatcher{
            .allocator = allocator_param,
            .config = config_param,
            .vertices = std.ArrayList(SpriteVertex).init(allocator_param),
            // .indices = std.ArrayList(u32).init(allocator_param),
            .projection_matrix = Mat4.identity(), // Should be set by camera/renderer
            .view_matrix = Mat4.identity(),       // Should be set by camera
            .shader = initial_shader,
            // Temp VBO - this needs proper GL init
            .vbo = undefined, // This will be replaced by actual GLBuffer creation
        };

        // Pre-allocate vertex buffer on CPU side
        try self.vertices.ensureTotalCapacity(config_param.max_sprites * 4); // 4 vertices per sprite

        // Create GPU buffers (VBO, VAO, potentially IBO)
        // This requires an active GL context.
        // For now, this is a placeholder. Real init would call GL functions.
        const max_vertex_buffer_size = config_param.max_sprites * 4 * @sizeOf(SpriteVertex);
        self.vbo = try GLBuffer.create(.Vertex, max_vertex_buffer_size, null, .DynamicDraw);

        // setupVAO(&self); // Placeholder for VAO setup

        return self;
    }

    pub fn deinit(self: *SpriteBatcher) void {
        std.log.debug("Deinitializing SpriteBatcher. Draw calls: {d}", .{self.draw_calls});
        self.vertices.deinit();
        // self.indices.deinit();

        self.vbo.destroy();
        // if (self.ibo) |ibo| ibo.destroy();
        // if (self.vao != 0) gl.deleteVertexArrays(1, &self.vao);

        // Shader and texture are not owned by the batcher, so not deinitialized here.
    }

    // fn setupVAO(self: *SpriteBatcher) void {
        // gl.genVertexArrays(1, &self.vao);
        // gl.bindVertexArray(self.vao);
        // self.vbo.bind();
        // Define vertex attributes for SpriteVertex
        // Position
        // gl.enableVertexAttribArray(0);
        // gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, @sizeOf(SpriteVertex), @ptrFromInt(0));
        // Color
        // gl.enableVertexAttribArray(1);
        // gl.vertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, @sizeOf(SpriteVertex), @ptrFromInt(@offsetOf(SpriteVertex, "color")));
        // TexCoords
        // gl.enableVertexAttribArray(2);
        // gl.vertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, @sizeOf(SpriteVertex), @ptrFromInt(@offsetOf(SpriteVertex, "tex_coords")));
        // gl.bindVertexArray(0); // Unbind VAO
    // }

    pub fn begin(self: *SpriteBatcher, proj_matrix: Mat4, view_matrix: Mat4) void {
        if (self.is_active) {
            std.log.warn("SpriteBatcher.begin() called while already active. Did you forget to call end()?", .{});
            // Optionally, could call end() here or return an error.
            // For now, let's reset and continue.
            // self.end(); // This might not be what user expects.
        }
        // std.log.debug("SpriteBatcher.begin()", .{});

        self.projection_matrix = proj_matrix;
        self.view_matrix = view_matrix;
        self.is_active = true;
        self.sprite_count_in_batch = 0;
        self.draw_calls = 0;
        self.vertices.shrinkRetainingCapacity(0); // Clear CPU buffer
        self.current_texture = null; // Reset current texture
    }

    pub fn end(self: *SpriteBatcher) void {
        if (!self.is_active) {
            std.log.warn("SpriteBatcher.end() called while not active.", .{});
            return;
        }
        // std.log.debug("SpriteBatcher.end()", .{});
        if (self.sprite_count_in_batch > 0) {
            self.flush();
        }
        self.is_active = false;
    }

    pub fn draw(self: *SpriteBatcher, sprite: *const Sprite) !void {
        if (!self.is_active) {
            std.log.err("SpriteBatcher.draw() called outside of begin/end block.", .{});
            return error.BatcherNotActive;
        }
        if (sprite.texture == null) {
            std.log.warn("Attempting to draw sprite with null texture.", .{});
            return; // Or draw a colored quad if no texture
        }

        // Check if batch needs to be flushed due to sprite count or texture change
        if (self.sprite_count_in_batch >= self.config.max_sprites or
            (self.current_texture != null and sprite.texture != self.current_texture and self.sprite_count_in_batch > 0))
        {
            self.flush();
        }

        // Set current texture for this batch if it's the first sprite or texture changed
        if (self.current_texture == null or (self.current_texture != sprite.texture)) {
            // If it's not the very first sprite in an empty batch, and texture changed, flush previous.
            // This condition is subtly handled by the flush condition above.
            // If current_texture was null, this is the first texture.
            // If current_texture was different, the flush above would have occurred.
            self.current_texture = sprite.texture;
        }


        // Add sprite vertices to CPU buffer
        // This is a simplified version. A full version would calculate transformed vertices.
        // For now, assume sprite properties (position, size, rotation, color, tex_coords) are directly used.
        // Texture coordinates from sprite.texture_rect_pos and sprite.texture_rect_size
        // These need to be normalized if the texture is an atlas.
        // Assuming texture_rect gives pixel coords and texture has width/height.
        const tex = sprite.texture.?; // Known not null from check above
        const tex_w = @intToFloat(f32, tex.width);
        const tex_h = @intToFloat(f32, tex.height);

        // Normalized texture coordinates
        const u0 = sprite.texture_rect_pos.x / tex_w;
        const v0 = sprite.texture_rect_pos.y / tex_h;
        const u1 = (sprite.texture_rect_pos.x + sprite.texture_rect_size.x) / tex_w;
        const v1 = (sprite.texture_rect_pos.y + sprite.texture_rect_size.y) / tex_h;

        // Simple quad vertices (local space, centered if origin is 0.5, 0.5)
        // This doesn't apply rotation or global transform yet. That's usually done in shader or by transforming these points.
        // For a CPU-side transformation batcher:
        // Calculate model matrix for sprite
        // Transform quad corners by model matrix
        // Add to vertex buffer
        // For now, let's just use sprite.position and sprite.size directly for simplicity.
        // This means the shader will need to handle the model transform.
        // Or, the batcher sends raw quad data and a per-sprite transform matrix (instancing).
        // The current SpriteVertex implies CPU-side transformation.

        // Let's define quad corners (local, pre-transform)
        // Origin adjustment:
        const half_w = sprite.size.x * 0.5;
        const half_h = sprite.size.y * 0.5;
        const offset_x = sprite.size.x * (sprite.origin.x - 0.5);
        const offset_y = sprite.size.y * (sprite.origin.y - 0.5);

        // Local quad points, adjusted by origin, ready for rotation and translation
        var p1 = Vec2.new(-half_w - offset_x, -half_h - offset_y); // Bottom-left
        var p2 = Vec2.new( half_w - offset_x, -half_h - offset_y); // Bottom-right
        var p3 = Vec2.new( half_w - offset_x,  half_h - offset_y); // Top-right
        var p4 = Vec2.new(-half_w - offset_x,  half_h - offset_y); // Top-left

        // Apply rotation if any
        if (sprite.rotation != 0.0) {
            const cos_r = std.math.cos(sprite.rotation);
            const sin_r = std.math.sin(sprite.rotation);
            p1 = p1.rotate(cos_r, sin_r);
            p2 = p2.rotate(cos_r, sin_r);
            p3 = p3.rotate(cos_r, sin_r);
            p4 = p4.rotate(cos_r, sin_r);
        }

        // Apply translation (sprite's world position)
        // And add to vertices list
        try self.vertices.appendSlice(&[_]SpriteVertex{
            .{ .position = Vec3.new(p1.x + sprite.position.x, p1.y + sprite.position.y, 0), .color = sprite.color, .tex_coords = Vec2.new(u0, v1) }, // BL
            .{ .position = Vec3.new(p2.x + sprite.position.x, p2.y + sprite.position.y, 0), .color = sprite.color, .tex_coords = Vec2.new(u1, v1) }, // BR
            .{ .position = Vec3.new(p3.x + sprite.position.x, p3.y + sprite.position.y, 0), .color = sprite.color, .tex_coords = Vec2.new(u1, v0) }, // TR
            .{ .position = Vec3.new(p4.x + sprite.position.x, p4.y + sprite.position.y, 0), .color = sprite.color, .tex_coords = Vec2.new(u0, v0) }, // TL
        });
        // This forms two triangles: (BL, BR, TR) and (BL, TR, TL)
        // So indices would be 0,1,2, 0,2,3 relative to these 4 vertices.
        // If using glDrawArrays with GL_TRIANGLES, vertices must be ordered: BL, BR, TR, BL, TR, TL

        self.sprite_count_in_batch += 1;
    }

    pub fn flush(self: *SpriteBatcher) void {
        if (self.sprite_count_in_batch == 0 || self.vertices.items.len == 0) {
            return; // Nothing to flush
        }
        if (self.shader == null) {
            std.log.err("SpriteBatcher: Cannot flush, no shader set.", .{});
            return;
        }
        if (self.current_texture == null) {
            std.log.err("SpriteBatcher: Cannot flush, no texture set for the current batch.", .{});
            // This case should ideally be prevented by `draw` logic.
            return;
        }

        // std.log.debug("Flushing SpriteBatcher: {d} sprites, {d} vertices.", .{
        //     self.sprite_count_in_batch, self.vertices.items.len
        // });

        // self.shader.?.bind();
        // self.shader.?.setUniformMat4f("u_projectionMatrix", self.projection_matrix); // Assuming uniform names
        // self.shader.?.setUniformMat4f("u_viewMatrix", self.view_matrix);
        // self.current_texture.?.bind(0); // Bind texture to slot 0
        // self.shader.?.setUniform1i("u_textureSampler", 0); // Tell shader sampler is at slot 0

        // Update VBO with vertex data
        self.vbo.bind();
        // Use bufferSubData for existing buffer, or bufferData if re-specifying size (less common for dynamic batches)
        // try self.vbo.updateData(0, std.mem.sliceAsBytes(self.vertices.items));
        // Or, if size can change or it's first fill:
        try self.vbo.setData(std.mem.sliceAsBytes(self.vertices.items).len, std.mem.sliceAsBytes(self.vertices.items), .DynamicDraw);


        // Bind VAO
        // gl.bindVertexArray(self.vao);

        // Draw the batch
        // Assumes vertices are already ordered for GL_TRIANGLES (6 per quad)
        // Or if using IBO with 4 vertices per quad and GL_TRIANGLES, draw (sprites * 6) indices.
        // gl.drawArrays(gl.TRIANGLES, 0, @intCast(gl.GLsizei, self.vertices.items.len));
        // If using an IBO that's pre-filled for max_sprites:
        // gl.drawElements(gl.TRIANGLES, @intCast(gl.GLsizei, self.sprite_count_in_batch * 6), gl.UNSIGNED_INT, null);

        // gl.bindVertexArray(0); // Unbind VAO
        GLBuffer.unbind(.Vertex); // Unbind VBO
        // self.current_texture.?.unbind(0); // Unbind texture from slot 0 (optional, depends on renderer structure)
        // self.shader.?.unbind();

        self.draw_calls += 1;
        self.vertices.shrinkRetainingCapacity(0); // Clear CPU buffer for next batch
        self.sprite_count_in_batch = 0;
        // self.current_texture = null; // Texture for next batch is not yet known.
                                     // This is reset in draw() or if begin() is called.
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

    // pub fn genVertexArrays(n: i32, arrays: *GLuint) void { _=n; arrays.* = 1; }
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


test "SpriteBatcher initialization and basic lifecycle (mocked GL)" {
    const allocator = std.testing.allocator;
    const config = SpriteBatcherConfig{ .max_sprites = 10 };

    // Need a mock shader and texture for the batcher to operate, even with mocked GL.
    var mock_shader_storage: GLShader = .{ .program_id = 1, .allocator = allocator };
    var mock_texture_storage: GLTexture = .{ .texture_id = 1, .width = 32, .height = 32, .format = .RGBA };

    var batcher = try SpriteBatcher.init(allocator, config, &mock_shader_storage);
    defer batcher.deinit();

    try std.testing.expect(batcher.vertices.capacity() >= config.max_sprites * 4);
    try std.testing.expect(batcher.vbo.buffer_id != 0); // Check VBO was "created"

    const proj = Mat4.ortho(0, 800, 0, 600, -1, 1);
    const view = Mat4.identity();

    batcher.begin(proj, view);
    try std.testing.expect(batcher.is_active);

    // Create a dummy sprite to draw
    var sprite = Sprite.init(allocator, &mock_texture_storage, Vec2.new(10,10), Vec2.new(32,32));
    try batcher.draw(&sprite);
    try std.testing.expect(batcher.sprite_count_in_batch == 1);
    try std.testing.expect(batcher.vertices.items.len == 4); // 4 vertices for one quad

    batcher.end(); // This should call flush
    try std.testing.expect(!batcher.is_active);
    try std.testing.expect(batcher.draw_calls == 1); // One flush should have occurred

    std.log.info("SpriteBatcher test completed (using mocked GL calls).", .{});
}

test "SpriteBatcher flush conditions (mocked GL)" {
    const allocator = std.testing.allocator;
    const max_s = 2;
    const config = SpriteBatcherConfig{ .max_sprites = max_s }; // Max 2 sprites per batch

    var mock_shader: GLShader = .{ .program_id = 1, .allocator = allocator };
    var tex1: GLTexture = .{ .texture_id = 1, .width = 16, .height = 16, .format = .RGBA };
    var tex2: GLTexture = .{ .texture_id = 2, .width = 16, .height = 16, .format = .RGBA };

    var batcher = try SpriteBatcher.init(allocator, config, &mock_shader);
    defer batcher.deinit();

    batcher.begin(Mat4.identity(), Mat4.identity());

    var s1 = Sprite.init(allocator, &tex1, Vec2.zero(), Vec2.new(10,10));
    var s2 = Sprite.init(allocator, &tex1, Vec2.zero(), Vec2.new(10,10));
    var s3 = Sprite.init(allocator, &tex1, Vec2.zero(), Vec2.new(10,10)); // Exceeds max_sprites
    var s4_tex_change = Sprite.init(allocator, &tex2, Vec2.zero(), Vec2.new(10,10)); // Different texture

    // Draw 1: s1 (tex1)
    try batcher.draw(&s1);
    try std.testing.expectEqual(@as(usize, 1), batcher.sprite_count_in_batch);
    try std.testing.expectEqual(@as(usize, 0), batcher.draw_calls);

    // Draw 2: s2 (tex1) - batch not full yet (max_s = 2)
    try batcher.draw(&s2);
    try std.testing.expectEqual(@as(usize, 2), batcher.sprite_count_in_batch);
    try std.testing.expectEqual(@as(usize, 0), batcher.draw_calls);

    // Draw 3: s3 (tex1) - exceeds max_sprites, should flush s1 and s2
    try batcher.draw(&s3);
    try std.testing.expectEqual(@as(usize, 1), batcher.sprite_count_in_batch); // s3 is now in the new batch
    try std.testing.expectEqual(@as(usize, 1), batcher.draw_calls); // s1, s2 flushed

    // Draw 4: s4_tex_change (tex2) - different texture, should flush s3
    try batcher.draw(&s4_tex_change);
    try std.testing.expectEqual(@as(usize, 1), batcher.sprite_count_in_batch); // s4 is now in the new batch
    try std.testing.expectEqual(@as(usize, 2), batcher.draw_calls); // s3 flushed

    batcher.end(); // Flushes the last sprite (s4)
    try std.testing.expectEqual(@as(usize, 3), batcher.draw_calls);
}
