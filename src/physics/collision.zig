// src/physics/collision.zig
// Collision detection algorithms (narrowphase) and contact resolution.

const std = @import("std");
const Vec2 = @import("../math/vec2.zig").Vec2;
const Mat3 = @import("../math/mat3.zig").Mat3; // For transforming shapes
const Collider = @import("collider.zig").ColliderComponent;
const ColliderShape = @import("collider.zig").ColliderShape;
const RigidBody = @import("../ecs/components/rigidbody.zig").RigidBodyComponent;
const Transform = @import("../ecs/components/transform.zig").TransformComponent; // For entity positions/rotations

// Represents a contact point from a collision
pub const ContactPoint = struct {
    point: Vec2,          // Point of contact in world space
    normal: Vec2,         // Collision normal (from A to B) in world space
    penetration_depth: f32, // How much shapes are overlapping along the normal

    // Optional: Info for friction/restitution
    // relative_velocity_at_contact: Vec2,
    // effective_mass_normal: f32,
    // effective_mass_tangent: f32,
    // bias: f32, // For position correction (Baumgarte stabilization)
};

// Contains all contact points for a single collision pair (A and B)
pub const CollisionManifold = struct {
    // body_a: ?*RigidBody = null, // Pointer to RigidBody A (or its Entity ID)
    // body_b: ?*RigidBody = null, // Pointer to RigidBody B
    // transform_a: ?*Transform = null,
    // transform_b: ?*Transform = null,
    // collider_a: ?*Collider = null,
    // collider_b: ?*Collider = null,

    contacts: std.ArrayList(ContactPoint), // Max 1 or 2 for circle/box, up to N for polygons
    // For simplicity, fixed array for common cases (e.g., max 2 contact points for box-box)
    // contact_points: [2]ContactPoint,
    // contact_count: u8 = 0,

    // Combined material properties
    // restitution: f32 = 0.0,
    // friction: f32 = 0.0,

    allocator: std.mem.Allocator, // If contacts list allocates

    pub fn init(allocator_param: std.mem.Allocator) CollisionManifold {
        return CollisionManifold{
            .contacts = std.ArrayList(ContactPoint).init(allocator_param),
            .allocator = allocator_param,
        };
    }

    pub fn deinit(self: *CollisionManifold) void {
        self.contacts.deinit();
    }

    pub fn addContact(self: *CollisionManifold, point: Vec2, normal: Vec2, depth: f32) !void {
        // In some cases, keep only the deepest contact or manage multiple contacts carefully.
        // For box-box, there can be 1 or 2 contacts usually.
        // For this simple manifold, just add it.
        try self.contacts.append(.{ .point = point, .normal = normal, .penetration_depth = depth });
    }
};


// --- Narrowphase Collision Detection Functions ---
// These functions check for collision between two specific shapes, given their transforms.
// They return an optional CollisionManifold if a collision occurs.

// Circle vs Circle
pub fn checkCircleCircle(
    // allocator: std.mem.Allocator, // To create manifold if collision
    // c1_transform: *const Transform, c1_collider: *const Collider, // Circle 1
    // c2_transform: *const Transform, c2_collider: *const Collider, // Circle 2
    // For placeholder, pass shape data and positions directly
    pos1: Vec2, radius1: f32,
    pos2: Vec2, radius2: f32,
) ?CollisionManifold { // Simplified: returns bool for now, manifold is complex
    const distance_sq = pos1.distanceSq(pos2);
    const radii_sum = radius1 + radius2;
    if (distance_sq < radii_sum * radii_sum) {
        // Collision occurred
        // TODO: Calculate manifold (contact point, normal, depth)
        // Normal: (pos2 - pos1).normalize()
        // Depth: radii_sum - sqrt(distance_sq)
        // Contact point: pos1 + normal * radius1 (or a point on the intersection line)
        // For this placeholder, just indicate collision.
        // var manifold = CollisionManifold.init(allocator);
        // ... populate manifold ...
        // return manifold;
        return CollisionManifold.init(std.heap.page_allocator); // DUMMY return, leaks!
    }
    return null;
}

// Box vs Box (AABB vs AABB for simplicity here)
// A real OBB vs OBB is more complex (Separating Axis Theorem - SAT).
pub fn checkAABBAABB(
    // allocator: std.mem.Allocator,
    // box1_transform: *const Transform, box1_collider: *const Collider, // Box 1 (AABB assumed)
    // box2_transform: *const Transform, box2_collider: *const Collider, // Box 2
    // For placeholder, pass AABB data directly
    aabb1_min: Vec2, aabb1_max: Vec2,
    aabb2_min: Vec2, aabb2_max: Vec2,
) ?CollisionManifold { // Simplified: returns bool
    // Check for overlap on X axis
    if (aabb1_max.x < aabb2_min.x or aabb1_min.x > aabb2_max.x) return null;
    // Check for overlap on Y axis
    if (aabb1_max.y < aabb2_min.y or aabb1_min.y > aabb2_max.y) return null;

    // Collision occurred
    // TODO: Calculate manifold (contact point, normal, depth)
    // This involves finding the axis of minimum penetration.
    // For this placeholder, indicate collision.
    return CollisionManifold.init(std.heap.page_allocator); // DUMMY return, leaks!
}

