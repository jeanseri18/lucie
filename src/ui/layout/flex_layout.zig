// src/ui/layout/flex_layout.zig
// Implements Flexbox-like layout calculations.
// This is a complex layout algorithm. This file will be a placeholder for its structure.

const std = @import("std");
const Vec2 = @import("../../math/vec2.zig").Vec2;
const LayoutElement = @import("layout_manager.zig").LayoutElement; // Re-use definition
const LayoutContext = @import("layout_manager.zig").LayoutContext;

// Properties for a flex container
pub const FlexContainerProps = struct {
    direction: FlexDirection = .Row,
    wrap: FlexWrap = .NoWrap,
    justify_content: JustifyContent = .FlexStart,
    align_items: AlignItems = .Stretch,    // Default for cross-axis alignment of items
    align_content: AlignContent = .Stretch, // For multi-line flex containers (when wrap is active)

    // Gap between items
    gap_row: f32 = 0.0,
    gap_column: f32 = 0.0,

    // Padding within the container (affects available space for children)
    // padding_left: f32 = 0.0, ... padding_top, padding_right, padding_bottom
};

// Properties for an item within a flex container
pub const FlexItemProps = struct {
    // Order: Not implemented in this placeholder
    // order: i32 = 0,

    // Flexibility
    grow: f32 = 0.0,   // How much the item can grow if there's extra space
    shrink: f32 = 1.0, // How much the item can shrink if there's not enough space
    basis: FlexBasis = .{ .Auto = {} }, // Initial main size of the item

    // Alignment override for this specific item
    align_self: ?AlignItems = null, // If null, uses container's align_items
};

pub const FlexBasis = union(enum) {
    Auto: void,      // Use item's preferred_size or content size
    Content: void,   // Use item's content size (not easily determined in this placeholder)
    Exact: f32,      // Specific value in pixels
    Percent: f32,    // Percentage of container's main size (0.0 to 1.0)
};

pub const FlexDirection = enum { Row, RowReverse, Column, ColumnReverse };
pub const FlexWrap = enum { NoWrap, Wrap, WrapReverse };
pub const JustifyContent = enum { FlexStart, FlexEnd, Center, SpaceBetween, SpaceAround, SpaceEvenly };
pub const AlignItems = enum { FlexStart, FlexEnd, Center, Stretch, Baseline /* Not impl */ };
pub const AlignContent = enum { FlexStart, FlexEnd, Center, Stretch, SpaceBetween, SpaceAround };


pub const FlexLayoutEngine = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator_param: std.mem.Allocator) FlexLayoutEngine {
        return FlexLayoutEngine{ .allocator = allocator_param };
    }

    pub fn deinit(self: *FlexLayoutEngine) void {
        _ = self; // No allocations in this placeholder engine itself
    }

    // Calculates the layout for a list of items within a container.
    // `items` is a mutable slice; this function will update their `computed_position` and `computed_size`.
    // `container_layout_element` provides the available space from its `computed_size`.
    pub fn calculate(
        self: *FlexLayoutEngine,
        layout_ctx: *const LayoutContext, // Provides available_space
        items_with_props: []FlexLayoutItemWithComputed, // Slice of items to layout
        container_props: FlexContainerProps,
    ) void {
        _ = self; // Mark as used

        if (items_with_props.len == 0) return;

        std.log.debug("FlexLayoutEngine.calculate: {d} items, available space ({d:.0}x{d:.0}), direction: {any}", .{
            items_with_props.len, layout_ctx.available_space.x, layout_ctx.available_space.y, container_props.direction
        });

        // This is a major simplification. A full Flexbox implementation involves:
        // 1. Resolving flexible lengths (flex-basis, flex-grow, flex-shrink).
        //    - Determine main/cross axes based on flex-direction.
        //    - Calculate initial main size of each item (flex-basis).
        //    - Distribute remaining space (flex-grow) or shrink items (flex-shrink).
        // 2. Handling flex lines if wrapping is enabled (flex-wrap).
        //    - Group items into lines.
        //    - Apply align-content to distribute space between lines.
        // 3. Aligning items within each flex line (align-items, align-self).
        // 4. Justifying content along the main axis (justify-content).
        // 5. Calculating final positions and sizes.

        // Placeholder logic: Simple horizontal or vertical list, no grow/shrink/wrap.
        // Assigns preferred size and stacks them.
        var current_pos = Vec2.zero(); // Relative to container's content area
        const main_axis_is_horizontal = (container_props.direction == .Row or container_props.direction == .RowReverse);

        for (items_with_props) |*item_wp| {
            var item = &item_wp.layout_element; // Get mutable LayoutElement part

            // Use preferred_size as the basis for this placeholder
            item.computed_size = item.preferred_size;
            item.computed_position = current_pos;

            if (main_axis_is_horizontal) {
                current_pos.x += item.computed_size.x + container_props.gap_column;
            } else { // Vertical
                current_pos.y += item.computed_size.y + container_props.gap_row;
            }
        }

        // TODO: Implement actual Flexbox algorithm.
        // Libraries like `stretch` (Rust, C bindings) or `yoga` (C++) are examples of full implementations.
        // A pure Zig implementation would be a significant undertaking.
        std.log.warn("Flexbox layout is currently a placeholder and only does simple stacking.", .{});
    }
};

