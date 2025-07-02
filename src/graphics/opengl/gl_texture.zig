// src/graphics/opengl/gl_texture.zig
// OpenGL texture management.

const std = @import("std");
const gl = @import("zopengl"); // Assuming zopengl or similar GL bindings
const Color = @import("../color.zig").Color; // For default texture color

pub const TextureError = error{
    CreationFailed,
    InvalidFormat,
    InvalidDimensions,
    ImmutableStorageAlreadyAllocated,
    AllocationFailed,
};

// TextureFormat enum might be more extensive
pub const TextureFormat = enum {
    RGB,
    RGBA,
    Depth,
    // Add more formats as needed (e.g., R8, RGBA16F, etc.)

    pub fn toGL(self: TextureFormat) gl.GLenum {
        return switch (self) {
            .RGB => 0, // gl.RGB,
            .RGBA => 1, // gl.RGBA,
            .Depth => 2, // gl.DEPTH_COMPONENT,
        };
    }
    pub fn toGLInternal(self: TextureFormat) gl.GLenum {
        return switch (self) {
            .RGB => 0, // gl.RGB8,
            .RGBA => 1, // gl.RGBA8,
            .Depth => 2, // gl.DEPTH_COMPONENT24,
        };
    }
};

pub const GLTexture = struct {
    texture_id: gl.GLuint,
    width: u32,
    height: u32,
    format: TextureFormat,
    // mipmap_levels: u32 = 1,
    // is_immutable: bool = false,

    // allocator: std.mem.Allocator, // If needed for internal data

    // Creates a 2D texture.
    // Data can be null to create an empty texture (e.g., for framebuffer attachments).
    pub fn create2D(
        // allocator_param: std.mem.Allocator,
        width_param: u32,
        height_param: u32,
        format_param: TextureFormat,
        data: ?[]const u8,
    ) !GLTexture {
        if (width_param == 0 or height_param == 0) {
            return TextureError.InvalidDimensions;
        }
        std.log.debug("Creating GLTexture2D: {d}x{d}, format: {any}", .{width_param, height_param, format_param});

        // var tex_id: gl.GLuint = 0;
        // gl.genTextures(1, &tex_id);
        // if (tex_id == 0) return TextureError.CreationFailed;
        const tex_id_placeholder: gl.GLuint = 1; // Placeholder

        // gl.bindTexture(gl.TEXTURE_2D, tex_id);

        // Set texture parameters (can be customized)
        // gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        // gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        // gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
        // gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

        // const gl_internal_format = format_param.toGLInternal();
        // const gl_format = format_param.toGL();
        // const data_ptr = if (data) |d| d.ptr else null;

        // gl.texImage2D(
        //     gl.TEXTURE_2D,
        //     0, // level
        //     @intCast(gl.GLint, gl_internal_format),
        //     @intCast(gl.GLsizei, width_param),
        //     @intCast(gl.GLsizei, height_param),
        //     0, // border
        //     gl_format,
        //     gl.UNSIGNED_BYTE, // Assuming 8-bit per channel for RGB/RGBA for now
        //     data_ptr
        // );

        // gl.generateMipmap(gl.TEXTURE_2D); // Generate mipmaps

        // gl.bindTexture(gl.TEXTURE_2D, 0); // Unbind

        return GLTexture{
            .texture_id = tex_id_placeholder, // tex_id,
            .width = width_param,
            .height = height_param,
            .format = format_param,
            // .allocator = allocator_param,
        };
    }

    // Creates a 1x1 white texture as a default/fallback
    pub fn createDefault(allocator: std.mem.Allocator) !GLTexture {
        _ = allocator;
        const default_pixel_data: [4]u8 = .{ 255, 255, 255, 255 }; // White
        return try GLTexture.create2D(1, 1, .RGBA, &default_pixel_data);
    }

    pub fn destroy(self: *GLTexture) void {
        std.log.debug("Destroying GLTexture (ID: {d})", .{self.texture_id});
        // gl.deleteTextures(1, &self.texture_id);
        self.texture_id = 0;
    }

    pub fn bind(self: *const GLTexture, slot: u32) void {
        // gl.activeTexture(gl.TEXTURE0 + slot);
        // gl.bindTexture(gl.TEXTURE_2D, self.texture_id);
        std.log.debug("Binding GLTexture (ID: {d}) to slot {d}", .{self.texture_id, slot});
    }

    pub fn unbind(slot: u32) void {
        // gl.activeTexture(gl.TEXTURE0 + slot);
        // gl.bindTexture(gl.TEXTURE_2D, 0);
        std.log.debug("Unbinding texture from slot {d}", .{slot});
    }

    // pub fn updateData(self: *const GLTexture, x_offset: u32, y_offset: u32, width: u32, height: u32, data: []const u8) !void {
    //     if (x_offset + width > self.width or y_offset + height > self.height) {
    //         return TextureError.InvalidDimensions;
    //     }
    //     if (self.is_immutable) {
    //         std.log.warn("Attempted to update immutable texture (ID: {d})", .{self.texture_id});
    //         // return TextureError.ImmutableStorageAlreadyAllocated; // Or just ignore
    //         return;
    //     }

    //     gl.bindTexture(gl.TEXTURE_2D, self.texture_id);
    //     gl.texSubImage2D(
    //         gl.TEXTURE_2D,
    //         0, // level
    //         @intCast(gl.GLint, x_offset),
    //         @intCast(gl.GLint, y_offset),
    //         @intCast(gl.GLsizei, width),
    //         @intCast(gl.GLsizei, height),
    //         self.format.toGL(),
    //         gl.UNSIGNED_BYTE, // Assuming u8 data
    //         data.ptr
    //     );
    //     // gl.bindTexture(gl.TEXTURE_2D, 0); // Unbind if necessary, often not done mid-operations
    // }
};

