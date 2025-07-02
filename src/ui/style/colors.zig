// src/ui/style/colors.zig
// Common color definitions and palettes for UI styling.
// This file might seem redundant with `src/graphics/color.zig` if that file
// already contains an extensive list of colors.
//
// The purpose of this specific `ui/style/colors.zig` could be:
// 1. To define UI-specific color names or palettes that are derived from base graphics colors.
//    (e.g., `panel_background`, `button_text_hover` which map to specific Color values).
// 2. If `graphics/color.zig` is minimal, this file could be the primary place for named colors.
// 3. To provide functions for color manipulation specific to UI theming (e.g., lighten, darken, blend).

const std = @import("std");
const BaseColor = @import("../../graphics/color.zig").Color; // Import the base Color struct

// Re-export the base Color type for convenience if this module is the primary access point for UI colors.
pub const Color = BaseColor;

// --- UI Semantic Color Names / Palette ---
// These colors are defined using the BaseColor struct.
// They provide names that are meaningful in a UI context.
// This can help in abstracting specific color values from theme definitions.

pub const UIColor = struct {
    // Example semantic colors:
    pub const Text = Color.Black;
    pub const TextDisabled = Color.Gray;
    pub const TextLink = Color.Blue;
    pub const TextLinkHover = Color.new(0.2, 0.2, 1.0, 1.0); // Darker blue

    pub const BackgroundPrimary = Color.White;         // Main content background
    pub const BackgroundSecondary = Color.LightGray;   // Slightly off-main background
    pub const BackgroundTertiary = Color.new(0.95, 0.95, 0.95, 1.0); // Even lighter gray, e.g., for cards

    pub const AccentPrimary = Color.Blue;
    pub const AccentSecondary = Color.Cyan;

    pub const BorderNormal = Color.DarkGray;
    pub const BorderFocus = Color.Blue;
    pub const BorderError = Color.Red;

    pub const Success = Color.Green;
    pub const Warning = Color.Orange; // Assuming Orange is defined in BaseColor
    pub const Error = Color.Red;
    pub const Info = Color.Blue;

    // Specific component colors (could also be part of Theme)
    pub const ButtonBackground = Color.LightGray;
    pub const ButtonText = Color.Black;
    pub const ButtonHoverBackground = Color.Gray;
    pub const ButtonPressedBackground = Color.DarkSlateGray; // Assuming in BaseColor

    pub const PanelBackground = Color.new(0.2, 0.2, 0.25, 0.9); // Darkish panel

    // ... and so on for other UI elements or states.
};


// --- Color Manipulation Utilities (Optional) ---

// Lighten a color by a percentage (0.0 to 1.0)
pub fn lighten(color: Color, amount: f32) Color {
    const clamped_amount = std.math.clamp(amount, 0.0, 1.0);
    return Color.new(
        std.math.min(1.0, color.r + (1.0 - color.r) * clamped_amount),
        std.math.min(1.0, color.g + (1.0 - color.g) * clamped_amount),
        std.math.min(1.0, color.b + (1.0 - color.b) * clamped_amount),
        color.a, // Alpha usually unchanged by lighten/darken
    );
}

// Darken a color by a percentage (0.0 to 1.0)
pub fn darken(color: Color, amount: f32) Color {
    const clamped_amount = std.math.clamp(amount, 0.0, 1.0);
    return Color.new(
        color.r * (1.0 - clamped_amount),
        color.g * (1.0 - clamped_amount),
        color.b * (1.0 - clamped_amount),
        color.a,
    );
}

// Alpha blend two colors (c_over on top of c_base)
// Formula: Cout = Alpha_over * C_over + (1 - Alpha_over) * C_base
// Alpha_out = Alpha_over + Alpha_base * (1 - Alpha_over)
pub fn blendAlpha(c_over: Color, c_base: Color) Color {
    if (c_over.a >= 0.9999) return c_over; // If top color is opaque, it fully covers
    if (c_over.a <= 0.0001) return c_base; // If top color is transparent, base shows through

    const out_a = c_over.a + c_base.a * (1.0 - c_over.a);
    if (out_a <= 0.0001) return Color.Transparent; // Result is fully transparent

    const out_r = (c_over.r * c_over.a + c_base.r * c_base.a * (1.0 - c_over.a)) / out_a;
    const out_g = (c_over.g * c_over.a + c_base.g * c_base.a * (1.0 - c_over.a)) / out_a;
    const out_b = (c_over.b * c_over.a + c_base.b * c_base.a * (1.0 - c_over.a)) / out_a;

    return Color.new(out_r, out_g, out_b, out_a);
}