// Helper struct to pair LayoutElement with its FlexItemProps for processing.
pub const FlexLayoutItemWithComputed = struct {
    layout_element: LayoutElement, // This will be modified with computed_pos/size
    flex_props: FlexItemProps,
};


test "FlexLayoutEngine initialization" {
    const allocator = std.testing.allocator;
    var engine = FlexLayoutEngine.init(allocator);
    defer engine.deinit(); // Trivial for placeholder

    try std.testing.expect(engine.allocator == allocator);
    std.log.info("FlexLayoutEngine initialization test completed.", .{});
}

test "FlexLayoutEngine.calculate (placeholder behavior)" {
    const allocator = std.testing.allocator;
    var engine = FlexLayoutEngine.init(allocator);
    defer engine.deinit();

    const layout_context = LayoutContext{ .available_space = Vec2.new(800, 600) };
    const container_props = FlexContainerProps{ .direction = .Row, .gap_column = 10 };

    var items_data = [_]FlexLayoutItemWithComputed{
        .{ .layout_element = .{ .preferred_size = Vec2.new(100,50) }, .flex_props = .{} },
        .{ .layout_element = .{ .preferred_size = Vec2.new(150,50) }, .flex_props = .{} },
        .{ .layout_element = .{ .preferred_size = Vec2.new(50,50) }, .flex_props = .{} },
    };

    engine.calculate(&layout_context, &items_data, container_props);

    // Check placeholder behavior (simple horizontal stacking)
    // Item 1
    try std.testing.expect(items_data[0].layout_element.computed_position.eql(Vec2.new(0,0)));
    try std.testing.expect(items_data[0].layout_element.computed_size.eql(Vec2.new(100,50)));
    // Item 2
    try std.testing.expect(items_data[1].layout_element.computed_position.eql(Vec2.new(100 + 10, 0))); // pos.x = 0 + 100 (size1.x) + 10 (gap)
    try std.testing.expect(items_data[1].layout_element.computed_size.eql(Vec2.new(150,50)));
    // Item 3
    try std.testing.expect(items_data[2].layout_element.computed_position.eql(Vec2.new(100 + 10 + 150 + 10, 0))); // pos.x = 110 + 150 + 10
    try std.testing.expect(items_data[2].layout_element.computed_size.eql(Vec2.new(50,50)));

    std.log.info("FlexLayoutEngine.calculate (placeholder) test completed.", .{});
}

test "Flex enums and structs default values" {
    const c_props = FlexContainerProps{};
    try std.testing.expect(c_props.direction == .Row);
    try std.testing.expect(c_props.wrap == .NoWrap);
    try std.testing.expect(c_props.justify_content == .FlexStart);
    try std.testing.expect(c_props.align_items == .Stretch);
    try std.testing.expect(c_props.gap_row == 0.0);

    const i_props = FlexItemProps{};
    try std.testing.expect(i_props.grow == 0.0);
    try std.testing.expect(i_props.shrink == 1.0);
    try std.testing.expect(i_props.basis == .Auto);
    try std.testing.expect(i_props.align_self == null);

    std.log.info("Flex enums/structs default values test completed.", .{});
}