// Dummy GL bindings for compilation if zopengl is not fully set up.
const gl = struct {
    const _GLuint = u32;
    const _GLenum = u32;
    // pub const TEXTURE_2D: GLenum = 0x0DE1;
    // pub const TEXTURE_WRAP_S: GLenum = 0x2802;
    // pub const TEXTURE_WRAP_T: GLenum = 0x2803;
    // pub const TEXTURE_MIN_FILTER: GLenum = 0x2801;
    // pub const TEXTURE_MAG_FILTER: GLenum = 0x2800;
    // pub const REPEAT: GLenum = 0x2901;
    // pub const LINEAR_MIPMAP_LINEAR: GLenum = 0x2703;
    // pub const LINEAR: GLenum = 0x2601;
    // pub const RGBA: GLenum = 0x1908;
    // pub const RGBA8: GLenum = 0x8058;
    // pub const UNSIGNED_BYTE: GLenum = 0x1401;
    // pub const TEXTURE0: GLenum = 0x84C0;

    // pub fn genTextures(n: i32, textures: *GLuint) void { _=n; textures.* = 1; } // Mock creation
    // pub fn deleteTextures(n: i32, textures: *const GLuint) void { _=n; _=textures; }
    // pub fn bindTexture(target: GLenum, texture: GLuint) void { _=target; _=texture; }
    // pub fn texParameteri(target: GLenum, pname: GLenum, param: i32) void { _=target; _=pname; _=param; }
    // pub fn texImage2D(target: GLenum, level: i32, internalformat: i32, width: i32, height: i32, border: i32, format: GLenum, type: GLenum, pixels: ?[*]const u8) void {
    //     _=target; _=level; _=internalformat; _=width; _=height; _=border; _=format; _=type; _=pixels;
    // }
    // pub fn generateMipmap(target: GLenum) void { _=target; }
    // pub fn activeTexture(texture: GLenum) void { _=texture; }
    // pub fn texSubImage2D(target: GLenum, level: i32, xoffset: i32, yoffset: i32, width: i32, height: i32, format: GLenum, type: GLenum, pixels: [*]const u8) void {
    //    _=target; _=level; _=xoffset; _=yoffset; _=width; _=height; _=format; _=type; _=pixels;
    //}
    pub const GLuint = u32;
    pub const GLenum = u32;
    pub const GLint = i32;
    pub const GLsizei = i32;

};

test "GLTexture creation and destruction (mocked GL)" {
    const allocator = std.testing.allocator;

    // Test default texture creation
    var default_tex = try GLTexture.createDefault(allocator);
    defer default_tex.destroy();
    try std.testing.expect(default_tex.texture_id != 0);
    try std.testing.expect(default_tex.width == 1);
    try std.testing.expect(default_tex.height == 1);
    try std.testing.expect(default_tex.format == .RGBA);

    // Test custom texture creation
    const width: u32 = 64;
    const height: u32 = 32;
    const pixel_data_len = width * height * 4; // RGBA
    var pixel_data = try allocator.alloc(u8, pixel_data_len);
    defer allocator.free(pixel_data);
    // Fill with some pattern (e.g., blue)
    for (pixel_data) |*p, i| {
        const ch = i % 4;
        if (ch == 0) p.* = 0;   // R
        else if (ch == 1) p.* = 0;   // G
        else if (ch == 2) p.* = 255; // B
        else p.* = 255; // A
    }

    var custom_tex = try GLTexture.create2D(width, height, .RGBA, pixel_data);
    defer custom_tex.destroy();
    try std.testing.expect(custom_tex.texture_id != 0);
    try std.testing.expect(custom_tex.width == width);
    try std.testing.expect(custom_tex.height == height);

    custom_tex.bind(0);
    GLTexture.unbind(0);

    std.log.info("GLTexture test completed (using mocked GL calls).", .{});
}

test "TextureFormat toGL" {
    // These would test actual GLenum values if gl constants were fully defined
    _ = TextureFormat.RGB.toGL();
    _ = TextureFormat.RGBA.toGLInternal();
    try std.testing.expect(true); // Placeholder
}
