// src/graphics/color.zig
// Defines a color structure and common color constants.

const std = @import("std");

pub const Color = extern struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    pub const Black = Color{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 };
    pub const White = Color{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 };
    pub const Red = Color{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 };
    pub const Green = Color{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 };
    pub const Blue = Color{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 };
    pub const Transparent = Color{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 0.0 };

    // Grayscale
    pub const Gray = Color{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 1.0 };
    pub const LightGray = Color{ .r = 0.75, .g = 0.75, .b = 0.75, .a = 1.0 };
    pub const DarkGray = Color{ .r = 0.25, .g = 0.25, .b = 0.25, .a = 1.0 };
    pub const DarkSlateGray = Color{ .r = 0.184, .g = 0.310, .b = 0.310, .a = 1.0 }; // From X11 color names

    // Other common colors
    pub const Yellow = Color{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 };
    pub const Cyan = Color{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 };
    pub const Magenta = Color{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 };
    pub const Orange = Color{ .r = 1.0, .g = 0.647, .b = 0.0, .a = 1.0 };
    pub const Purple = Color{ .r = 0.5, .g = 0.0, .b = 0.5, .a = 1.0 };
    pub const Brown = Color{ .r = 0.647, .g = 0.165, .b = 0.165, .a = 1.0 };
    pub const Pink = Color{ .r = 1.0, .g = 0.753, .b = 0.796, .a = 1.0 };
    pub const Lime = Color{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }; // Same as Green by this definition
    pub const Teal = Color{ .r = 0.0, .g = 0.502, .b = 0.502, .a = 1.0 };
    pub const Olive = Color{ .r = 0.502, .g = 0.502, .b = 0.0, .a = 1.0 };
    pub const Maroon = Color{ .r = 0.502, .g = 0.0, .b = 0.0, .a = 1.0 };
    pub const Navy = Color{ .r = 0.0, .g = 0.0, .b = 0.502, .a = 1.0 };
    pub const LightBlue = Color{ .r = 0.678, .g = 0.847, .b = 0.902, .a = 1.0 }; // X11 LightBlue
    pub const LightCyan = Color{ .r = 0.878, .g = 1.0, .b = 1.0, .a = 1.0 }; // X11 LightCyan


    pub fn new(r_param: f32, g_param: f32, b_param: f32, a_param: f32) Color {
        return Color{ .r = r_param, .g = g_param, .b = b_param, .a = a_param };
    }

    pub fn fromRGBA(rgba: u32) Color {
        return Color{
            .r = @intToFloat(f32, (rgba >> 24) & 0xFF) / 255.0,
            .g = @intToFloat(f32, (rgba >> 16) & 0xFF) / 255.0,
            .b = @intToFloat(f32, (rgba >> 8) & 0xFF) / 255.0,
            .a = @intToFloat(f32, (rgba >> 0) & 0xFF) / 255.0,
        };
    }

    pub fn toRGBA(self: Color) u32 {
        const r_u8 = @floatToInt(u8, std.math.clamp(self.r * 255.0, 0.0, 255.0));
        const g_u8 = @floatToInt(u8, std.math.clamp(self.g * 255.0, 0.0, 255.0));
        const b_u8 = @floatToInt(u8, std.math.clamp(self.b * 255.0, 0.0, 255.0));
        const a_u8 = @floatToInt(u8, std.math.clamp(self.a * 255.0, 0.0, 255.0));
        return (@as(u32, r_u8) << 24) |
               (@as(u32, g_u8) << 16) |
               (@as(u32, b_u8) << 8) |
               (@as(u32, a_u8) << 0);
    }

    pub fn eql(self: Color, other: Color) bool {
        const epsilon = 0.0001; // Epsilon for float comparisons
        return std.math.approxEqAbs(self.r, other.r, epsilon) and
               std.math.approxEqAbs(self.g, other.g, epsilon) and
               std.math.approxEqAbs(self.b, other.b, epsilon) and
               std.math.approxEqAbs(self.a, other.a, epsilon);
    }
};

test "Color struct and functions" {
    const color1 = Color.new(0.1, 0.2, 0.3, 0.4);
    try std.testing.expect(color1.r == 0.1); // Direct for assignment
    try std.testing.expect(color1.g == 0.2);
    try std.testing.expect(color1.b == 0.3);
    try std.testing.expect(color1.a == 0.4);

    const color_rgba: u32 = 0x1A2B3C4D; // R=0x1A(26), G=0x2B(43), B=0x3C(60), A=0x4D(77)
    const color_from_rgba = Color.fromRGBA(color_rgba);

    const epsilon = 0.001;
    try std.testing.expect(std.math.approxEqAbs(color_from_rgba.r, 26.0 / 255.0, epsilon));
    try std.testing.expect(std.math.approxEqAbs(color_from_rgba.g, 43.0 / 255.0, epsilon));
    try std.testing.expect(std.math.approxEqAbs(color_from_rgba.b, 60.0 / 255.0, epsilon));
    try std.testing.expect(std.math.approxEqAbs(color_from_rgba.a, 77.0 / 255.0, epsilon));

    const converted_rgba = color_from_rgba.toRGBA();
    try std.testing.expectEqual(color_rgba, converted_rgba);

    // Test predefined colors (check one component for brevity)
    try std.testing.expect(Color.Red.r == 1.0 and Color.Red.g == 0.0);
    try std.testing.expect(Color.Green.g == 1.0);
    try std.testing.expect(Color.Blue.b == 1.0);
    try std.testing.expect(Color.White.r == 1.0 and Color.White.g == 1.0 and Color.White.b == 1.0);
    try std.testing.expect(Color.Black.r == 0.0 and Color.Black.g == 0.0 and Color.Black.b == 0.0);
    try std.testing.expect(Color.Transparent.a == 0.0);
    try std.testing.expect(Color.Gray.r == 0.5);
    try std.testing.expect(Color.LightGray.r == 0.75);
    try std.testing.expect(Color.DarkSlateGray.g == 0.310);

    // Test eql method
    const c_a = Color.new(0.1, 0.2, 0.3, 0.4);
    const c_b = Color.new(0.1, 0.200001, 0.3, 0.399999); // Slightly different, should be equal with epsilon
    const c_c = Color.new(0.1, 0.25, 0.3, 0.4); // Different enough

    try std.testing.expect(c_a.eql(c_b));
    try std.testing.expect(!c_a.eql(c_c));
    try std.testing.expect(Color.Red.eql(Color.new(1.0,0.0,0.0,1.0)));
}
