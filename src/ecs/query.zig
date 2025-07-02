// src/ecs/query.zig
// Query system for efficiently iterating over entities with specific components.

const std = @import("std");
const Entity = @import("entity.zig").Entity;
// const World = @import("world.zig").World; // Avoid direct import if possible, pass as arg
// const Archetype = @import("archetype.zig").Archetype; // Needed for archetype-based queries
// const Component = @import("component.zig").Component; // For ComponentTypeId

// --- Query Definition ---

// Represents a query for entities possessing a specific set of components.
// It might also specify components to exclude.
pub const QueryDesc = struct {
    // Component types the entity MUST have.
    // Stored as TypeId for runtime matching against archetypes.
    // For comptime queries, this could be `[]const type`.
    all_of: std.ArrayList(std.meta.Type), // std.meta.Type is ComponentTypeId from component.zig

    // Optional: Component types the entity MAY have (for read/write access declaration).
    // any_of: std.ArrayList(std.meta.Type),

    // Optional: Component types the entity MUST NOT have.
    // none_of: std.ArrayList(std.meta.Type),

    allocator: std.mem.Allocator,

    pub fn init(allocator_param: std.mem.Allocator) QueryDesc {
        return QueryDesc{
            .all_of = std.ArrayList(std.meta.Type).init(allocator_param),
            // .any_of = std.ArrayList(std.meta.Type).init(allocator_param),
            // .none_of = std.ArrayList(std.meta.Type).init(allocator_param),
            .allocator = allocator_param,
        };
    }

    pub fn deinit(self: *QueryDesc) void {
        self.all_of.deinit();
        // self.any_of.deinit();
        // self.none_of.deinit();
    }

    pub fn with(self: *QueryDesc, comptime T: type) !*QueryDesc {
        try self.all_of.append(std.meta.Type.init(T));
        return self;
    }

    // pub fn without(self: *QueryDesc, comptime T: type) !*QueryDesc {
    //     try self.none_of.append(std.meta.Type.init(T));
    //     return self;
    // }

    // pub fn optional(self: *QueryDesc, comptime T: type) !*QueryDesc {
    //     try self.any_of.append(std.meta.Type.init(T));
    //     return self;
    // }
};

// --- Query Result Iterator ---
// This is highly dependent on the ECS storage backend (archetypes, sparse sets, etc.).
// The iterator yields entities or direct component pointers.

// For an archetype-based ECS, a query would iterate over matching archetypes,
// and then over entities within those archetypes.

// Placeholder: An iterator that would yield Entity IDs.
// A real iterator would likely yield tuples of component pointers, e.g. `struct{*Position, *Velocity}`.
pub const QueryIterator = struct {
    // world_ptr: *const World, // Pointer to the world being queried
    // query_desc: QueryDesc,   // The description of what to query

    // Internal state for iteration
    // current_archetype_idx: usize = 0,
    // current_entity_in_archetype_idx: usize = 0,
    // matching_archetypes: std.ArrayList(*Archetype), // Cached list of archetypes that match the query

    // For a simple entity list iteration (less efficient, placeholder):
    all_entities: []const Entity, // Slice of entities to iterate (e.g., from World.entities)
    current_entity_idx: usize = 0,

    // This context would be needed to fetch components for the entity.
    // world_for_components: *const @import("world.zig").World,

    // To make it yield component tuples, the iterator needs to be generic over the component types.
    // This is where Zig's comptime capabilities shine, often using `pub fn iterator(world: *World, comptime Components: []type) IteratorType(...)`

    // Simplified next function for Entity ID iteration
    pub fn next(self: *QueryIterator) ?Entity {
        // This is a naive iteration over all entities, checking components one by one.
        // A real query system would be much more optimized, e.g., using archetypes.
        // This placeholder does NOT actually filter by components.
        if (self.current_entity_idx < self.all_entities.len) {
            const entity = self.all_entities[self.current_entity_idx];
            self.current_entity_idx += 1;
            return entity;
        }
        return null;
    }
};

// --- Query Execution ---

