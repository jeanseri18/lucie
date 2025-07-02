// src/ecs/system.zig
// Base system definition for the ECS.

const std = @import("std");

// Forward declare World to avoid circular dependencies if System needs to reference World.
// However, System method signatures will take `?*World` so direct import isn't strictly needed here.
// const World = @import("world.zig").World; // Causes import cycle if world.zig imports system.zig

// A System processes entities that have a certain set of components.
// This is a base struct that specific systems can embed or use as a model.
// In Zig, polymorphism for systems is often achieved using a struct with function pointers (a vtable).

// Define the function pointer types for the system's lifecycle methods.
// `?*anyopaque` is used for `self` to allow different system structs to implement these.
// The actual `self` pointer will be cast back to the concrete system type within the implementation.
// Alternatively, `*System` can be used if all systems embed `System` as their first field.
pub const SystemFnAttach = fn (self: *System, world: ?*@import("world.zig").World) void;
pub const SystemFnUpdate = fn (self: *System, world: ?*@import("world.zig").World, dt: f32) void;
pub const SystemFnDeinit = fn (self: *System, allocator: std.mem.Allocator) void; // For freeing system's own resources

pub const System = struct {
    // VTable for polymorphic behavior
    on_attach_fn: SystemFnAttach,
    update_fn: SystemFnUpdate,
    deinit_fn: SystemFnDeinit,

    // Optional: common system properties
    is_enabled: bool = true,
    // name: []const u8 = "UnnamedSystem", // For debugging

    // Public interface that dispatches to function pointers
    pub fn onAttach(self: *System, world: ?*@import("world.zig").World) void {
        self.on_attach_fn(self, world);
    }

    pub fn update(self: *System, world: ?*@import("world.zig").World, dt: f32) void {
        if (!self.is_enabled) return;
        self.update_fn(self, world, dt);
    }

    pub fn deinit(self: *System, allocator: std.mem.Allocator) void {
        self.deinit_fn(self, allocator);
    }

    // Helper to create a System instance with specific implementations.
    // This is how concrete systems provide their logic.
    pub fn create(
        attach_fn_impl: SystemFnAttach,
        update_fn_impl: SystemFnUpdate,
        deinit_fn_impl: SystemFnDeinit,
    ) System {
        return System{
            .on_attach_fn = attach_fn_impl,
            .update_fn = update_fn_impl,
            .deinit_fn = deinit_fn_impl,
        };
    }
};

// --- Example of how a concrete system might be defined ---
// This would typically be in its own file, e.g., `systems/movement_system.zig`

// pub const MyConcreteSystem = struct {
//     // Embed the base System to make this a System.
//     // This allows casting `*MyConcreteSystem` to `*System`.
//     base: System,
//
//     // Specific data for this system
//     some_data: i32,
//     allocator: std.mem.Allocator, // If it allocates its own resources

//     // Implementation of the system's logic
//     fn doAttach(self_concrete: *MyConcreteSystem, world: ?*@import("world.zig").World) void {
//         _ = world; // Use world if needed
//         std.log.info("MyConcreteSystem ({any}) attached. Data: {d}", .{self_concrete, self_concrete.some_data});
//         // Initialize system based on world state if necessary
//     }

//     fn doUpdate(self_concrete: *MyConcreteSystem, world: ?*@import("world.zig").World, dt: f32) void {
//         _ = world; // Use world to query/update components
//         // std.log.debug("MyConcreteSystem ({any}) update. DeltaTime: {d}, Data: {d}", .{self_concrete, dt, self_concrete.some_data});
//         // Perform system logic, e.g., iterate entities with specific components
//         self_concrete.some_data += 1; // Example internal state change
//     }

//     fn doDeinit(self_concrete: *MyConcreteSystem, system_allocator: std.mem.Allocator) void {
//         std.log.info("MyConcreteSystem ({any}) deinit. Data: {d}", .{self_concrete, self_concrete.some_data});
//         // Free any resources allocated by this system instance
//         // If `some_data` was a pointer to heap memory, free it here using self_concrete.allocator
//         _ = system_allocator; // This allocator is for the System struct itself if World allocated it.
//                               // self_concrete.allocator is for this system's internal allocations.
//     }

