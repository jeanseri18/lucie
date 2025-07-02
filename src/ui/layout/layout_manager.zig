// src/ui/layout/layout_manager.zig
// Manages UI element layout (e.g., Flexbox, Grid).

const std = @import("std");
const Vec2 = @import("../../math/vec2.zig").Vec2;
// const Rect = @import("../widgets/button.zig").Rect; // Re-use Rect if suitable, or define LayoutRect
// const UIWidgetHandle = u32; // Or some way to reference UI elements

// Placeholder for a generic UI element's properties needed for layout.
// In a real system, this would interface with the actual widget data.
pub const LayoutElement = struct {
    // id: UIWidgetHandle,
    min_size: Vec2 = Vec2.zero(), // Minimum desired size
    preferred_size: Vec2 = Vec2.new(50,20), // Desired size if space allows
    max_size: Vec2 = Vec2.new(std.math.floatMax(f32), std.math.floatMax(f32)), // Maximum allowed size

    // Layout-specific properties (e.g., flex_grow, grid_column_span)
    // These would be part of specific layout data structs (FlexItemProps, GridItemProps)

    // Calculated properties (output of the layout process)
    computed_position: Vec2 = Vec2.zero(), // Relative to parent container
    computed_size: Vec2 = Vec2.zero(),
};

// Enum for different layout types the manager might support.
pub const LayoutType = enum {
    None,       // No layout, elements are positioned manually/absolutely
    Flex,       // Flexbox-like layout
    Grid,       // Grid-based layout
    // Stack,   // Elements stacked on top of each other
    // VerticalList, // Simple vertical arrangement
    // HorizontalList, // Simple horizontal arrangement
};

// Context for a layout pass.
pub const LayoutContext = struct {
    available_space: Vec2, // Width and height available for layout
    // parent_padding: EdgeWidths,
    // theme_spacing: f32, // Default spacing from theme
    // allocator: std.mem.Allocator, // For temporary calculations
};


