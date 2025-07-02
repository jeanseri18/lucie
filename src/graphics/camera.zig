// src/graphics/camera.zig
// Camera system (2D and/or 3D).

const std = @import("std");
const Mat4 = @import("../math/mat4.zig").Mat4;
const Vec2 = @import("../math/vec2.zig").Vec2;
const Vec3 = @import("../math/vec3.zig").Vec3;

pub const CameraProjectionType = enum {
    Orthographic,
    Perspective,
};

pub const Camera = struct {
    projection_type: CameraProjectionType = .Orthographic,

    position: Vec3 = Vec3.zero(),
    rotation: Vec3 = Vec3.zero(), // Euler angles (pitch, yaw, roll) or use Quaternion
    // orientation: Quaternion = Quaternion.identity(), // Alternative to Euler for rotation

    // For Perspective projection
    fov_y_degrees: f32 = 70.0, // Field of view in Y direction, in degrees
    aspect_ratio: f32 = 16.0 / 9.0, // Width / Height
    near_plane: f32 = 0.1,
    far_plane: f32 = 1000.0,

    // For Orthographic projection
    ortho_size: f32 = 10.0, // Represents half height (e.g. 10 units from center to top)
    // ortho_left, ortho_right, ortho_bottom, ortho_top can also be used for more control.

    // Cached matrices
    view_matrix: Mat4 = Mat4.identity(),
    projection_matrix: Mat4 = Mat4.identity(),
    view_projection_matrix: Mat4 = Mat4.identity(),

    is_dirty: bool = true, // Flag to recompute matrices when properties change

    pub fn initPerspective(
        pos: Vec3,
        fov_y_deg: f32,
        aspect: f32,
        near_p: f32,
        far_p: f32,
    ) Camera {
        var cam = Camera{
            .projection_type = .Perspective,
            .position = pos,
            .fov_y_degrees = fov_y_deg,
            .aspect_ratio = aspect,
            .near_plane = near_p,
            .far_plane = far_p,
        };
        cam.recalculateMatrices();
        return cam;
    }

    pub fn initOrthographic(
        pos: Vec3,
        size: f32, // Half height of the view area
        aspect: f32,
        near_p: f32, // Typically -1 or small negative for 2D
        far_p: f32,  // Typically 1 or small positive for 2D
    ) Camera {
        var cam = Camera{
            .projection_type = .Orthographic,
            .position = pos,
            .ortho_size = size,
            .aspect_ratio = aspect,
            .near_plane = near_p, // Ortho near/far define the depth range
            .far_plane = far_p,
        };
        cam.recalculateMatrices();
        return cam;
    }

    // Call this when camera properties (position, rotation, fov, etc.) change
    pub fn setDirty(self: *Camera) void {
        self.is_dirty = true;
    }

    pub fn update(self: *Camera) void {
        if (self.is_dirty) {
            self.recalculateMatrices();
            self.is_dirty = false;
        }
    }

    fn recalculateMatrices(self: *Camera) void {
        // Recalculate View Matrix
        // This is a simplified view matrix calculation.
        // A full implementation would use lookAt or build from rotation (quaternion or Euler).
        // Assuming a simple FPS-style camera for now (yaw and pitch only, no roll).
        const pitch = self.rotation.x; // Rotation around X-axis
        const yaw = self.rotation.y;   // Rotation around Y-axis

        // Direction vectors
        var front: Vec3 = undefined;
        front.x = std.math.cos(yaw) * std.math.cos(pitch);
        front.y = std.math.sin(pitch);
        front.z = std.math.sin(yaw) * std.math.cos(pitch);
        front = front.normalize();

        // For a simple lookAt, if we define a target point:
        // const target = self.position.add(front);
        // self.view_matrix = Mat4.lookAt(self.position, target, Vec3.up());
        // Or, build the view matrix manually (inverse of camera's world transform)
        // For now, let's use a simplified translation and rotation.
        // This is a common simplification for 2D or basic 3D view matrices.
        // More robust: Mat4.translation(self.position.negate()).mul(Mat4.fromEulerAngles(-self.rotation.x, -self.rotation.y, -self.rotation.z));
        // Or using lookAt properly is better for 3D.
        // For a 2D orthographic camera, view matrix is often just translation:
        if (self.projection_type == .Orthographic) {
             // For 2D, position.z might control layering if near/far are wide enough.
             // Typically, a 2D camera's view matrix inverts its X and Y position.
            self.view_matrix = Mat4.translation(Vec3.new(-self.position.x, -self.position.y, -self.position.z));
            // If rotation is needed for a 2D camera (e.g. top-down rotated view):
            // self.view_matrix = Mat4.rotationZ(-self.rotation.z).mul(Mat4.translation(Vec3.new(-self.position.x, -self.position.y, 0)));
        } else { // Perspective
            // Using a proper lookAt for 3D perspective:
            const world_up = Vec3.up();
            const cam_right = world_up.cross(front).normalize();
            const cam_up = front.cross(cam_right).normalize(); // Recalculate up vector to be orthogonal
            self.view_matrix = Mat4.lookAtRh(self.position, self.position.add(front), cam_up);
        }


        // Recalculate Projection Matrix
        switch (self.projection_type) {
            .Orthographic => {
                const half_width = self.ortho_size * self.aspect_ratio;
                const half_height = self.ortho_size;
                self.projection_matrix = Mat4.orthoRhZo(
                    -half_width, half_width,    // left, right
                    -half_height, half_height,  // bottom, top
                    self.near_plane, self.far_plane,
                );
                // Common alternative for pixel-perfect 2D (origin top-left):
                // Mat4.ortho(0, screen_width, screen_height, 0, self.near_plane, self.far_plane);
            },
            .Perspective => {
                self.projection_matrix = Mat4.perspectiveRhZo(
                    std.math.degreesToRadians(self.fov_y_degrees),
                    self.aspect_ratio,
                    self.near_plane,
                    self.far_plane,
                );
            },
        }

        self.view_projection_matrix = self.projection_matrix.mul(self.view_matrix);
    }

    pub fn getViewMatrix(self: *Camera) Mat4 {
        if (self.is_dirty) self.update();
        return self.view_matrix;
    }

    pub fn getProjectionMatrix(self: *Camera) Mat4 {
        if (self.is_dirty) self.update();
        return self.projection_matrix;
    }

    pub fn getViewProjectionMatrix(self: *Camera) Mat4 {
        if (self.is_dirty) self.update();
        return self.view_projection_matrix;
    }

    // Movement examples (would typically be in a CameraController or game logic)
    pub fn moveForward(self: *Camera, amount: f32) void {
        // This requires calculating the camera's forward vector based on rotation
        // For simplicity, if just moving along world axes: self.position.z -= amount;
        // Proper forward based on yaw/pitch:
        const pitch = self.rotation.x;
        const yaw = self.rotation.y;
        var direction: Vec3 = undefined;
        direction.x = std.math.cos(yaw) * std.math.cos(pitch);
        direction.y = std.math.sin(pitch); // If you want to move "up/down" with pitch
        // direction.y = 0; // If you want to move only on XZ plane based on yaw
        direction.z = std.math.sin(yaw) * std.math.cos(pitch);
        self.position = self.position.add(direction.scale(amount));
        self.setDirty();
    }
    pub fn moveRight(self: *Camera, amount: f32) void {
        // Requires calculating camera's right vector
        const pitch = self.rotation.x;
        const yaw = self.rotation.y;
        var forward: Vec3 = .{
            .x = std.math.cos(yaw) * std.math.cos(pitch),
            .y = std.math.sin(pitch),
            .z = std.math.sin(yaw) * std.math.cos(pitch),
        };
        const right = forward.cross(Vec3.up()).normalize(); // Assuming world up is (0,1,0)
        self.position = self.position.add(right.scale(amount));
        self.setDirty();
    }
    pub fn moveUp(self: *Camera, amount: f32) void {
        self.position.y += amount; // Moves along world Y axis
        // If you want to move along camera's local up:
        // const pitch = self.rotation.x;
        // const yaw = self.rotation.y;
        // var forward: Vec3 = .{ .x = std.math.cos(yaw) * std.math.cos(pitch), .y = std.math.sin(pitch), .z = std.math.sin(yaw) * std.math.cos(pitch) };
        // const right = forward.cross(Vec3.up()).normalize();
        // const local_up = right.cross(forward).normalize();
        // self.position = self.position.add(local_up.scale(amount));
        self.setDirty();
    }

    pub fn rotate(self: *Camera, pitch_delta_deg: f32, yaw_delta_deg: f32) void {
        self.rotation.x += std.math.degreesToRadians(pitch_delta_deg);
        self.rotation.y += std.math.degreesToRadians(yaw_delta_deg);
        // Clamp pitch to avoid gimbal lock issues or flipping upside down
        const max_pitch = std.math.pi / 2.0 - 0.01; // Just under 90 degrees
        self.rotation.x = std.math.clamp(self.rotation.x, -max_pitch, max_pitch);
        self.setDirty();
    }

};