//     // Public constructor for MyConcreteSystem
//     pub fn init(allocator_param: std.mem.Allocator, initial_data: i32) MyConcreteSystem {
//         return MyConcreteSystem{
//             .base = System.create(
//                 // Cast `self` from `*System` back to `*MyConcreteSystem`
//                 // This relies on MyConcreteSystem.base being the first field.
//                 (struct {fn f(s: *System, w:?*@import("world.zig").World)void{doAttach(@ptrCast(*MyConcreteSystem, @alignCast(@alignOf(MyConcreteSystem),s)),w);}}).f,
//                 (struct {fn f(s: *System, w:?*@import("world.zig").World, d:f32)void{doUpdate(@ptrCast(*MyConcreteSystem, @alignCast(@alignOf(MyConcreteSystem),s)),w,d);}}).f,
//                 (struct {fn f(s: *System, a:std.mem.Allocator)void{doDeinit(@ptrCast(*MyConcreteSystem, @alignCast(@alignOf(MyConcreteSystem),s)),a);}}).f
//             ),
//             .some_data = initial_data,
//             .allocator = allocator_param,
//         };
//     }
// };


// --- Test System Implementations (using the direct System.create pattern) ---

// A simple test system that logs its lifecycle
var test_system_attach_called = false;
var test_system_update_called = false;
var test_system_deinit_called = false;

fn testAttachFn(_: *System, world: ?*@import("world.zig").World) void {
    _ = world;
    test_system_attach_called = true;
    std.log.debug("TestSystem: Attached.", .{});
}
fn testUpdateFn(_: *System, world: ?*@import("world.zig").World, dt: f32) void {
    _ = world; _ = dt;
    test_system_update_called = true;
    std.log.debug("TestSystem: Updated with dt = {d}", .{dt});
}
fn testDeinitFn(_: *System, allocator: std.mem.Allocator) void {
    _ = allocator;
    test_system_deinit_called = true;
    std.log.debug("TestSystem: Deinitialized.", .{});
}

const TestSystem = System.create(testAttachFn, testUpdateFn, testDeinitFn);


test "Base System lifecycle" {
    // This test uses the `TestSystem` instance created directly with System.create.
    // In a real scenario, a World would manage system instances.
    const allocator = std.testing.allocator; // For deinit signature, not used by TestSystem impl.

    // Reset test flags
    test_system_attach_called = false;
    test_system_update_called = false;
    test_system_deinit_called = false;

    // Create an instance of TestSystem (it's a const, so we copy it to make it mutable if needed for `is_enabled`)
    var my_test_system_instance = TestSystem;

    // Call lifecycle methods directly on the instance
    // The `world` parameter is null for this direct test.
    my_test_system_instance.onAttach(null);
    try std.testing.expect(test_system_attach_called);

    my_test_system_instance.update(null, 0.016);
    try std.testing.expect(test_system_update_called);

    // Test disabling the system
    test_system_update_called = false; // Reset flag
    my_test_system_instance.is_enabled = false;
    my_test_system_instance.update(null, 0.032);
    try std.testing.expect(!test_system_update_called); // Should not have been called
    my_test_system_instance.is_enabled = true; // Re-enable

    my_test_system_instance.deinit(allocator);
    try std.testing.expect(test_system_deinit_called);

    std.log.info("Base System lifecycle test completed.", .{});
}

// test "Concrete System (MyConcreteSystem) polymorphism" {
//     const allocator = std.testing.allocator;
//     var concrete_sys = MyConcreteSystem.init(allocator, 42);

//     // Get a pointer to the base System part
//     var base_sys_ptr: *System = &concrete_sys.base;

//     // Call methods through the base pointer (polymorphism)
//     base_sys_ptr.onAttach(null); // Should call MyConcreteSystem.doAttach

//     const initial_data = concrete_sys.some_data;
//     base_sys_ptr.update(null, 0.1); // Should call MyConcreteSystem.doUpdate
//     try std.testing.expect(concrete_sys.some_data == initial_data + 1);

//     base_sys_ptr.deinit(allocator); // Should call MyConcreteSystem.doDeinit

//     std.log.info("Concrete System polymorphism test completed.", .{});
// }
