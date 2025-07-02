// src/ecs/components/transform.zig
// Defines the Transform component.

const std = @import("std");
const Vec3 = @import("../../math/vec3.zig").Vec3;
const Quaternion = @import("../../math/quaternion.zig").Quaternion;
const Mat4 = @import("../../math/mat4.zig").Mat4;

pub const TransformComponent = struct {
    position: Vec3 = Vec3.zero(),
    rotation: Quaternion = Quaternion.identity(),
    scale: Vec3 = Vec3.one(),

    // Optional: Cache for the local transformation matrix
    // mutable for caching, but conceptually represents the state of pos/rot/scale.
    // local_matrix: Mat4 = Mat4.identity(),
    // is_dirty: bool = true, // If local_matrix needs recalculation

    // Optional: Parent-child relationships
    // parent: ?Entity = null, // Entity is defined in ecs/entity.zig
    // children: std.ArrayList(Entity), // Requires Entity type

    // pub fn init(allocator: std.mem.Allocator) TransformComponent {
    //     return TransformComponent{
    //         .children = std.ArrayList(Entity).init(allocator),
    //     };
    // }

    // pub fn deinit(self: *TransformComponent) void {
    //     self.children.deinit();
    // }

    pub fn getLocalTransformMatrix(self: *const TransformComponent) Mat4 {
        // if (self.is_dirty) {
        //     self.local_matrix = Mat4.fromRotationTranslationScale(self.rotation, self.position, self.scale);
        //     self.is_dirty = false;
        // }
        // return self.local_matrix;
        // For non-caching version:
        return Mat4.fromRotationTranslationScale(self.rotation, self.position, self.scale);
    }

    // TODO: Add methods for world transform calculation if parenting is implemented.
    // pub fn getWorldTransformMatrix(self: *const TransformComponent, world: *const World) Mat4 {
    //     var transform = self.getLocalTransformMatrix();
    //     var current_parent = self.parent;
    //     while (current_parent) |parent_entity| {
    //         const parent_transform_comp = world.getComponent(parent_entity, TransformComponent);
    //         if (parent_transform_comp) |ptc| {
    //             transform = ptc.getLocalTransformMatrix().mul(transform);
    //             current_parent = ptc.parent;
    //         } else {
    //             break; // Parent doesn't have a transform component, chain broken.
    //         }
    //     }
    //     return transform;
    // }

    // --- Setters that would mark dirty for caching ---
    // pub fn setPosition(self: *TransformComponent, new_pos: Vec3) void {
    //     self.position = new_pos;
    //     self.is_dirty = true;
    // }
    // pub fn setRotation(self: *TransformComponent, new_rot: Quaternion) void {
    //     self.rotation = new_rot;
    //     self.is_dirty = true;
    // }
    // pub fn setScale(self: *TransformComponent, new_scale: Vec3) void {
    //     self.scale = new_scale;
    //     self.is_dirty = true;
    // }

    // --- Helper methods for common transformations ---
    pub fn translate(self: *TransformComponent, translation: Vec3) void {
        self.position = self.position.add(translation);
        // self.is_dirty = true;
    }

    pub fn rotate(self: *TransformComponent, axis: Vec3, angle_radians: f32) void {
        self.rotation = Quaternion.fromAxisAngle(axis, angle_radians).mul(self.rotation).normalize();
        // self.is_dirty = true;
    }

    pub fn lookAt(self: *TransformComponent, target: Vec3, world_up: Vec3) void {
        self.rotation = Quaternion.lookAt(self.position, target, world_up);
        // self.is_dirty = true;
    }
};

test "TransformComponent initialization and default values" {
    // const allocator = std.testing.allocator; // Needed if init/deinit uses allocator
    // var transform = TransformComponent.init(allocator);
    // defer transform.deinit();
    var transform = TransformComponent{}; // Using default struct initialization

    try std.testing.expect(transform.position.eql(Vec3.zero()));
    try std.testing.expect(transform.rotation.eql(Quaternion.identity()));
    try std.testing.expect(transform.scale.eql(Vec3.one()));
    // try std.testing.expect(transform.is_dirty == true); // If caching is used
    // try std.testing.expect(transform.parent == null);
    // try std.testing.expect(transform.children.items.len == 0);

    std.log.info("TransformComponent initialization test completed.", .{});
}