test "Camera initialization and matrix calculation" {
    // Perspective Camera
    var p_cam = Camera.initPerspective(Vec3.new(0,0,3), 70.0, 16.0/9.0, 0.1, 100.0);
    p_cam.update(); // Initial update

    try std.testing.expect(p_cam.projection_type == .Perspective);
    // Basic check: view matrix should reflect camera position (e.g. translate by -pos.z in m[14])
    // This depends heavily on the Mat4.lookAt implementation.
    // For a camera at (0,0,3) looking at (0,0,0) with up (0,1,0),
    // the view matrix should translate Z by -3.
    // Mat4 stores in column-major order typically. view_matrix.m[14] is Z translation.
    // If Mat4.lookAtRh correctly implemented:
    // For position (0,0,3), target (0,0,0), up (0,1,0)
    // zaxis = (pos - target).norm() = (0,0,1)
    // xaxis = up.cross(zaxis).norm() = (1,0,0)
    // yaxis = zaxis.cross(xaxis).norm() = (0,1,0)
    // view matrix:
    // xaxis.x, yaxis.x, zaxis.x, 0
    // xaxis.y, yaxis.y, zaxis.y, 0
    // xaxis.z, yaxis.z, zaxis.z, 0
    // -dot(xaxis,pos), -dot(yaxis,pos), -dot(zaxis,pos), 1
    // So, m[12] = 0, m[13] = 0, m[14] = -3
    try std.testing.expect(p_cam.view_matrix.m[14] == -3.0); // Check Z translation part

    // Orthographic Camera
    var o_cam = Camera.initOrthographic(Vec3.new(10,20,0), 100.0, 800.0/600.0, -1.0, 1.0);
    o_cam.update();
    try std.testing.expect(o_cam.projection_type == .Orthographic);
    // View matrix for ortho is simpler: translates by -pos
    try std.testing.expect(o_cam.view_matrix.m[12] == -10.0); // Check X translation
    try std.testing.expect(o_cam.view_matrix.m[13] == -20.0); // Check Y translation

    // Test dirty flag and update
    o_cam.position.x = 50.0;
    o_cam.setDirty();
    try std.testing.expect(o_cam.is_dirty);
    _ = o_cam.getViewProjectionMatrix(); // This should trigger update
    try std.testing.expect(!o_cam.is_dirty);
    try std.testing.expect(o_cam.view_matrix.m[12] == -50.0);

    std.log.info("Camera test completed.", .{});
}

