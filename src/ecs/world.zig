// src/ecs/world.zig
// ECS World: Manages entities, components, and systems.

const std = @import("std");
const Entity = @import("entity.zig").Entity;
const Archetype = @import("archetype.zig").Archetype; // Assuming an Archetype file will be created
const System = @import("system.zig").System;
const Component = @import("component.zig").Component; // For component type info if needed

// Helper for component type IDs.
// This could be more sophisticated, e.g., using comptime registration.
var next_component_type_id: u32 = 0;
pub fn getComponentTypeId(comptime T: type) u32 {
    // This is a simplified way to get unique IDs at compile time for different types.
    // A more robust system might use a global registry or `std.meta.TypeId`.
    // For now, a comptime variable that increments for each new type `T` encountered.
    // This requires `T` to be known at compile-time.
    // This basic approach might assign same ID if called from different comptime contexts
    // for the same type. A true unique ID generator is more complex.
    // Let's use a placeholder that relies on `std.meta.typeName` for some uniqueness,
    // then hash it, or simply use a counter.
    // A simple counter per type `T` is not what we want. We want one ID per type.
    // `std.meta.trait.UniqueId` can generate unique IDs at comptime.
    comptime {
        // This is just a placeholder. A real system would ensure true unique IDs.
        // For example, by using a global comptime hash map of type names to IDs.
        // Or by relying on a more advanced comptime reflection feature.
        // `std.meta.trait.UniqueId(T)` is a good candidate.
        // However, let's use a simple incrementing ID for this placeholder.
        // This is NOT robust for a real ECS.
        const id = next_component_type_id;
        next_component_type_id += 1;
        return id;
    }
}