pub const LayoutManager = struct {
    allocator: std.mem.Allocator,
    // active_layout_type: LayoutType = .None,
    // current_container_bounds: Rect,
    // elements_to_layout: std.ArrayList(LayoutElement), // List of elements in current container

    // Specific layout engines
    // flex_layout_engine: @import("flex_layout.zig").FlexLayoutEngine,
    // grid_layout_engine: @import("grid_layout.zig").GridLayoutEngine,

    pub fn init(allocator_param: std.mem.Allocator) LayoutManager {
        std.log.debug("Initializing LayoutManager...", .{});
        return LayoutManager{
            .allocator = allocator_param,
            // .flex_layout_engine = FlexLayoutEngine.init(allocator_param),
            // .grid_layout_engine = GridLayoutEngine.init(allocator_param),
            // .elements_to_layout = std.ArrayList(LayoutElement).init(allocator_param),
        };
    }

    pub fn deinit(self: *LayoutManager) void {
        std.log.debug("Deinitializing LayoutManager.", .{});
        // self.flex_layout_engine.deinit();
        // self.grid_layout_engine.deinit();
        // self.elements_to_layout.deinit();
        _ = self; // Mark as used if no fields to deinit for placeholder
    }

    // Called at the start of a UI container's definition (e.g., Panel.begin).
    // `container_rect` is the available space for this layout.
    // pub fn beginLayout(self: *LayoutManager, container_rect: Rect, layout_type_param: LayoutType) void {
    //     self.active_layout_type = layout_type_param;
    //     self.current_container_bounds = container_rect;
    //     self.elements_to_layout.shrinkRetainingCapacity(0); // Clear elements from previous layout
    //     std.log.debug("LayoutManager.beginLayout: Type {any}, Bounds ({d:.0},{d:.0} {d:.0}x{d:.0})", .{
    //         layout_type_param, container_rect.pos.x, container_rect.pos.y, container_rect.size.x, container_rect.size.y
    //     });
    // }

    // Called for each child element within the container.
    // The element's properties (min_size, preferred_size, layout_flags) are registered.
    // pub fn addElement(self: *LayoutManager, element_props: LayoutElement) !void {
    //     // In a real system, element_props might be a pointer to the actual widget
    //     // or a handle, from which layout properties are derived.
    //     try self.elements_to_layout.append(element_props);
    //     std.log.debug("LayoutManager.addElement: PrefSize ({d:.0},{d:.0})", .{element_props.preferred_size.x, element_props.preferred_size.y});
    // }

    // Called at the end of a UI container's definition (e.g., Panel.end).
    // Performs the actual layout calculation and updates `computed_position` and `computed_size`
    // for all registered elements.
    // Returns an iterator or slice of the laid-out elements.
    // pub fn endLayout(self: *LayoutManager) []LayoutElement /* or Iterator */ {
    //     std.log.debug("LayoutManager.endLayout: Calculating for {d} elements.", .{self.elements_to_layout.items.len});
    //     if (self.elements_to_layout.items.len == 0) return &[_]LayoutElement{};

    //     const layout_ctx = LayoutContext {
    //         .available_space = self.current_container_bounds.size,
    //         // .allocator = self.allocator,
    //     };

    //     switch (self.active_layout_type) {
    //         .None => { // Manual/absolute positioning - no calculation needed by manager
    //             // Elements are assumed to have their positions set directly.
    //             // We might just assign preferred_size to computed_size here.
    //             for (self.elements_to_layout.items) |*el| {
    //                 el.computed_size = el.preferred_size;
    //                 // el.computed_position is assumed to be already set (e.g. from widget.rect.pos)
    //             }
    //         },
    //         .Flex => {
    //             // self.flex_layout_engine.calculate(&layout_ctx, self.elements_to_layout.items);
    //             std.log.warn("Flex layout not yet implemented in placeholder LayoutManager.", .{});
    //         },
    //         .Grid => {
    //             // self.grid_layout_engine.calculate(&layout_ctx, self.elements_to_layout.items);
    //             std.log.warn("Grid layout not yet implemented in placeholder LayoutManager.", .{});
    //         },
    //         // Handle other layout types...
    //         else => {
    //             std.log.warn("LayoutManager: LayoutType {any} not implemented. Defaulting to manual.", .{self.active_layout_type});
    //             // Fallback to None-like behavior
    //             for (self.elements_to_layout.items) |*el| { el.computed_size = el.preferred_size; }
    //         }
    //     }
    //     return self.elements_to_layout.items;
    // }

    // --- Standalone layout functions (could be called directly if not using manager state) ---
    // These would take a list of elements and available space, and modify element.computed_*.

    pub fn calculateFlexLayout(
        // allocator: std.mem.Allocator,
        // available_space: Vec2,
        // items: []LayoutElement, // Mutable slice to update computed_pos/size
        // flex_container_props: FlexContainerProperties, // e.g., direction, wrap, align_items, justify_content
    ) void {
        std.log.warn("calculateFlexLayout: Not implemented (placeholder).", .{});
        // Placeholder: just assign preferred size for now to avoid uninit data if items are used.
        // for (items) |*item| {
        //     item.computed_size = item.preferred_size;
        //     // item.computed_position would be set by flex logic.
        // }
    }

    pub fn calculateGridLayout(
        // allocator: std.mem.Allocator,
        // available_space: Vec2,
        // items: []LayoutElement,
        // grid_container_props: GridContainerProperties, // e.g., column/row definitions
    ) void {
        std.log.warn("calculateGridLayout: Not implemented (placeholder).", .{});
    }
};

test "LayoutManager initialization" {
    const allocator = std.testing.allocator;
    var layout_manager = LayoutManager.init(allocator);
    defer layout_manager.deinit(); // Deinit is trivial for placeholder

    // No specific state to check in the placeholder init.
    try std.testing.expect(layout_manager.allocator == allocator);
    std.log.info("LayoutManager initialization test completed.", .{});
}

test "LayoutManager placeholder function calls" {
    // const allocator = std.testing.allocator;
    // var layout_manager = LayoutManager.init(allocator);
    // defer layout_manager.deinit();

    // const container_rect = Rect{ .pos = Vec2.zero(), .size = Vec2.new(800,600) };
    // layout_manager.beginLayout(container_rect, .Flex);

    // var el1 = LayoutElement{ .preferred_size = Vec2.new(100,30) };
    // var el2 = LayoutElement{ .preferred_size = Vec2.new(200,50) }; // With some flex props
    // try layout_manager.addElement(el1);
    // try layout_manager.addElement(el2);

    // const results = layout_manager.endLayout();
    // try std.testing.expect(results.len == 2);
    // For placeholder, results will have computed_size = preferred_size.
    // try std.testing.expect(results[0].computed_size.eql(el1.preferred_size));

    // Direct calls to calculate functions (also placeholders)
    LayoutManager.calculateFlexLayout();
    LayoutManager.calculateGridLayout();

    try std.testing.expect(true); // Placeholder assertion
    std.log.info("LayoutManager placeholder function calls test completed.", .{});
}

// Placeholder for Rect (if not imported from a common place like widgets/button.zig)
// pub const Rect = struct { pos: Vec2, size: Vec2 };
