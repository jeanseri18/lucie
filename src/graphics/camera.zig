// src/graphics/camera.zig
const std = @import("std");
const math = std.math;
const Vec3 = @import("../math/vec3.zig").Vec3;
const Mat4 = @import("../math/mat4.zig").Mat4;
const Quat = @import("../math/quat.zig").Quat;

// Forward declaration for Quat.fromLookRotation if it's to be part of Quat's API
// For now, defining it as a static function in this file for Camera's use.
fn quatFromLookRotation(forward_normalized: Vec3, up_normalized: Vec3) Quat;

pub const ProjectionType = enum {
    Perspective,
    Orthographic,
};

pub const Camera = struct {
    allocator: std.mem.Allocator,

    position: Vec3 = Vec3.zero,
    orientation: Quat = Quat.identity,

    projection_type: ProjectionType = .Perspective,
    fov_y_rad: f32 = math.degreesToRadians(f32, 60.0),
    aspect_ratio: f32 = 16.0 / 9.0,
    z_near: f32 = 0.1,
    z_far: f32 = 100.0,
    ortho_size: f32 = 10.0,

    pub fn init(allocator: std.mem.Allocator, pos: Vec3, target: Vec3, world_up: Vec3) Camera {
        var cam = Camera {
            .allocator = allocator,
            .position = pos,
            .orientation = Quat.identity, // Placeholder, lookAt will set it
        };
        cam.lookAt(target, world_up);
        return cam;
    }

    pub fn initDefault(allocator: std.mem.Allocator) Camera {
        // Default: looking at origin from +Z, world Y is up.
        return Camera.init(allocator, Vec3.init(0,0,3), Vec3.zero, Vec3.up);
    }

    pub fn getViewMatrix(self: *const Camera) Mat4 {
        // View matrix is Inverse(CameraWorldTransform)
        // CameraWorldTransform = Translate(position) * Rotate(orientation)
        // Inverse(Translate*Rotate) = Inverse(Rotate) * Inverse(Translate)
        // = Rotate(conjugate(orientation)) * Translate(-position)
        const rot_inv = self.orientation.conjugate().toMat4();
        const transl_inv = Mat4.translation(self.position.negate());
        return rot_inv.mul(transl_inv);
    }

    pub fn getProjectionMatrix(self: *const Camera) Mat4 {
        switch (self.projection_type) {
            .Perspective => return Mat4.perspective(self.fov_y_rad, self.aspect_ratio, self.z_near, self.z_far),
            .Orthographic => {
                const half_h = self.ortho_size / 2.0;
                const half_w = half_h * self.aspect_ratio;
                return Mat4.orthographic(-half_w, half_w, -half_h, half_h, self.z_near, self.z_far);
            },
        }
    }

    pub fn lookAt(self: *Camera, target: Vec3, world_up_hint: Vec3) void {
        // Camera's forward direction (-Z local) points towards target from eye.
        const forward_local_z = self.position.sub(target).normalized(); // This is +Z local if -Z view is target
        // If target is (0,0,0) and pos is (0,0,5), then forward_local_z is (0,0,1)
        // This means the camera's +Z axis in world space is (0,0,1).
        // The quatFromLookRotation expects the "forward" direction of the object itself.
        // If our camera's "forward" is its -Z axis, then we pass that.
        const cam_forward_world = target.sub(self.position).normalized(); // Direction camera is looking
        self.orientation = quatFromLookRotation(cam_forward_world, world_up_hint);
    }

    // Moves camera along its local axes (relative to its orientation)
    pub fn moveLocal(self: *Camera, delta_local: Vec3) void {
        // Rotate delta_local by camera's orientation to get world-space delta
        const delta_world = self.orientation.mulVec3(delta_local);
        self.position = self.position.add(delta_world);
    }

    // Moves camera along world axes
    pub fn moveWorld(self: *Camera, delta_world: Vec3) void {
        self.position = self.position.add(delta_world);
    }

    // FPS-style rotation: pitch around local X, yaw around world Y.
    pub fn rotateFps(self: *Camera, pitch_rad: f32, yaw_rad: f32) void {
        // Yaw around world UP vector
        const yaw_quat = Quat.fromAxisAngle(Vec3.up, yaw_rad);
        self.orientation = yaw_quat.mul(self.orientation); // Pre-multiply for world axis rotation

        // Pitch around local RIGHT vector
        // Local right is (1,0,0) rotated by current orientation
        const local_right = self.orientation.mulVec3(Vec3.right);
        const pitch_quat = Quat.fromAxisAngle(local_right, pitch_rad);
        self.orientation = self.orientation.mul(pitch_quat); // Post-multiply for local axis rotation

        self.orientation = self.orientation.normalized(); // Normalize after combined rotations
    }

    pub fn forward(self: *const Camera) Vec3 { return self.orientation.mulVec3(Vec3.forward); } // (0,0,-1) local
    pub fn right(self: *const Camera) Vec3 { return self.orientation.mulVec3(Vec3.right); }   // (1,0,0) local
    pub fn up(self: *const Camera) Vec3 { return self.orientation.mulVec3(Vec3.up); }       // (0,1,0) local
};