pub const World = struct {
    allocator: std.mem.Allocator,

    // Entity management
    entities: std.ArrayList(Entity), // List of all entities
    // TODO: Add more sophisticated entity storage, e.g., with generation IDs for recycling.
    // For now, Entity is just a u32 ID.

    // Component storage (Archetype-based approach is common and efficient)
    // archetypes: std.ArrayList(Archetype), // Each archetype stores components for a set of entities
    // entity_archetype_map: std.AutoHashMap(Entity, *Archetype), // Maps entity to its archetype

    // Simpler component storage for this placeholder:
    // One ArrayList per component type, indexed by Entity ID.
    // This is NOT efficient for querying but simple to start.
    // Example for a Transform component:
    // transforms: std.AutoHashMap(Entity, TransformComponent),
    // A better approach involves `std.ComptimeArrayListHashMap` or similar for type-to-storage mapping.

    // System management
    systems: std.ArrayList(*System), // Polymorphic systems

    // For this placeholder, let's use a very simplified component storage.
    // A real ECS would use archetypes or sparse sets.
    // We'll need a way to store components of different types.
    // `std.any.Any` could be used, or type-erased storage per component type.

    // Let's simulate a very basic component storage:
    // A hash map from Entity ID to another hash map of ComponentTypeID to *anyopaque (component data)
    // This is highly inefficient and mainly for structural placeholder.
    // component_storage: std.AutoHashMap(Entity, std.AutoHashMap(u32, *anyopaque)),

    // A slightly better placeholder: each component type has its own storage.
    // This requires knowing all component types or using comptime magic.
    // For the plan, let's assume we'll create concrete component files like transform.zig.
    // The World would then have specific storage for these. This is not generic enough for a real ECS.

    // Let's assume an Archetype based model conceptually, even if not fully implemented here.
    // For now, the World will just manage entities and systems. Component storage details deferred.

    pub fn init(allocator_param: std.mem.Allocator) World {
        std.log.debug("Initializing ECS World...", .{});
        return World{
            .allocator = allocator_param,
            .entities = std.ArrayList(Entity).init(allocator_param),
            // .component_storage = std.AutoHashMap(Entity, std.AutoHashMap(u32, *anyopaque)).init(allocator_param),
            .systems = std.ArrayList(*System).init(allocator_param),
        };
    }

    pub fn deinit(self: *World) void {
        std.log.debug("Deinitializing ECS World...", .{});
        // Deinitialize systems
        for (self.systems.items) |sys| {
            sys.deinit(self.allocator); // Assuming systems have a deinit
            self.allocator.destroy(sys); // If systems were allocated by world
        }
        self.systems.deinit();

        // Deinitialize component storage
        // This is complex with the placeholder `component_storage`.
        // Each stored component would need to be deinitialized and freed.
        // var it = self.component_storage.iterator();
        // while (it.next()) |entry| {
        //     var inner_it = entry.value_ptr.*.iterator();
        //     while (inner_it.next()) |inner_entry| {
        //         // How to deinit *anyopaque? Need component type info.
        //         // self.allocator.destroy(inner_entry.value_ptr.*); // This is wrong without type
        //     }
        //     entry.value_ptr.*.deinit();
        // }
        // self.component_storage.deinit();

        self.entities.deinit();
    }

    pub fn createEntity(self: *World) !Entity {
        // Simple entity ID generation: just the next index.
        // A real ECS uses generations to recycle IDs safely.
        const new_entity_id = @intCast(u32, self.entities.items.len); // Placeholder Entity ID
        const entity = Entity.new(new_entity_id); // Assuming Entity has a constructor

        try self.entities.append(entity); // Store it for tracking (maybe not needed if only an ID)
        // Initialize component map for this entity
        // try self.component_storage.put(entity, std.AutoHashMap(u32, *anyopaque).init(self.allocator));

        std.log.debug("Created Entity: ID {d}", .{entity.id});
        return entity;
    }

    pub fn destroyEntity(self: *World, entity: Entity) void {
        std.log.debug("Destroying Entity: ID {d}", .{entity.id});
        // Remove entity from list (if simple list is used)
        // This is inefficient. A real ECS would mark as inactive or use a free list.
        var i: usize = 0;
        while (i < self.entities.items.len) : (i += 1) {
            if (self.entities.items[i].id == entity.id) {
                _ = self.entities.swapRemove(i);
                break;
            }
        }

        // Remove all components associated with the entity
        // if (self.component_storage.fetchRemove(entity)) |removed_entry| {
        //     var inner_map = removed_entry.value;
        //     var inner_it = inner_map.iterator();
        //     while (inner_it.next()) |comp_entry| {
        //         // Again, deallocating *anyopaque is tricky without type info.
        //         // This placeholder assumes components are simple pointers that can be freed directly,
        //         // or that a more complex system handles their deallocation.
        //         // self.allocator.destroy(comp_entry.value_ptr.*); // Example, likely incorrect
        //     }
        //     inner_map.deinit();
        // }

        // Notify systems about entity destruction (optional, systems might query)
    }

    // Placeholder for adding a component to an entity
    // CompType: type of the component struct
    // component_data: instance of the component struct
    // A real ECS would use `addComponent(world, entity, component_instance)`
    // Or `world.addComponent(entity, component_instance)`
    // pub fn addComponent(self: *World, entity: Entity, comptime CompType: type, component_data: CompType) !void {
    //     const type_id = getComponentTypeId(CompType);
    //     var entity_components = self.component_storage.getPtr(entity) orelse {
    //         std.log.err("Entity {any} not found for addComponent.", .{entity});
    //         return error.EntityNotFound;
    //     };

    //     // Need to allocate memory for the component and store a pointer.
    //     // The `component_data` is passed by value, so we need to copy it to the heap.
    //     const component_ptr = try self.allocator.create(CompType);
    //     component_ptr.* = component_data;

    //     try entity_components.put(type_id, @ptrCast(*anyopaque, component_ptr));
    //     std.log.debug("Added component type {s} (ID {d}) to Entity {any}", .{ @typeName(CompType), type_id, entity });
    // }

    // Placeholder for getting a component from an entity
    // pub fn getComponent(self: *World, entity: Entity, comptime CompType: type) ?*CompType {
    //     const type_id = getComponentTypeId(CompType);
    //     const entity_components = self.component_storage.get(entity) orelse return null;
    //     const component_any_ptr = entity_components.get(type_id) orelse return null;
    //     return @ptrCast(*CompType, @alignCast(@alignOf(CompType), component_any_ptr));
    // }

    // Placeholder for removing a component
    // pub fn removeComponent(self: *World, entity: Entity, comptime CompType: type) void {
    //     const type_id = getComponentTypeId(CompType);
    //     var entity_components = self.component_storage.getPtr(entity) orelse return;
    //     if (entity_components.fetchRemove(type_id)) |removed_entry| {
    //         const component_ptr = @ptrCast(*CompType, @alignCast(@alignOf(CompType), removed_entry.value));
    //         self.allocator.destroy(component_ptr);
    //         std.log.debug("Removed component type {s} from Entity {any}", .{ @typeName(CompType), entity });
    //     }
    // }

    pub fn addSystem(self: *World, system: *System) !void {
        // System could be allocated externally and pointer passed, or allocated by World.
        // Assuming it's passed and World doesn't own its memory directly unless specified.
        // For this example, let's assume systems are heap-allocated and world takes ownership of the pointer's lifecycle for list management.
        // If system itself was passed by value, World would allocate for it.
        try self.systems.append(system);
        system.onAttach(self); // Notify system it's been added
        std.log.debug("Added System: {s} (type placeholder)", .{@typeName(@TypeOf(system.*))});
    }

    pub fn updateSystems(self: *World, dt: f32) void {
        // std.log.debug("Updating all systems (dt: {d:.4})", .{dt});
        for (self.systems.items) |sys| {
            sys.update(self, dt); // Call the polymorphic update
        }
    }

    // TODO: Querying mechanism (e.g., iterate entities with specific components)
    // pub fn query(self: *World, comptime component_types: []type) Iterator { ... }
};

