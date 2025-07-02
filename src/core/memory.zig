// src/core/memory.zig
// Optimized allocators and memory management utilities.

const std = @import("std");

// This file will contain custom allocators tailored for game development needs.
// Examples:
// - Arena allocator for frame-based allocations
// - Pool allocator for objects of the same size
// - Stack allocator for hierarchical allocations

// For now, we can define some common allocator interfaces or re-export std allocators
// with potential custom configurations or tracking.

pub const Allocator = std.mem.Allocator;

// Example: A simple Arena Allocator
// This is a very basic example. A production arena would have more features
// like alignment, ability to free all, etc.
pub const ArenaAllocator = struct {
    allocator: Allocator,
    arena: std.heap.ArenaAllocator,

    pub fn init(backing_allocator: Allocator) ArenaAllocator {
        return .{
            .allocator = backing_allocator,
            .arena = std.heap.ArenaAllocator.init(backing_allocator),
        };
    }

    pub fn deinit(self: *ArenaAllocator) void {
        self.arena.deinit();
    }

    pub fn reset(self: *ArenaAllocator) void {
        // This is a simplified reset. A true arena reset might involve
        // freeing all allocated memory or reusing the buffer.
        // std.heap.ArenaAllocator automatically frees all its allocations
        // when it's deinitialized. To "reset" it for reuse without deinit/reinit,
        // you'd typically deinit and then init again with the same backing allocator,
        // or manage its internal state if the implementation allows.
        // For this example, let's assume 'reset' means deinit and reinit.
        const backing = self.arena.child_allocator; // Save the original backing allocator
        self.arena.deinit();
        self.arena = std.heap.ArenaAllocator.init(backing);
    }

    pub fn allocator(self: *ArenaAllocator) Allocator {
        return self.arena.allocator();
    }
};

// Example: A simple Pool Allocator (conceptual)
// A real pool allocator would be more complex, managing fixed-size blocks.
// pub const PoolAllocator = struct {
//     // ... fields for managing memory pool ...
//     // item_size: usize,
//     // capacity: usize,
//     // memory_block: []u8,
//     // free_list: ?*Node,
//
//     pub fn init(item_size: usize, capacity: usize, backing_allocator: Allocator) !PoolAllocator {
//         // ... allocate memory block ...
//         // ... initialize free list ...
//         @panic("PoolAllocator not yet implemented");
//     }
//
//     pub fn deinit(self: *PoolAllocator) void {
//         // ... free memory block ...
//     }
//
//     pub fn alloc(self: *PoolAllocator) ?*anyopaque {
//         // ... allocate one item from pool ...
//         @panic("PoolAllocator.alloc not yet implemented");
//         return null;
//     }
//
//     pub fn free(self: *PoolAllocator, ptr: *anyopaque) void {
//         // ... return item to pool ...
//         @panic("PoolAllocator.free not yet implemented");
//     }
// };

test "ArenaAllocator basic usage" {
    const testing_allocator = std.testing.allocator;
    var arena_state = ArenaAllocator.init(testing_allocator);
    defer arena_state.deinit();

    const arena = arena_state.allocator();

    // Allocate some memory
    var data1 = try arena.alloc(u8, 10);
    try std.testing.expect(data1.len == 10);

    var data2 = try arena.create(i32);
    data2.* = 123;
    try std.testing.expect(data2.* == 123);

    // Reset the arena (deinitializes and reinitializes the underlying ArenaAllocator)
    // This means data1 and data2 are now invalid if not careful with std.heap.ArenaAllocator's behavior.
    // A more robust arena might offer different reset semantics.
    // For std.heap.ArenaAllocator, deinit frees all, so re-init starts fresh.
    arena_state.reset();
    const arena_after_reset = arena_state.allocator();

    // Allocate again after reset
    var data3 = try arena_after_reset.alloc(u8, 5);
    try std.testing.expect(data3.len == 5);

    // Note: std.heap.ArenaAllocator frees everything on deinit.
    // The 'reset' above calls deinit and then init.
}

test "default allocators" {
    // Ensure std allocators are accessible if needed
    const page_allocator = std.heap.page_allocator;
    var list = std.ArrayList(u8).init(page_allocator);
    try list.append('a');
    try std.testing.expect(list.items[0] == 'a');
    list.deinit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        try std.testing.expect(!leaked);
    }
    const gpa_allocator = gpa.allocator();
    var map = std.AutoHashMap(u32, u32).init(gpa_allocator);
    try map.put(1, 10);
    try std.testing.expect(map.get(1).? == 10);
    map.deinit();
}
