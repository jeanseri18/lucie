// src/physics/collider.zig
// Defines collider shapes for collision detection.

const std = @import("std");
const Vec2 = @import("../math/vec2.zig").Vec2; // Assuming 2D shapes for now
const Mat3 = @import("../math/mat3.zig").Mat3; // For transforming shapes (2D affine transform)
// const AABB = @import("../math/aabb.zig").AABB2D; // If AABB is defined elsewhere

// Axis-Aligned Bounding Box (2D)
// Often part of a math library, but can be here if specific to physics colliders.
pub const AABB = struct {
    min: Vec2 = Vec2.new(std.math.floatMax(f32), std.math.floatMax(f32)),
    max: Vec2 = Vec2.new(std.math.floatMin(f32), std.math.floatMin(f32)),

    pub fn fromCenterHalfExtents(center: Vec2, half_extents: Vec2) AABB {
        return AABB{
            .min = center.sub(half_extents),
            .max = center.add(half_extents),
        };
    }

    pub fn fromMinMax(min_pt: Vec2, max_pt: Vec2) AABB {
        return AABB{ .min = min_pt, .max = max_pt };
    }

    pub fn getCenter(self: AABB) Vec2 {
        return self.min.add(self.max).scale(0.5);
    }

    pub fn getHalfExtents(self: AABB) Vec2 {
        return self.max.sub(self.min).scale(0.5);
    }

    pub fn getSize(self: AABB) Vec2 {
        return self.max.sub(self.min);
    }

    pub fn overlaps(self: AABB, other: AABB) bool {
        if (self.max.x < other.min.x or self.min.x > other.max.x) return false;
        if (self.max.y < other.min.y or self.min.y > other.max.y) return false;
        return true;
    }

    // TODO: Transform AABB by a matrix (results in a new, larger AABB enclosing the transformed original)
    // pub fn transform(self: AABB, matrix: Mat3) AABB { ... }
};


// Different types of collider shapes
pub const ColliderShapeType = enum {
    Circle,
    Box,      // Can be AABB (Axis-Aligned) or OBB (Oriented Bounding Box)
    Polygon,  // Convex polygon
    // Capsule,
    // Segment, (Line segment)
    // Point,
};

// Represents the geometric shape of a collider.
// This is a tagged union.
pub const ColliderShape = union(ColliderShapeType) {
    Circle: struct {
        radius: f32,
        // offset: Vec2 = Vec2.zero(), // Offset from RigidBody's origin
    },
    Box: struct { // Represents half-extents for a box centered at RigidBody's origin + offset
        half_extents: Vec2,
        // offset: Vec2 = Vec2.zero(),
    },
    Polygon: struct { // Convex polygon defined by vertices relative to RigidBody's origin + offset
        vertices: std.ArrayList(Vec2), // Must be ordered (e.g., clockwise) and convex.
        // offset: Vec2 = Vec2.zero(),
        // Note: ArrayList here means Polygon shape itself allocates.
        // For ECS components, it's often better if shapes are POD or handles to shared shape data.
        // For simplicity, allowing allocation here.

        // pub fn deinit(self: *@This()) void { self.vertices.deinit(); } // If it owned vertices list
    },

    // Common method to get AABB (in local space of the collider, before transform)
    pub fn getLocalAABB(self: ColliderShape) AABB {
        return switch (self) {
            .Circle => |c| AABB.fromCenterHalfExtents(Vec2.zero(), Vec2.new(c.radius, c.radius)),
            .Box => |b| AABB.fromCenterHalfExtents(Vec2.zero(), b.half_extents),
            .Polygon => |p| {
                if (p.vertices.items.len == 0) return AABB{};
                var min_pt = p.vertices.items[0];
                var max_pt = p.vertices.items[0];
                for (p.vertices.items) |v| {
                    min_pt.x = std.math.min(min_pt.x, v.x);
                    min_pt.y = std.math.min(min_pt.y, v.y);
                    max_pt.x = std.math.max(max_pt.x, v.x);
                    max_pt.y = std.math.max(max_pt.y, v.y);
                }
                return AABB.fromMinMax(min_pt, max_pt);
            },
        };
    }
};

// The Collider component that would be attached to an ECS entity.
// It holds the shape and other properties like material, sensor status.
pub const ColliderComponent = struct {
    shape: ColliderShape,

    // Offset of the shape relative to the RigidBody/TransformComponent's origin.
    offset: Vec2 = Vec2.zero(),

    // Physics material properties (can also be on RigidBody or separate Material component)
    // If not here, physics system might look for them on RigidBody or use defaults.
    // restitution: f32 = 0.5,
    // friction: f32 = 0.5,

    is_sensor: bool = false, // If true, detects collisions but doesn't cause physical response (e.g., triggers)

    // Collision filtering (e.g., layers, masks)
    // collision_layer: u32 = 1,
    // collision_mask: u32 = 0xFFFFFFFF,

    // Optional: User data pointer or ID
    // user_data: ?*anyopaque = null,

    // If ColliderShape.Polygon allocates, ColliderComponent needs allocator and deinit.
    allocator: ?std.mem.Allocator = null, // Only needed if shape itself allocates (like Polygon)

    pub fn init(allocator_opt: ?std.mem.Allocator, shape_param: ColliderShape) ColliderComponent {
        var self = ColliderComponent {
            .shape = shape_param,
            .allocator = allocator_opt,
        };
        // If shape is Polygon and needs its list initialized with the component's allocator:
        // if (self.shape == .Polygon and self.allocator != null) {
        //    self.shape.Polygon.vertices = std.ArrayList(Vec2).init(self.allocator.?);
        // }
        // This assumes shape_param is passed by value and if it's a Polygon, its list is already init'd or moved.
        return self;
    }

    pub fn deinit(self: *ColliderComponent) void {
        // If the shape itself owns allocated memory (e.g. Polygon.vertices)
        // and was initialized with self.allocator.
        if (self.shape == .Polygon and self.allocator != null) {
            // This is tricky. If shape.Polygon.vertices was init'd with its own allocator,
            // this deinit needs to call that.
            // If it was intended to use self.allocator, it should've been init'd with it.
            // For now, assume Polygon vertices are managed externally or by value for simple cases.
            // Or, if Polygon shape has a deinit method:
            // if (self.shape == .Polygon) self.shape.Polygon.deinit();
        }
    }

    // Calculate the world-space AABB of this collider given its entity's transform.
    // `entity_transform` is Mat4 from TransformComponent.getLocalTransformMatrix().
    // For 2D, this would be a Mat3 (2x2 rotation/scale + 2x1 translation).
    // pub fn getWorldAABB(self: *const ColliderComponent, entity_transform: Mat4) AABB {
    //    const local_aabb = self.shape.getLocalAABB();
    //    // Apply self.offset to local_aabb points, then transform by entity_transform.
    //    // This requires AABB.transform() method.
    //    // Placeholder:
    //    _ = entity_transform;
    //    return local_aabb; // This is incorrect, needs transform
    // }
};