// Dummy component for testing
const PositionComponent = struct { x: f32, y: f32, z: f32 };
const VelocityComponent = struct { dx: f32, dy: f32, dz: f32 };

// Dummy system for testing
const MovementSystem = System.create(
    // onAttach
    struct {
        fn onAttachFn(_: *System, world: ?*World) void {
            _ = world;
            std.log.info("MovementSystem attached.", .{});
        }
    }.onAttachFn,
    // update
    struct {
        fn updateFn(_: *System, world: ?*World, dt: f32) void {
            _ = dt;
            if (world) |w| {
                 std.log.debug("MovementSystem update called. (World has {d} entities - placeholder)", .{w.entities.items.len});
                // Example: Iterate entities with Position and Velocity
                // for (w.entities.items) |entity| {
                //     var pos = w.getComponent(entity, PositionComponent);
                //     const vel = w.getComponent(entity, VelocityComponent);
                //     if (pos != null and vel != null) {
                //         pos.?.x += vel.?.dx * dt;
                //         pos.?.y += vel.?.dy * dt;
                //         pos.?.z += vel.?.dz * dt;
                //     }
                // }
            }
        }
    }.updateFn,
    // deinit
    struct {
        fn deinitFn(_: *System, allocator: std.mem.Allocator) void {
            _ = allocator;
            std.log.info("MovementSystem deinit.", .{});
        }
    }.deinitFn
);


test "ECS World entity management" {
    const allocator = std.testing.allocator;
    var world = World.init(allocator);
    defer world.deinit();

    const entity1 = try world.createEntity();
    try std.testing.expect(entity1.id == 0); // Simple ID scheme for now
    try std.testing.expect(world.entities.items.len == 1);

    const entity2 = try world.createEntity();
    try std.testing.expect(entity2.id == 1);
    try std.testing.expect(world.entities.items.len == 2);

    world.destroyEntity(entity1);
    try std.testing.expect(world.entities.items.len == 1);
    // Check if the remaining entity is entity2 (or its ID is still valid)
    // This depends on how destroyEntity modifies the list. SwapRemove changes order.
    var found_entity2 = false;
    for (world.entities.items) |e| {
        if (e.id == entity2.id) {
            found_entity2 = true;
            break;
        }
    }
    try std.testing.expect(found_entity2);

    std.log.info("ECS World entity management test completed.", .{});
}

test "ECS World system management" {
    const allocator = std.testing.allocator;
    var world = World.init(allocator);
    defer world.deinit();

    // Systems are typically heap allocated.
    var movement_sys_concrete = MovementSystem; // This is the struct instance
    // To add to `systems: std.ArrayList(*System)`, we need a pointer to a System.
    // MovementSystem *is* a System (due to `const System = @This()`), so `&movement_sys_concrete` is `*MovementSystem`.
    // We need to cast it to `*System`.
    // If systems are dynamically allocated by the world or caller:
    var movement_system_ptr = try allocator.create(System); // Allocating the base System type
    movement_system_ptr.* = MovementSystem; // Copying the vtable and any data if System had fields

    try world.addSystem(movement_system_ptr);
    try std.testing.expect(world.systems.items.len == 1);

    world.updateSystems(0.016); // Simulate an update tick

    // Note: `movement_system_ptr` created with `allocator.create` needs to be freed.
    // The world's deinit loop currently calls `allocator.destroy(sys)`, which is correct for this.
    // If `addSystem` took `*MovementSystem` and cast it, the ownership would be different.
    // The current `System.create` makes `MovementSystem` a `System` directly.
    // So `var movement_sys_on_stack = MovementSystem;` and `world.addSystem(&movement_sys_on_stack)` would be problematic
    // if world tried to deallocate stack memory.
    // The test uses heap allocation, which is fine with current world.deinit.

    std.log.info("ECS World system management test completed.", .{});
}

// Test for component type ID generation (basic)
// test "Component Type ID generation" {
//     const pos_id = getComponentTypeId(PositionComponent);
//     const vel_id = getComponentTypeId(VelocityComponent);
//     const pos_id_2 = getComponentTypeId(PositionComponent);

//     // This basic ID generator is just an incrementer, so IDs will be sequential
//     // and different for different types if called in order.
//     // A real test would depend on the specific ID generation strategy.
//     try std.testing.expect(pos_id != vel_id);
//     try std.testing.expect(pos_id == pos_id_2); // Same type should yield same ID in a robust system.
//                                                // Current placeholder might not if calls are reordered by compiler.
//                                                // `std.meta.trait.UniqueId` would guarantee this.
//     std.log.info("PosID: {d}, VelID: {d}, PosID2: {d}", .{pos_id, vel_id, pos_id_2});
// }

// Placeholder for Archetype, will be in its own file.
// const Archetype = struct {
//     // Manages a collection of entities that all have the same set of component types.
//     // Stores components contiguously for cache efficiency.
// };
