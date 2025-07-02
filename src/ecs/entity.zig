// src/ecs/entity.zig
// Defines an Entity in the ECS.

const std = @import("std");

// An Entity is typically just an identifier.
// It can include a generation count to safely recycle IDs and avoid the "ABA problem"
// where a new entity might reuse an old ID that some system still references.

pub const Entity = extern struct { // `extern` for predictable layout if used across FFI or for certain alignment needs. Not strictly necessary here.
    id: u32,          // The unique identifier for the entity
    // generation: u16,  // Generation count for recycling IDs (optional, but good practice)

    // Using u64 to pack ID and generation:
    // packed_id: u64, // e.g., lower 32 bits for ID, upper 32 bits for generation

    // For simplicity in this placeholder, Entity is just a u32 ID.
    // A common pattern for u64 packed ID:
    // const ID_BITS = 32;
    // const GEN_BITS = 32;
    // const ID_MASK = (@as(u64, 1) << ID_BITS) - 1;
    // const GEN_MASK = (@as(u64, 1) << GEN_BITS) - 1;

    pub fn new(entity_id: u32 /*, entity_generation: u16 */) Entity {
        return Entity{
            .id = entity_id,
            // .generation = entity_generation,
            // .packed_id = (@as(u64, entity_generation) << ID_BITS) | @as(u64, entity_id),
        };
    }

    // pub fn id(self: Entity) u32 {
    //     return @intCast(u32, self.packed_id & ID_MASK);
    // }

    // pub fn generation(self: Entity) u32 { // Or u16
    //     return @intCast(u32, (self.packed_id >> ID_BITS) & GEN_MASK);
    // }

    // For direct u32 id version:
    pub fn index(self: Entity) u32 { // Often, ID is used as an index directly in simple ECS
        return self.id;
    }

    // Null or invalid entity representation
    pub const Null = Entity{
        .id = std.math.maxInt(u32), // Or specific sentinel value like 0 if 0 is not a valid ID
        // .generation = std.math.maxInt(u16),
        // .packed_id = std.math.maxInt(u64),
    };

    pub fn isNull(self: Entity) bool {
        return self.id == Null.id; // and self.generation == Null.generation;
    }

    // Equality check (needed for HashMaps, etc.)
    // pub fn eql(self: Entity, other: Entity) bool {
    //     return self.id == other.id; // For u32 id version
    //     // return self.packed_id == other.packed_id; // For u64 packed version
    // }
};

// Implement std.hash.Hashable if Entity is used as a key in standard Zig HashMaps.
// For the simple u32 id version:
pub const HashableContext = struct {};
pub fn hash(ctx: HashableContext, key: Entity) u64 {
    _ = ctx;
    var hasher = std.hash.Wyhash.init(0); // Seed = 0
    std.hash.autoHash(&hasher, key.id);
    return hasher.final();
}

pub fn eql(ctx: HashableContext, a: Entity, b: Entity) bool {
    _ = ctx;
    return a.id == b.id;
}


// Entity manager: Responsible for creating, destroying, and recycling entity IDs.
// This is often part of the World, but can be a separate structure.
pub const EntityManager = struct {
    allocator: std.mem.Allocator,
    next_id: u32 = 1, // Start IDs from 1 if 0 is Null/Invalid
    // generations: std.ArrayList(u16), // Stores generation for each live or dead ID slot
    // free_ids: std.ArrayList(u32), // List of recycled IDs

    pub fn init(allocator_param: std.mem.Allocator) EntityManager {
        return EntityManager{
            .allocator = allocator_param,
            // .generations = std.ArrayList(u16).init(allocator_param),
            // .free_ids = std.ArrayList(u32).init(allocator_param),
        };
    }

    pub fn deinit(self: *EntityManager) void {
        // self.generations.deinit();
        // self.free_ids.deinit();
        _ = self; // Nothing to deinit for the simplified version
    }

    pub fn create(self: *EntityManager) Entity {
        // Simplified ID creation (no recycling or generations for this placeholder)
        const id = self.next_id;
        self.next_id += 1;

        // Example with recycling and generations:
        // if (self.free_ids.popOrNull()) |recycled_idx| {
        //     const gen = self.generations.items[recycled_idx];
        //     return Entity.new(recycled_idx, gen);
        // } else {
        //     const new_idx = @intCast(u32, self.generations.items.len);
        //     try self.generations.append(0); // Initial generation 0
        //     return Entity.new(new_idx, 0);
        // }
        return Entity.new(id);
    }

    pub fn destroy(self: *EntityManager, entity: Entity) void {
        // Simplified: does nothing as IDs are not recycled yet.
        // With recycling:
        // const idx = entity.id(); // Or entity.index()
        // self.generations.items[idx] += 1; // Increment generation
        // try self.free_ids.append(idx); // Add to free list
        _ = self;
        _ = entity;
    }

    // pub fn isAlive(self: *const EntityManager, entity: Entity) bool {
    //     const idx = entity.id();
    //     return idx < self.generations.items.len and
    //            self.generations.items[idx] == entity.generation();
    // }
};


test "Entity creation and properties" {
    const e1 = Entity.new(10);
    try std.testing.expect(e1.id == 10);
    try std.testing.expect(e1.index() == 10);
    try std.testing.expect(!e1.isNull());

    // Test with packed ID and generation (if implemented)
    // const e_gen = Entity.new(5, 2); // ID 5, Gen 2
    // try std.testing.expect(e_gen.id() == 5);
    // try std.testing.expect(e_gen.generation() == 2);

    const null_e = Entity.Null;
    try std.testing.expect(null_e.isNull());
    try std.testing.expect(null_e.id == std.math.maxInt(u32));

    std.log.info("Entity struct test completed.", .{});
}

test "EntityManager basic operations (simplified)" {
    const allocator = std.testing.allocator;
    var manager = EntityManager.init(allocator);
    defer manager.deinit();

    const e1 = manager.create(); // Should be ID 1 (if next_id starts at 1)
    try std.testing.expect(e1.id == 1);

    const e2 = manager.create(); // Should be ID 2
    try std.testing.expect(e2.id == 2);

    manager.destroy(e1); // Does nothing in simplified version
    // In a version with isAlive: try std.testing.expect(!manager.isAlive(e1));

    const e3 = manager.create(); // Should be ID 3 (no recycling yet)
    try std.testing.expect(e3.id == 3);

    std.log.info("EntityManager (simplified) test completed.", .{});
}

test "Entity Hashing and Equality" {
    const e1a = Entity.new(100);
    const e1b = Entity.new(100);
    const e2 = Entity.new(200);

    var map = std.AutoHashMap(Entity, i32).init(std.testing.allocator);
    defer map.deinit();

    try map.put(e1a, 1);
    try map.put(e2, 2);

    try std.testing.expect(map.contains(e1a));
    try std.testing.expect(map.contains(e1b)); // e1b should be equal to e1a
    try std.testing.expect(map.get(e1a).? == 1);
    try std.testing.expect(map.get(e1b).? == 1);
    try std.testing.expect(map.get(e2).? == 2);

    const removed_val = map.fetchRemove(e1a);
    try std.testing.expect(removed_val != null);
    try std.testing.expect(removed_val.?.value == 1);
    try std.testing.expect(!map.contains(e1a));

    std.log.info("Entity hashing/equality test completed.", .{});
}