test "AABB operations" {
    const center = Vec2.new(10, 20);
    const half_extents = Vec2.new(5, 10);
    const aabb1 = AABB.fromCenterHalfExtents(center, half_extents);

    try std.testing.expect(aabb1.min.x == 5.0 and aabb1.min.y == 10.0);
    try std.testing.expect(aabb1.max.x == 15.0 and aabb1.max.y == 30.0);
    try std.testing.expect(aabb1.getCenter().eql(center));
    try std.testing.expect(aabb1.getHalfExtents().eql(half_extents));
    try std.testing.expect(aabb1.getSize().eql(half_extents.scale(2.0)));

    const aabb2 = AABB.fromMinMax(Vec2.new(12, 25), Vec2.new(20, 35)); // Overlaps aabb1
    const aabb3 = AABB.fromMinMax(Vec2.new(0, 0), Vec2.new(4, 9));    // Does not overlap aabb1

    try std.testing.expect(aabb1.overlaps(aabb2));
    try std.testing.expect(!aabb1.overlaps(aabb3));
    try std.testing.expect(aabb2.overlaps(aabb1)); // Overlap is symmetric

    std.log.info("AABB operations test completed.", .{});
}

test "ColliderShape getLocalAABB" {
    // Circle
    const circle_shape = ColliderShape{ .Circle = .{ .radius = 10.0 } };
    const circle_aabb = circle_shape.getLocalAABB();
    try std.testing.expect(circle_aabb.min.eql(Vec2.new(-10, -10)));
    try std.testing.expect(circle_aabb.max.eql(Vec2.new(10, 10)));

    // Box
    const box_shape = ColliderShape{ .Box = .{ .half_extents = Vec2.new(5, 15) } };
    const box_aabb = box_shape.getLocalAABB();
    try std.testing.expect(box_aabb.min.eql(Vec2.new(-5, -15)));
    try std.testing.expect(box_aabb.max.eql(Vec2.new(5, 15)));

    // Polygon (requires allocator for vertices list if not temporary)
    // For test, can use a temporary list.
    var temp_poly_verts = std.ArrayList(Vec2).init(std.testing.allocator);
    defer temp_poly_verts.deinit();
    try temp_poly_verts.appendSlice(&[_]Vec2{
        Vec2.new(-1, -1), Vec2.new(1, -1), Vec2.new(0, 1),
    });
    const polygon_shape = ColliderShape{ .Polygon = .{ .vertices = temp_poly_verts } };
    const polygon_aabb = polygon_shape.getLocalAABB();
    try std.testing.expect(polygon_aabb.min.eql(Vec2.new(-1, -1)));
    try std.testing.expect(polygon_aabb.max.eql(Vec2.new(1, 1)));

    std.log.info("ColliderShape getLocalAABB test completed.", .{});
}

test "ColliderComponent initialization" {
    const allocator = std.testing.allocator; // For Polygon if it allocates

    // Circle Collider
    const circle_shape = ColliderShape{ .Circle = .{ .radius = 5.0 } };
    var circle_collider = ColliderComponent.init(null, circle_shape); // No allocator needed for Circle shape
    defer circle_collider.deinit(); // Deinit is trivial if no allocations

    try std.testing.expect(circle_collider.shape == .Circle);
    try std.testing.expect(circle_collider.shape.Circle.radius == 5.0);
    try std.testing.expect(circle_collider.offset.eql(Vec2.zero()));
    try std.testing.expect(circle_collider.is_sensor == false);

    // Box Collider
    const box_shape = ColliderShape{ .Box = .{ .half_extents = Vec2.new(2,3) } };
    var box_collider = ColliderComponent.init(null, box_shape);
    defer box_collider.deinit();
    try std.testing.expect(box_collider.shape.Box.half_extents.eql(Vec2.new(2,3)));

    // Polygon Collider (if it manages its own vertex list memory)
    // This part is tricky depending on how Polygon.vertices is managed.
    // If ColliderComponent.init takes ownership or copies, then allocator might be needed.
    // For current placeholder, assume Polygon vertices are managed externally or simple.
    // If shape is passed by value, the ArrayList in Polygon is also copied/moved.
    // If that ArrayList was init'd with an allocator, its deinit is important.
    // The ColliderComponent.deinit placeholder needs to be aware of this.
    // For this test, let's assume the shape is simple and doesn't require complex deinit logic in ColliderComponent.

    std.log.info("ColliderComponent initialization test completed.", .{});
}