// Placeholder function to "execute" a query.
// In a real ECS, this would be a method of the World or a QuerySystem.
// It would find matching archetypes and prepare an iterator.
pub fn executeQuery(
    world: *const @import("world.zig").World, // The world to query
    // query_desc: *const QueryDesc, // The query criteria
) QueryIterator {
    // 1. Find all archetypes in the world that match `query_desc.all_of`
    //    and do not contain any of `query_desc.none_of`.
    // 2. Collect these matching archetypes.
    // 3. The QueryIterator would then iterate through entities in these archetypes.

    // Placeholder implementation: returns an iterator over ALL entities in the world.
    // This does not actually filter based on the QueryDesc.
    std.log.debug("Executing query (placeholder - iterates all entities)...", .{});
    return QueryIterator{
        .all_entities = world.entities.items, // Using the simplified entity list from placeholder World
        // .world_for_components = world,
    };
}


// --- Example Components for Testing ---
const QPos = struct { x: f32, y: f32 };
const QVel = struct { dx: f32, dy: f32 };
const QTag = struct {}; // A tag component (zero-sized)

test "QueryDesc creation" {
    const allocator = std.testing.allocator;
    var q_desc = QueryDesc.init(allocator);
    defer q_desc.deinit();

    _ = try q_desc.with(QPos);
    _ = try q_desc.with(QVel);
    // _ = try q_desc.without(QTag);
    // _ = try q_desc.optional(QTag); // This was for any_of

    try std.testing.expect(q_desc.all_of.items.len == 2);
    // try std.testing.expect(q_desc.none_of.items.len == 1);
    // try std.testing.expect(q_desc.any_of.items.len == 1);

    // Check if correct TypeIds were stored (fragile due to type ID generation details)
    var found_pos = false;
    var found_vel = false;
    for (q_desc.all_of.items) |type_id| {
        if (type_id.eql(std.meta.Type.init(QPos))) found_pos = true;
        if (type_id.eql(std.meta.Type.init(QVel))) found_vel = true;
    }
    try std.testing.expect(found_pos);
    try std.testing.expect(found_vel);

    std.log.info("QueryDesc creation test completed.", .{});
}

// Test for Query Execution and Iteration (highly conceptual due to placeholders)
// This requires a mock World and component setup.
// For now, we'll just test the placeholder executeQuery and iterator.
// A full test would involve:
// 1. Creating a World.
// 2. Creating entities with various combinations of components.
// 3. Defining a QueryDesc.
// 4. Executing the query on the World.
// 5. Iterating the results and verifying that only matching entities (and their components) are returned.

test "Query execution and iteration (placeholder)" {
    const allocator = std.testing.allocator;
    var world_store = @import("world.zig").World.init(allocator); // Assuming world.zig is accessible
    defer world_store.deinit();

    // Add some entities to the world (World's createEntity is also a placeholder)
    const e1 = try world_store.createEntity();
    const e2 = try world_store.createEntity();
    // In a real test, you'd add components to these entities here.
    // e.g., world_store.addComponent(e1, QPos{ .x=1, .y=1 });
    //       world_store.addComponent(e2, QPos{ .x=2, .y=2 });
    //       world_store.addComponent(e2, QVel{ .dx=0.1, .dy=0.1});


    // var q_desc = QueryDesc.init(allocator);
    // defer q_desc.deinit();
    // _ = try q_desc.with(QPos); // Query for entities with QPos

    // Execute the query (placeholder version)
    var iterator = executeQuery(&world_store /*, &q_desc */);

    var count: usize = 0;
    while (iterator.next()) |_entity| {
        // In a real test, you'd get components for `_entity` and verify them.
        // e.g. var pos = world_store.getComponent(_entity, QPos); try std.testing.expect(pos != null);
        count += 1;
    }

    // Placeholder query iterates all entities, so count should be total entities.
    try std.testing.expect(count == world_store.entities.items.len);
    try std.testing.expect(count == 2); // Since we created 2 entities

    std.log.info("Query execution (placeholder) test completed. Iterated {d} entities.", .{count});
}