// Helper to create a quaternion that rotates to look in a specific direction.
// `forward_normalized`: The world-space direction the local +Z axis should point to.
// `up_hint_normalized`: A world-space "up" vector, used to establish roll.
// This function constructs a rotation that aligns local +Z with `forward_normalized`
// and local +Y as close as possible to `up_hint_normalized`.
fn quatFromLookRotation(forward_normalized: Vec3, up_hint_normalized: Vec3) Quat {
    const z_axis = forward_normalized; // Local +Z will align with this world direction

    var x_axis = up_hint_normalized.cross(z_axis);
    if (x_axis.lengthSquared() < 0.00001) { // up_hint and z_axis are collinear
        // If z_axis is (0,1,0) or (0,-1,0), cross with (1,0,0) to get a valid x_axis
        if (math.fabs(z_axis.y) > 0.9999) {
            x_axis = Vec3.right.cross(z_axis);
        } else { // Otherwise, cross with (0,1,0) to get a valid x_axis
            x_axis = Vec3.up.cross(z_axis);
        }
    }
    x_axis = x_axis.normalized();

    const y_axis = z_axis.cross(x_axis).normalized(); // Recalculate Y to ensure orthogonality

    // Now we have an orthonormal basis [x_axis, y_axis, z_axis] for the target orientation.
    // Convert this rotation basis to a quaternion.
    // This matrix M = [x_axis | y_axis | z_axis] rotates from basis vectors to world.
    // Standard algorithm for matrix to quaternion:
    const m00 = x_axis.x; const m01 = y_axis.x; const m02 = z_axis.x;
    const m10 = x_axis.y; const m11 = y_axis.y; const m12 = z_axis.y;
    const m20 = x_axis.z; const m21 = y_axis.z; const m22 = z_axis.z;

    const trace = m00 + m11 + m22;
    var qx:f32 = 0; var qy:f32 = 0; var qz:f32 = 0; var qw:f32 = 0;

    if (trace > 0.0) {
        var s = math.sqrt(trace + 1.0) * 2.0;
        qw = 0.25 * s;
        s = 1.0 / s;
        qx = (m21 - m12) * s;
        qy = (m02 - m20) * s;
        qz = (m10 - m01) * s;
    } else if ((m00 > m11) and (m00 > m22)) {
        var s = math.sqrt(1.0 + m00 - m11 - m22) * 2.0;
        qx = 0.25 * s;
        s = 1.0 / s;
        qw = (m21 - m12) * s;
        qy = (m01 + m10) * s;
        qz = (m02 + m20) * s;
    } else if (m11 > m22) {
        var s = math.sqrt(1.0 + m11 - m00 - m22) * 2.0;
        qy = 0.25 * s;
        s = 1.0 / s;
        qw = (m02 - m20) * s;
        qx = (m01 + m10) * s;
        qz = (m12 + m21) * s;
    } else {
        var s = math.sqrt(1.0 + m22 - m00 - m11) * 2.0;
        qz = 0.25 * s;
        s = 1.0 / s;
        qw = (m10 - m01) * s;
        qx = (m02 + m20) * s;
        qy = (m12 + m21) * s;
    }
    // The quaternion q=(qx,qy,qz,qw) rotates from identity to the new orientation.
    // If our Camera orientation means "rotation from world to camera's standard orientation (-Z fwd)",
    // then this calculated quat is correct.
    // If Camera orientation means "rotation from camera's standard to world", then we need conjugate.
    // Standard for storing object orientation is world_from_local. So this q is correct.
    return Quat.init(qx, qy, qz, qw).normalized();
}


test "Camera initialization and default values" {
    const allocator = std.testing.allocator;
    var cam = Camera.initDefault(allocator); // pos(0,0,3), target(0,0,0), up(0,1,0)

    // Default init looks at (0,0,0) from (0,0,3) with up (0,1,0).
    // Camera's forward direction (local -Z) should point along world -Z.
    // So, cam.forward() which is orientation * (0,0,-1) should be (0,0,-1).
    // This means orientation must be identity.
    try std.testing.expect(cam.position.equals(Vec3.init(0,0,3), 0.001));
    try std.testing.expect(cam.orientation.equals(Quat.identity, 0.001));
    try std.testing.expect(cam.forward().equals(Vec3.init(0,0,-1), 0.001));
}