test "UIColor semantic color definitions" {
    // This test mainly checks if the color constants compile and have expected base values.
    // It relies on `graphics/color.zig` having the base colors (Black, Gray, Blue, etc.)
    // and the `eql` method for comparison.

    try std.testing.expect(UIColor.Text.eql(Color.Black));
    try std.testing.expect(UIColor.BorderNormal.eql(Color.DarkGray));
    try std.testing.expect(UIColor.AccentPrimary.eql(Color.Blue));
    try std.testing.expect(UIColor.ButtonBackground.eql(Color.LightGray));

    const link_hover_expected = Color.new(0.2, 0.2, 1.0, 1.0);
    try std.testing.expect(UIColor.TextLinkHover.eql(link_hover_expected));

    std.log.info("UIColor semantic color definitions test completed.", .{});
}

test "Color manipulation utilities" {
    // Test lighten
    const original_dark = Color.new(0.2, 0.3, 0.4, 1.0);
    const lightened = lighten(original_dark, 0.5); // Lighten by 50%
    // Expected: r = 0.2 + (1-0.2)*0.5 = 0.2 + 0.8*0.5 = 0.2 + 0.4 = 0.6
    //           g = 0.3 + (1-0.3)*0.5 = 0.3 + 0.7*0.5 = 0.3 + 0.35 = 0.65
    //           b = 0.4 + (1-0.4)*0.5 = 0.4 + 0.6*0.5 = 0.4 + 0.3 = 0.7
    try std.testing.expect(lightened.eql(Color.new(0.6, 0.65, 0.7, 1.0)));
    try std.testing.expect(lighten(Color.Black, 1.0).eql(Color.White)); // Lighten black by 100% -> white
    try std.testing.expect(lighten(Color.White, 0.5).eql(Color.White)); // Lighten white -> still white

    // Test darken
    const original_light = Color.new(0.8, 0.7, 0.6, 1.0);
    const darkened = darken(original_light, 0.5); // Darken by 50%
    // Expected: r = 0.8 * (1-0.5) = 0.8 * 0.5 = 0.4
    //           g = 0.7 * 0.5 = 0.35
    //           b = 0.6 * 0.5 = 0.3
    try std.testing.expect(darkened.eql(Color.new(0.4, 0.35, 0.3, 1.0)));
    try std.testing.expect(darken(Color.White, 1.0).eql(Color.Black)); // Darken white by 100% -> black
    try std.testing.expect(darken(Color.Black, 0.5).eql(Color.Black)); // Darken black -> still black

    // Test blendAlpha
    const semi_transparent_red = Color.new(1.0, 0.0, 0.0, 0.5); // 50% opaque red
    const opaque_blue = Color.new(0.0, 0.0, 1.0, 1.0);         // Opaque blue

    // Red (50% alpha) over Blue (100% alpha)
    // Alpha_out = 0.5 + 1.0 * (1 - 0.5) = 0.5 + 0.5 = 1.0
    // R_out = (1.0*0.5 + 0.0*1.0*(1-0.5)) / 1.0 = 0.5 / 1.0 = 0.5
    // G_out = (0.0*0.5 + 0.0*1.0*(1-0.5)) / 1.0 = 0.0 / 1.0 = 0.0
    // B_out = (0.0*0.5 + 1.0*1.0*(1-0.5)) / 1.0 = 0.5 / 1.0 = 0.5
    const blended1 = blendAlpha(semi_transparent_red, opaque_blue);
    try std.testing.expect(blended1.eql(Color.new(0.5, 0.0, 0.5, 1.0))); // Purple

    const fully_transparent = Color.new(1.0, 1.0, 1.0, 0.0); // Transparent white
    const blended2 = blendAlpha(fully_transparent, opaque_blue);
    try std.testing.expect(blended2.eql(opaque_blue)); // Transparent over opaque -> opaque

    const opaque_red = Color.new(1.0, 0.0, 0.0, 1.0);
    const blended3 = blendAlpha(opaque_red, opaque_blue);
    try std.testing.expect(blended3.eql(opaque_red)); // Opaque over opaque -> top color

    std.log.info("Color manipulation utilities test completed.", .{});
}

// Ensure graphics/color.zig has the necessary BaseColor definitions (Black, Gray, Blue, etc.)
// and the `eql` method for these tests to pass correctly.
// The previous step updated graphics/color.zig, so this should be fine.