test "Camera movement and rotation" {
    var cam = Camera.initPerspective(Vec3.zero(), 70.0, 1.0, 0.1, 100.0);

    cam.moveForward(10.0); // Moves along -Z if default rotation is (0,0,0) looking down -Z
    // Default front vector from recalculateMatrices with (0,0,0) rotation is (1,0,0) (cos(0)cos(0), sin(0), sin(0)cos(0))
    // This is not looking down -Z. A typical setup would have yaw = -PI/2 or PI/2 to look along Z.
    // Let's adjust initial rotation or test based on current forward.
    // If yaw is 0, forward is +X. So moveForward(10) moves to (10,0,0).
    // Let's assume a default orientation or test rotation first.

    cam.rotate(0, 90); // Rotate 90 degrees yaw (around Y)
    cam.update();
    // After 90 deg yaw (PI/2), forward should be along world +Z (cos(PI/2)=0, sin(PI/2)=1 => (0,0,1))
    // So moving forward by 10 should change Z by 10.
    const initial_pos_z = cam.position.z;
    cam.moveForward(10.0);
    cam.update();
    try std.testing.expect(std.math.approxEqAbs(cam.position.z, initial_pos_z + 10.0, 0.001));

    const initial_pos_x = cam.position.x;
    cam.moveRight(5.0); // Right vector should be -X after 90 deg yaw
    cam.update();
    try std.testing.expect(std.math.approxEqAbs(cam.position.x, initial_pos_x - 5.0, 0.001));

    std.log.info("Camera movement/rotation test completed.", .{});
}