test "Camera view matrix" {
    const allocator = std.testing.allocator;
    var cam = Camera.init(allocator, Vec3.init(0,0,5), Vec3.zero, Vec3.up);
    const view_mat = cam.getViewMatrix();
    const expected_view_mat = Mat4.lookAt(Vec3.init(0,0,5), Vec3.zero, Vec3.up);
    try std.testing.expect(view_mat.equals(expected_view_mat, 0.0001));

    // Test with a different orientation
    // Cam at origin, looking along +X, world Y is up.
    // Forward is (1,0,0). Up hint (0,1,0).
    cam.position = Vec3.zero;
    cam.lookAt(Vec3.init(1,0,0), Vec3.up);

    const view_mat2 = cam.getViewMatrix();
    const expected_view_mat2 = Mat4.lookAt(Vec3.zero, Vec3.init(1,0,0), Vec3.up);
    try std.testing.expect(view_mat2.equals(expected_view_mat2, 0.0001));
}

test "Camera projection matrix" {
    const allocator = std.testing.allocator;
    var cam = Camera.initDefault(allocator);
    cam.aspect_ratio = 16.0/9.0;
    cam.fov_y_rad = math.degreesToRadians(f32, 90.0);
    cam.z_near = 0.1;
    cam.z_far = 100.0;

    const proj_mat_p = cam.getProjectionMatrix();
    const expected_proj_p = Mat4.perspective(cam.fov_y_rad, cam.aspect_ratio, cam.z_near, cam.z_far);
    try std.testing.expect(proj_mat_p.equals(expected_proj_p, 0.0001));

    cam.projection_type = .Orthographic;
    cam.ortho_size = 10.0;
    const proj_mat_o = cam.getProjectionMatrix();
    const half_h = cam.ortho_size / 2.0;
    const half_w = half_h * cam.aspect_ratio;
    const expected_proj_o = Mat4.orthographic(-half_w, half_w, -half_h, half_h, cam.z_near, cam.z_far);
    try std.testing.expect(proj_mat_o.equals(expected_proj_o, 0.0001));
}

test "Camera movement and rotation" {
    const allocator = std.testing.allocator;
    var cam = Camera.initDefault(allocator); // (0,0,3) looking at (0,0,0), orientation=identity

    // Move local forward (-Z) by 1 unit. Cam forward is (0,0,-1).
    cam.moveLocal(Vec3.init(0,0,-1));
    try std.testing.expect(cam.position.equals(Vec3.init(0,0,2), 0.0001)); // (0,0,3) + (0,0,-1) = (0,0,2)

    // Rotate FPS style: yaw by 90 deg (pi/2) around world Y.
    cam.rotateFps(0, math.pi / 2.0);
    // Cam's local -Z (forward) should now point along world -X.
    // Cam's local +X (right) should now point along world +Z.
    try std.testing.expect(cam.forward().equals(Vec3.init(-1,0,0), 0.001));
    try std.testing.expect(cam.right().equals(Vec3.init(0,0,1), 0.001)); // Corrected: right is (0,0,1) not (0,0,-1)
                                                                      // because if fwd is -X, and up is Y, then right = up x fwd = Y x (-X) = +Z

    // Move local forward (-Z) by 1 unit. Current forward is (-1,0,0).
    cam.moveLocal(Vec3.init(0,0,-1)); // Moves by (-1,0,0) in world
    try std.testing.expect(cam.position.equals(Vec3.init(-1,0,2), 0.001)); // (0,0,2) + (-1,0,0) = (-1,0,2)

    // Move local right (+X) by 1 unit. Current right is (0,0,1).
    cam.moveLocal(Vec3.init(1,0,0)); // Moves by (0,0,1) in world
    try std.testing.expect(cam.position.equals(Vec3.init(-1,0,3), 0.001)); // (-1,0,2) + (0,0,1) = (-1,0,3)

    // Pitch up (around local right) by -pi/2 (look upwards)
    // Current local right is (0,0,1).
    cam.rotateFps(-math.pi/2.0, 0);
    // Forward was (-1,0,0). After pitching up around (0,0,1) by -90deg, forward should be (0,1,0) (world up)
    try std.testing.expect(cam.forward().equals(Vec3.init(0,1,0), 0.001));
}