// Circle vs Box (AABB for box)
pub fn checkCircleAABB(
    // allocator: std.mem.Allocator,
    // circle_transform: *const Transform, circle_collider: *const Collider,
    // box_transform: *const Transform, box_collider: *const Collider,
    circle_pos: Vec2, circle_radius: f32,
    box_min: Vec2, box_max: Vec2,
) ?CollisionManifold { // Simplified: returns bool
    // Find closest point on AABB to circle's center
    const closest_x = std.math.clamp(circle_pos.x, box_min.x, box_max.x);
    const closest_y = std.math.clamp(circle_pos.y, box_min.y, box_max.y);
    const closest_point_on_aabb = Vec2.new(closest_x, closest_y);

    if (circle_pos.distanceSq(closest_point_on_aabb) < circle_radius * circle_radius) {
        // Collision occurred
        // TODO: Manifold calculation
        return CollisionManifold.init(std.heap.page_allocator); // DUMMY return, leaks!
    }
    return null;
}

// Main dispatch function for collision checking based on collider types.
// This is a simplified version. A real engine might use a dispatch table or function matrix.
pub fn checkCollision(
    allocator: std.mem.Allocator, // For manifold if collision
    collider_a: *const Collider, transform_a: *const Transform,
    collider_b: *const Collider, transform_b: *const Transform,
) ?CollisionManifold {
    _ = allocator; // Mark as used for now. Real functions above would use it.

    // Get world positions and transformed shapes
    // This is where shape.offset and entity transform (pos, rot, scale) are applied.
    // For simplicity, assuming shapes are already in world space or simple to transform.
    // E.g., Circle world_pos = transform_a.position + collider_a.offset;
    // Box world_aabb = collider_a.shape.Box.getLocalAABB().transform(transform_a.getLocalMatrix());
    // This part is complex and depends on math library capabilities.

    // Placeholder logic using simplified direct parameters for now.
    // This requires getting specific shape data and world positions.
    const shape_a = collider_a.shape;
    const shape_b = collider_b.shape;
    const pos_a = transform_a.position.toVec2().add(collider_a.offset); // Assuming Vec3.toVec2() if needed
    const pos_b = transform_b.position.toVec2().add(collider_b.offset);

    switch (shape_a) {
        .Circle => |circle_a_data| {
            switch (shape_b) {
                .Circle => |circle_b_data| {
                    return checkCircleCircle(pos_a, circle_a_data.radius, pos_b, circle_b_data.radius);
                },
                .Box => |box_b_data| {
                    // Need world AABB for box_b
                    const box_b_world_min = pos_b.sub(box_b_data.half_extents); // Simplified AABB in world
                    const box_b_world_max = pos_b.add(box_b_data.half_extents);
                    return checkCircleAABB(pos_a, circle_a_data.radius, box_b_world_min, box_b_world_max);
                },
                .Polygon => |_| return null, // Polygon checks not implemented
            }
        },
        .Box => |box_a_data| {
             const box_a_world_min = pos_a.sub(box_a_data.half_extents);
             const box_a_world_max = pos_a.add(box_a_data.half_extents);
            switch (shape_b) {
                .Circle => |circle_b_data| {
                    return checkCircleAABB(pos_b, circle_b_data.radius, box_a_world_min, box_a_world_max);
                },
                .Box => |box_b_data| {
                    const box_b_world_min = pos_b.sub(box_b_data.half_extents);
                    const box_b_world_max = pos_b.add(box_b_data.half_extents);
                    return checkAABBAABB(box_a_world_min, box_a_world_max, box_b_world_min, box_b_world_max);
                },
                .Polygon => |_| return null,
            }
        },
        .Polygon => |_| return null, // Polygon checks not implemented
    }
    return null;
}


// --- Collision Resolution Functions ---
// These modify RigidBody velocities and/or Transform positions based on a CollisionManifold.