test "TransformComponent getLocalTransformMatrix" {
    var transform = TransformComponent{
        .position = Vec3.new(1, 2, 3),
        .rotation = Quaternion.fromAxisAngle(Vec3.y_axis(), std.math.pi / 2.0), // 90 deg around Y
        .scale = Vec3.new(2, 2, 2),
    };

    const matrix = transform.getLocalTransformMatrix();

    // Verify matrix components (this is complex and depends on Mat4.fromRotationTranslationScale)
    // For example, translation part should be (1,2,3) in m[12], m[13], m[14]
    try std.testing.expect(matrix.m[12] == 1.0);
    try std.testing.expect(matrix.m[13] == 2.0);
    try std.testing.expect(matrix.m[14] == 3.0);

    // Check scale effect (e.g. X-axis vector (1,0,0) transformed by matrix should have length 2)
    const x_axis_scaled = matrix.transformVector(Vec3.x_axis());
    try std.testing.expect(std.math.approxEqAbs(x_axis_scaled.length(), 2.0, 0.001));

    // Check rotation (e.g. X-axis (1,0,0) rotated 90 deg around Y becomes Z-axis (0,0,1) or (0,0,-1) depending on convention)
    // Mat4.fromRotationTranslationScale applies scale, then rotation, then translation.
    // So, (2,0,0) (scaled x-axis) rotated 90 deg around Y becomes (0,0,-2) for RHS, y-up.
    // Let's test a point transformation. Point (1,0,0) scaled is (2,0,0). Rotated 90 deg around Y is (0,0,-2). Translated is (1,2,1).
    const test_point = Vec3.new(1,0,0); // A point along the x-axis
    const transformed_point = matrix.transformPoint(test_point);
    // Expected: scale (1,0,0) to (2,0,0). Rotate (2,0,0) by 90 deg about Y to (0,0,-2). Translate to (1,2,1).
    try std.testing.expect(transformed_point.eqlApprox(Vec3.new(1.0, 2.0, 1.0), 0.001));


    std.log.info("TransformComponent getLocalTransformMatrix test completed.", .{});
}

test "TransformComponent helper methods" {
    var transform = TransformComponent{};
    transform.translate(Vec3.new(10, 5, -2));
    try std.testing.expect(transform.position.eql(Vec3.new(10,5,-2)));

    transform.rotate(Vec3.z_axis(), std.math.pi); // Rotate 180 deg around Z
    // Rotating identity quaternion by 180 deg around Z:
    // q = (cos(pi/2), 0,0,sin(pi/2)) = (0,0,0,1) (axis (0,0,1), angle pi)
    // Expected quaternion should be (w=0, x=0, y=0, z=1) or (w=0, x=0, y=0, z=-1)
    const expected_rot = Quaternion.fromAxisAngle(Vec3.z_axis(), std.math.pi);
    try std.testing.expect(transform.rotation.eqlApprox(expected_rot, 0.001));

    // Test lookAt
    transform.position = Vec3.zero();
    transform.lookAt(Vec3.new(0,0,-1), Vec3.y_axis()); // Look down negative Z (standard OpenGL view)
    // This should result in an identity rotation if camera faces -Z by default.
    // Quaternion.lookAt creates a rotation that would orient an object at `self.position`
    // to point its forward vector (commonly +Z or -Z) towards `target`.
    // If object's forward is +Z, looking at (0,0,-1) from (0,0,0) means 180 deg rot around Y.
    // If object's forward is -Z (like a camera), looking at (0,0,-1) means identity rot.
    // Quaternion.lookAt assumes object's initial forward is +Z.
    // So, to make +Z point to (0,0,-1), it's a 180-degree rotation around Y.
    const look_at_rot = Quaternion.fromAxisAngle(Vec3.y_axis(), std.math.pi);
    try std.testing.expect(transform.rotation.eqlApprox(look_at_rot, 0.001));

    std.log.info("TransformComponent helper methods test completed.", .{});
}
