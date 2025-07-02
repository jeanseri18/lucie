// src/ui/canvas.zig
// Canvas for rendering UI elements. This might wrap a 2D graphics library or GPU texture.

const std = @import("std");
const Color = @import("../graphics/color.zig").Color; // Assuming graphics color
const Vec2 = @import("../math/vec2.zig").Vec2;
// const FontHandle = u32; // Placeholder for font resource handle

// For this placeholder, Canvas is conceptual.
// A real Canvas would interact with a renderer (e.g., OpenGL, Vulkan)
// to draw primitives or manage a render target texture.
// It might use a library like `zig-cairo` for CPU-based 2D rendering,
// or a GPU-accelerated 2D renderer.

pub const Canvas = struct {
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,

    // If GPU-backed, this might be a handle to a framebuffer or texture
    // gpu_texture_handle: ?u32 = null,
    // pixel_data_buffer: ?[]u8 = null, // For CPU-backed canvas

    // Drawing state (simplified)
    // current_color: Color = Color.White,
    // current_font: ?FontHandle = null,
    // current_transform: Mat3 = Mat3.identity(), // For transformed drawing

    pub fn init(allocator_param: std.mem.Allocator, w: u32, h: u32) !Canvas {
        std.log.debug("Initializing Canvas: {d}x{d}", .{w, h});
        if (w == 0 or h == 0) return error.InvalidDimensions;

        // If CPU-backed, allocate pixel buffer:
        // const buffer_size = w * h * 4; // Assuming RGBA8
        // var buffer = try allocator_param.alloc(u8, buffer_size);
        // @memset(buffer, 0); // Clear to black or some default

        // If GPU-backed, create texture/render target here via graphics API.

        return Canvas{
            .allocator = allocator_param,
            .width = w,
            .height = h,
            // .pixel_data_buffer = buffer, // If CPU backed
        };
    }

    pub fn deinit(self: *Canvas) void {
        std.log.debug("Deinitializing Canvas.", .{});
        // if (self.pixel_data_buffer) |buf| {
        //     self.allocator.free(buf);
        //     self.pixel_data_buffer = null;
        // }
        // If GPU-backed, release texture/render target.
        _ = self; // Mark as used if no fields to deinit for placeholder
    }

    pub fn getWidth(self: *const Canvas) u32 { return self.width; }
    pub fn getHeight(self: *const Canvas) u32 { return self.height; }
    // pub fn getBounds(self: *const Canvas) Rect { return Rect{ .pos = Vec2.zero(), .size = Vec2.new(@intToFloat(f32, self.width), @intToFloat(f32, self.height))}; }


    // --- Drawing Primitives (Placeholders) ---
    // These would interact with the underlying rendering mechanism.

    pub fn clear(self: *Canvas, clear_color: ?Color) void {
        _ = self;
        const c = clear_color orelse Color.Transparent; // Default clear to transparent black
        std.log.debug("Canvas: Clearing with color R:{d:.2} G:{d:.2} B:{d:.2} A:{d:.2} (mock)", .{c.r, c.g, c.b, c.a});
        // If CPU buffer: @memset(self.pixel_data_buffer.?, some_value_from_color);
        // If GPU: glClearColor(...); glClear(...);
    }

    pub fn drawRect(self: *Canvas, x: f32, y: f32, w: f32, h: f32, color: Color, filled: bool) void {
        _ = self; _=filled; // Mark as used
        std.log.debug("Canvas: DrawRect at ({d:.1},{d:.1}) size ({d:.1},{d:.1}), Color R:{d:.2} (mock)", .{x,y,w,h,color.r});
        // Actual drawing logic here
    }

    // pub fn drawLine(self: *Canvas, start: Vec2, end: Vec2, color: Color, thickness: f32) void {
    //     _ = self; _=start; _=end; _=color; _=thickness;
    //     std.log.debug("Canvas: DrawLine (mock)", .{});
    // }

    // pub fn drawCircle(self: *Canvas, center: Vec2, radius: f32, color: Color, filled: bool) void {
    //     _ = self; _=center; _=radius; _=color; _=filled;
    //     std.log.debug("Canvas: DrawCircle (mock)", .{});
    // }

    pub fn drawText(
        self: *Canvas,
        text: []const u8,
        pos: Vec2,
        // font: FontHandle, // Handle to a loaded font
        size_px: f32, // Font size in pixels
        color: Color,
    ) void {
        _ = self; _=size_px; // Mark as used
        std.log.debug("Canvas: DrawText '{s}' at ({d:.1},{d:.1}), Color R:{d:.2} (mock)", .{text, pos.x, pos.y, color.r});
        // Text rendering is complex: requires font loading, glyph rasterization (e.g. freetype, stb_truetype),
        // and drawing glyphs (textured quads) to the canvas.
    }

    // pub fn drawTexture(
    //     self: *Canvas,
    //     texture_handle: u32, // Some TextureHandle type
    //     pos: Vec2,
    //     size: ?Vec2, // Optional size, if null use texture's native size
    //     source_rect: ?Rect, // Optional sub-rectangle of the texture
    //     tint: Color = Color.White,
    // ) void {
    //     _ = self; _=texture_handle; _=pos; _=size; _=source_rect; _=tint;
    //     std.log.debug("Canvas: DrawTexture (mock)", .{});
    // }


    // If GPU-backed, this provides the texture handle for rendering.
    // pub fn getTextureHandle(self: *const Canvas) ?u32 /* TextureHandle */ {
    //     return self.gpu_texture_handle;
    // }

    // If CPU-backed, this provides access to raw pixel data.
    // pub fn getPixelData(self: *const Canvas) ?[]const u8 {
    //     return self.pixel_data_buffer;
    // }
    // pub fn getMutablePixelData(self: *Canvas) ?[]u8 {
    //     return self.pixel_data_buffer;
    // }
};

test "Canvas initialization and properties" {
    const allocator = std.testing.allocator;
    const w: u32 = 100;
    const h: u32 = 200;

    var canvas = try Canvas.init(allocator, w, h);
    defer canvas.deinit();

    try std.testing.expect(canvas.width == w);
    try std.testing.expect(canvas.height == h);
    // if (canvas.pixel_data_buffer) |buf| { // If CPU backed and buffer allocated
    //     try std.testing.expect(buf.len == w * h * 4);
    // }

    // Test invalid dimensions
    const bad_canvas = Canvas.init(allocator, 0, 100);
    try std.testing.expectError(error.InvalidDimensions, bad_canvas);

    std.log.info("Canvas initialization test completed.", .{});
}

test "Canvas drawing command placeholders" {
    const allocator = std.testing.allocator;
    var canvas = try Canvas.init(allocator, 800, 600);
    defer canvas.deinit();

    // These calls just log for now, testing they don't crash.
    canvas.clear(Color.Black);
    canvas.drawRect(10, 10, 50, 30, Color.Red, true);
    canvas.drawText("Hello UI", Vec2.new(100,100), 16.0, Color.White);

    // No actual output to verify in this placeholder test.
    try std.testing.expect(true);
    std.log.info("Canvas drawing command placeholder test completed.", .{});
}
