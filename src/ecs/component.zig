// src/ecs/component.zig
// Base component definitions or related utilities.

const std = @import("std");

// In Zig, components are typically just structs (plain old data).
// There isn't usually a base "Component" struct they need to inherit from in the traditional OOP sense.
// However, this file can serve as a place for:
// 1. Defining component-related concepts or type traits.
// 2. Component registration utilities (if any).
// 3. Common component types or interfaces (though less common in pure ECS).

// --- Component Type Identification ---

// A more robust way to get unique IDs for component types.
// This uses `std.meta.Type` which provides unique identifiers for types.
pub const ComponentTypeId = std.meta.Type;

pub fn getComponentId(comptime T: type) ComponentTypeId {
    return std.meta.Type.init(T);
}

// --- Component Traits/Concepts (Example) ---

// Example: A trait to check if a type is a "Plain Old Data" component.
// This is more of a conceptual check, as Zig structs are generally POD-like.
// pub fn isPODComponent(comptime T: type) bool {
//     return switch (@typeInfo(T)) {
//         .Struct => |s| !s.has_deinit and !s.has_custom_member_fns, // Simplified check
//         else => false,
//     };
// }

// --- Component Wrapper (Optional, for type erasure or dynamic components) ---
// Sometimes, if you need to store components of different types in a generic way
// without full archetype systems, a wrapper might be used. This is less common in high-performance ECS.
//
// pub const ComponentWrapper = struct {
//     type_id: ComponentTypeId,
//     data: *anyopaque, // Pointer to the actual component data
//     // deinit_fn: ?fn(*anyopaque, std.mem.Allocator) void, // For freeing the component
//
//     pub fn init(allocator: std.mem.Allocator, comptime T: type, component_value: T) !ComponentWrapper {
//         const ptr = try allocator.create(T);
//         ptr.* = component_value;
//         return ComponentWrapper {
//             .type_id = getComponentId(T),
//             .data = @ptrCast(*anyopaque, ptr),
//             // .deinit_fn = struct { fn deinit(ptr_any: *anyopaque, alloc: std.mem.Allocator) void { alloc.destroy(@ptrCast(*T, @alignCast(@alignOf(T), ptr_any))); }}.deinit,
//         };
//     }
//
//     pub fn deinit(self: *ComponentWrapper, allocator: std.mem.Allocator) void {
//         // Need a way to call the correct typed destroy.
//         // This is complex and often why type erasure is tricky for components.
//         // If a deinit_fn was stored:
//         // if (self.deinit_fn) |dfn| dfn(self.data, allocator);
//         // Or, the World/Archetype that knows the type would handle deallocation.
//         _ = self; _ = allocator; // Placeholder
//         @panic("ComponentWrapper.deinit requires type information or registered deinit function.");
//     }
//
//     pub fn get(self: *const ComponentWrapper, comptime T: type) ?*T {
//         if (self.type_id.eql(getComponentId(T))) {
//             return @ptrCast(*T, @alignCast(@alignOf(T), self.data));
//         }
//         return null;
//     }
// };


// --- Example Components (can also be in their own files like ecs/components/transform.zig) ---
// These are just type definitions. The actual component files are listed in the plan.

// pub const TransformComponent = struct {
//     position: Vec3,
//     rotation: Quaternion,
//     scale: Vec3 = Vec3.one(),
// };

// pub const RenderableComponent = struct {
//     mesh_handle: u32, // Or some Mesh resource type
//     material_handle: u32, // Or Material resource type
// };

// pub const HealthComponent = struct {
//     current: i32,
//     max: i32,
// };


test "ComponentTypeId generation" {
    const MyComponent1 = struct { a: i32 };
    const MyComponent2 = struct { b: f32 };
    const MyComponent1Again = struct { a: i32 }; // Same structure as MyComponent1

    const id1 = getComponentId(MyComponent1);
    const id2 = getComponentId(MyComponent2);
    const id1_again = getComponentId(MyComponent1);
    const id1_struct_again = getComponentId(MyComponent1Again); // This is a DIFFERENT type

    try std.testing.expect(!id1.eql(id2)); // Different types should have different IDs
    try std.testing.expect(id1.eql(id1_again)); // Same type should have same ID

    // `std.meta.Type` distinguishes between structurally identical but separately defined types.
    // So MyComponent1 and MyComponent1Again will have different TypeIds.
    try std.testing.expect(!id1.eql(id1_struct_again));

    std.log.info("ComponentTypeId for MyComponent1: {any}", .{id1});
    std.log.info("ComponentTypeId for MyComponent2: {any}", .{id2});
    std.log.info("ComponentTypeId for MyComponent1Again (structurally same): {any}", .{id1_struct_again});

    // Test with a built-in type
    const id_u32 = getComponentId(u32);
    const id_f64 = getComponentId(f64);
    try std.testing.expect(!id_u32.eql(id_f64));
    std.log.info("ComponentTypeId for u32: {any}", .{id_u32});
}

// test "ComponentWrapper basic usage" {
//     const allocator = std.testing.allocator;
//     const Health = struct { hp: i32 };
//     const Mana = struct { mp: i32 };

//     var health_comp = Health{ .hp = 100 };
//     var wrapper1 = try ComponentWrapper.init(allocator, Health, health_comp);
//     // defer wrapper1.deinit(allocator); // Deinit is problematic in this placeholder

//     var mana_comp = Mana{ .mp = 50 };
//     var wrapper2 = try ComponentWrapper.init(allocator, Mana, mana_comp);
//     // defer wrapper2.deinit(allocator);

//     // Test getting typed data
//     const retrieved_health = wrapper1.get(Health);
//     try std.testing.expect(retrieved_health != null);
//     try std.testing.expect(retrieved_health.?.hp == 100);

//     const should_be_null = wrapper1.get(Mana);
//     try std.testing.expect(should_be_null == null);

//     const retrieved_mana = wrapper2.get(Mana);
//     try std.testing.expect(retrieved_mana != null);
//     try std.testing.expect(retrieved_mana.?.mp == 50);

//     // Cleanup (manual for this test due to deinit placeholder)
//     allocator.destroy(@ptrCast(*Health, @alignCast(@alignOf(Health), wrapper1.data)));
//     allocator.destroy(@ptrCast(*Mana, @alignCast(@alignOf(Mana), wrapper2.data)));

//     std.log.info("ComponentWrapper test completed.", .{});
// }
