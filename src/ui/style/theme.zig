// src/ui/style/theme.zig
// Defines UI themes and styles (colors, fonts, spacing).

const std = @import("std");
const Color = @import("../../graphics/color.zig").Color;
// const FontHandle = u32; // Placeholder for font resource handle

// Defines style properties for a specific widget type or state.
pub const WidgetStyle = struct {
    background_color: Color = Color.Transparent,
    text_color: Color = Color.Black,
    border_color: Color = Color.Transparent,
    border_width: f32 = 0.0,
    // font_handle: ?FontHandle = null,
    font_size_px: f32 = 14.0,

    // Padding within the widget (space between border and content)
    padding_top: f32 = 2.0,
    padding_right: f32 = 4.0,
    padding_bottom: f32 = 2.0,
    padding_left: f32 = 4.0,

    // Margin outside the widget (space to next widget)
    // margin_top: f32 = 0.0, ...
};

// Specific styles for different widgets and their states
pub const ButtonTheme = struct {
    normal: WidgetStyle = WidgetStyle{ .background_color = Color.LightGray, .text_color = Color.Black, .border_color = Color.DarkGray, .border_width = 1.0, .padding_left = 8.0, .padding_right = 8.0},
    hover: WidgetStyle = WidgetStyle{ .background_color = Color.Gray, .text_color = Color.White, .border_color = Color.Black, .border_width = 1.0, .padding_left = 8.0, .padding_right = 8.0},
    pressed: WidgetStyle = WidgetStyle{ .background_color = Color.DarkSlateGray, .text_color = Color.White, .border_color = Color.Black, .border_width = 1.0, .padding_left = 8.0, .padding_right = 8.0},
    // disabled: WidgetStyle = ...,
};

pub const PanelTheme = struct {
    background: WidgetStyle = WidgetStyle{ .background_color = Color.new(0.15, 0.15, 0.18, 0.95), .padding_top = 5.0, .padding_bottom = 5.0, .padding_left = 5.0, .padding_right = 5.0 },
    // title_bar_style: WidgetStyle = ...,
};

pub const CheckboxTheme = struct {
    box_normal: WidgetStyle = WidgetStyle{ .background_color = Color.White, .border_color = Color.DarkGray, .border_width = 1.0 },
    box_hover: WidgetStyle = WidgetStyle{ .background_color = Color.LightCyan, .border_color = Color.Gray, .border_width = 1.0 },
    check_mark_color: Color = Color.Blue,
    label_style: WidgetStyle = WidgetStyle { .text_color = Color.Black, .padding_left = 4.0 },
};

pub const SliderTheme = struct {
    track_color: Color = Color.DarkGray,
    handle_color_normal: Color = Color.LightGray,
    handle_color_hover: Color = Color.Cyan,
    label_style: WidgetStyle = WidgetStyle { .text_color = Color.Black, .padding_right = 5.0}, // For label next to slider
    value_text_style: WidgetStyle = WidgetStyle { .text_color = Color.DarkGray, .padding_left = 5.0}, // For displaying value
};

pub const LabelTheme = struct {
    style: WidgetStyle = WidgetStyle { .text_color = Color.Black, .font_size_px = 14.0 },
};


// A Theme aggregates styles for various UI elements.
pub const Theme = struct {
    allocator: std.mem.Allocator, // If theme loads fonts or other resources

    name: []const u8 = "DefaultTheme",

    // Default properties (can be overridden by specific widget styles)
    default_font_size: f32 = 14.0,
    // default_font_handle: ?FontHandle = null,
    default_text_color: Color = Color.Black,
    default_background_color: Color = Color.White, // General window/app background
    default_spacing: f32 = 5.0, // Default gap/padding unit

    // Widget-specific themes
    button: ButtonTheme = .{},
    panel: PanelTheme = .{},
    checkbox: CheckboxTheme = .{},
    slider: SliderTheme = .{},
    label: LabelTheme = .{},
    // text_input: TextInputTheme = .{},
    // ... other widget themes

    pub fn default(allocator_param: std.mem.Allocator) Theme {
        std.log.debug("Creating default Theme.", .{});
        var theme = Theme{
            .allocator = allocator_param,
        };
        // Example: Customize a specific part of the default theme
        theme.panel.background.background_color = Color.new(0.92, 0.92, 0.95, 1.0); // Light background for panels
        theme.label.style.text_color = Color.new(0.1, 0.1, 0.1, 1.0); // Darker text for labels

        // Load default font here if applicable
        // theme.default_font_handle = try loadDefaultFont(allocator_param);
        return theme;
    }

    pub fn deinit(self: *Theme) void {
        std.log.debug("Deinitializing Theme: {s}", .{self.name});
        // Unload fonts or other resources allocated by the theme
        // if (self.default_font_handle) |handle| {
        //    unloadFont(self.allocator, handle);
        // }
        _ = self;
    }
};


test "Theme initialization with default values" {
    const allocator = std.testing.allocator;
    var theme = Theme.default(allocator);
    defer theme.deinit();

    try std.testing.expectEqualStrings("DefaultTheme", theme.name);
    try std.testing.expect(theme.default_font_size == 14.0);

    // Check some default sub-theme values (after Theme.default() customization)
    try std.testing.expect(theme.button.normal.background_color.eql(Color.LightGray));
    try std.testing.expect(theme.panel.background.background_color.eql(Color.new(0.92,0.92,0.95,1.0)));
    try std.testing.expect(theme.label.style.text_color.eql(Color.new(0.1,0.1,0.1,1.0)));
    try std.testing.expect(theme.checkbox.box_normal.border_color.eql(Color.DarkGray));
    try std.testing.expect(theme.slider.track_color.eql(Color.DarkGray));

    std.log.info("Theme initialization with default values test completed.", .{});
}

test "WidgetStyle default values" {
    const style = WidgetStyle{};
    try std.testing.expect(style.background_color.eql(Color.Transparent));
    try std.testing.expect(style.text_color.eql(Color.Black));
    try std.testing.expect(style.border_width == 0.0);
    try std.testing.expect(style.font_size_px == 14.0);
    try std.testing.expect(style.padding_left == 4.0);

    std.log.info("WidgetStyle default values test completed.", .{});
}