// Resolve velocity constraints (impulses for bounce and friction)
pub fn resolveVelocity(
    // manifold: *const CollisionManifold,
    // rb_a: *RigidBody, rb_b: *RigidBody, // Mutable, as velocities change
    // dt: f32, // Timestep, for Baumgarte stabilization if used
) void {
    // For each contact point in manifold:
    // 1. Calculate relative velocity at contact point.
    // 2. Calculate impulse needed to prevent penetration (normal impulse).
    //    - Takes into account masses, inertia, contact normal, restitution.
    // 3. Apply normal impulse to rb_a and rb_b velocities (linear and angular).
    // 4. Calculate friction impulse (tangent impulse).
    //    - Based on normal impulse, friction coefficients, relative tangent velocity.
    // 5. Apply friction impulse.
    // This is a core part of a physics solver (e.g., sequential impulses).
    // Placeholder for now.
    // _ = manifold; _ = rb_a; _ = rb_b; _ = dt;
}

// Resolve position constraints (correct interpenetration directly)
pub fn resolvePosition(
    // manifold: *const CollisionManifold,
    // transform_a: *Transform, transform_b: *Transform, // Mutable
    // rb_a: *const RigidBody, rb_b: *const RigidBody, // For mass properties (inv_mass)
) void {
    // For each contact point with penetration_depth > threshold:
    // 1. Calculate position correction amount based on penetration_depth and inverse masses.
    //    (e.g., move bodies apart along contact normal by `depth * correction_factor`).
    // 2. Apply correction to transform_a.position and transform_b.position.
    //    - Distribute correction based on inv_mass (lighter body moves more).
    //    - Ensure static bodies are not moved.
    // This is a simpler correction than impulse-based, often used to fix "sinking".
    // Placeholder for now.
    // _ = manifold; _ = transform_a; _ = transform_b; _ = rb_a; _ = rb_b;
}


test "Collision detection function placeholders" {
    // These tests are very basic as the functions are placeholders.
    // They mainly check if the functions can be called and return expected nulls.
    // A real test would require proper manifold generation and checking.
    const allocator = std.testing.allocator; // For manifold if returned

    // Circle vs Circle (no collision)
    var m1 = checkCircleCircle(Vec2.new(0,0), 1.0, Vec2.new(10,0), 1.0);
    if (m1) |*manifold| manifold.deinit(); // Clean up dummy manifold
    try std.testing.expect(m1 == null);

    // Circle vs Circle (collision)
    var m2 = checkCircleCircle(Vec2.new(0,0), 1.0, Vec2.new(1,0), 1.0);
    if (m2) |*manifold| manifold.deinit();
    try std.testing.expect(m2 != null); // Dummy manifold returned

    // AABB vs AABB (no collision)
    var m3 = checkAABBAABB(Vec2.new(0,0), Vec2.new(1,1), Vec2.new(5,5), Vec2.new(6,6));
    if (m3) |*manifold| manifold.deinit();
    try std.testing.expect(m3 == null);

    // AABB vs AABB (collision)
    var m4 = checkAABBAABB(Vec2.new(0,0), Vec2.new(2,2), Vec2.new(1,1), Vec2.new(3,3));
    if (m4) |*manifold| manifold.deinit();
    try std.testing.expect(m4 != null);

    // Circle vs AABB (no collision)
    var m5 = checkCircleAABB(Vec2.new(5,0), 1.0, Vec2.new(0,0), Vec2.new(2,2));
    if (m5) |*manifold| manifold.deinit();
    try std.testing.expect(m5 == null);

    // Circle vs AABB (collision)
    var m6 = checkCircleAABB(Vec2.new(1.5, 0.5), 1.0, Vec2.new(0,0), Vec2.new(2,2));
    if (m6) |*manifold| manifold.deinit();
    try std.testing.expect(m6 != null);

    std.log.info("Collision detection placeholder tests completed.", .{});
    _ = allocator; // To mark as used if no manifolds were created.
}

test "CollisionManifold operations" {
    const allocator = std.testing.allocator;
    var manifold = CollisionManifold.init(allocator);
    defer manifold.deinit();

    try std.testing.expect(manifold.contacts.items.len == 0);

    try manifold.addContact(Vec2.new(1,1), Vec2.new(0,-1), 0.5);
    try std.testing.expect(manifold.contacts.items.len == 1);
    try std.testing.expect(manifold.contacts.items[0].penetration_depth == 0.5);

    try manifold.addContact(Vec2.new(2,2), Vec2.new(1,0), 0.2);
    try std.testing.expect(manifold.contacts.items.len == 2);

    std.log.info("CollisionManifold operations test completed.", .{});
}

// Note: The checkCollision dispatch function is very basic and needs actual transform application
// for shape data to be in world space before calling individual shape-pair checkers.
// The individual checkers (circle-circle etc.) are also placeholders for manifold calculation.
// This file lays out the structure for these future implementations.
