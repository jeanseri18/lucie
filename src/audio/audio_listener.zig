// src/audio/audio_listener.zig
// Defines the AudioListener for 3D spatialized audio.

const std = @import("std");
const Vec3 = @import("../math/vec3.zig").Vec3;
const Mat3 = @import("../math/mat3.zig").Mat3; // For orientation (or use Quaternion/Mat4)
const Quaternion = @import("../math/quaternion.zig").Quaternion;

// The AudioListener represents the point in the 3D world from which audio is heard.
// There is typically only one active listener in a scene (e.g., attached to the player's camera).
pub const AudioListener = struct {
    position: Vec3 = Vec3.zero(),

    // Orientation: defines forward and up vectors for the listener.
    // This can be represented in several ways:
    // 1. Separate forward and up vectors.
    // 2. A rotation matrix (Mat3 or relevant part of Mat4).
    // 3. A quaternion.
    // Miniaudio's `ma_engine_listener_set_orientation` takes forward and up vectors.
    forward_vector: Vec3 = Vec3.negative_z_axis(), // Default: looking down -Z
    up_vector: Vec3 = Vec3.y_axis(),          // Default: Y is up

    // Optional: Velocity, for Doppler effect calculation if supported by audio engine.
    // velocity: Vec3 = Vec3.zero(),

    // Optional: Cone properties, if the listener has directional hearing (e.g. HRTF pre-processing)
    // cone_inner_angle_radians: f32 = std.math.pi * 2.0, // Full sphere by default
    // cone_outer_angle_radians: f32 = std.math.pi * 2.0,
    // cone_outer_gain: f32 = 0.0, // Attenuation outside outer cone

    pub fn default() AudioListener {
        return AudioListener{}; // Uses default field values
    }

    pub fn setPosition(self: *AudioListener, pos: Vec3) void {
        self.position = pos;
        // TODO: Signal AudioEngine to update listener position in the audio backend (e.g., miniaudio)
        // Example: audioEngine.updateListenerTransform(self.position, self.forward_vector, self.up_vector);
    }

    pub fn setOrientation(self: *AudioListener, forward: Vec3, up: Vec3) void {
        // Ensure vectors are normalized and orthogonal if required by audio backend.
        // Miniaudio typically expects normalized vectors.
        self.forward_vector = forward.normalize();
        // Make 'up' orthogonal to 'forward', then normalize 'up'.
        // right = forward x up
        // corrected_up = right x forward (or up - project(up, forward))
        var r = self.forward_vector.cross(up.normalize()); // Get right vector
        if (r.lengthSq() < 0.00001) { // If forward and up are collinear
            // Attempt to create a valid 'up' if original was bad.
            // E.g., if forward is (0,1,0), new up could be (0,0,1) or (1,0,0)
            if (std.math.fabs(self.forward_vector.y) > 0.99) { // Forward is mostly Y axis
                r = self.forward_vector.cross(Vec3.z_axis()); // Try Z as temp up
                if (r.lengthSq() < 0.00001) { // If forward is also Z (should not happen if normalized before)
                     r = self.forward_vector.cross(Vec3.x_axis());
                }
            } else { // Forward is not primarily Y, so Y-up should be fine as a base
                 r = self.forward_vector.cross(Vec3.y_axis());
            }
        }
        self.up_vector = r.cross(self.forward_vector).normalize();


        // TODO: Signal AudioEngine to update listener orientation.
    }

    // Set orientation from a rotation matrix (e.g., view matrix's rotation part)
    pub fn setOrientationFromMatrix(self: *AudioListener, view_matrix_rotation_part: Mat3) void {
        // Assuming view_matrix_rotation_part is the upper 3x3 of a standard view matrix:
        // Forward vector is often the negative Z-axis of the camera's local space,
        // which corresponds to the third column (or row, depending on convention) of the
        // inverse of the view matrix's rotation part.
        // If view_matrix_rotation_part is indeed the rotation of the camera in world space:
        //   Forward = matrix * (0,0,-1) (if camera looks down -Z locally)
        //   Up      = matrix * (0,1,0)
        // However, miniaudio wants the direction the listener *is facing* in world space.
        // If view_matrix_rotation_part is from a camera's view matrix (world to view),
        // then its inverse's columns are camera's axes in world space.
        // Column 0: Right vector, Column 1: Up vector, Column 2: Backward vector (-Forward)
        // So, Forward_world = -view_matrix_rotation_part_inverse.col(2)
        //     Up_world      =  view_matrix_rotation_part_inverse.col(1)
        // This is complex. Simpler: if you have camera's world rotation as a Quaternion:
        // self.setOrientationFromQuaternion(camera_world_rotation);

        // For now, let's assume view_matrix_rotation_part is directly the listener's orientation matrix
        // where columns are basis vectors in world space [Right, Up, Forward_vector_pointing_out_of_screen]
        // Or [Right, Up, -LookDirection]
        // Miniaudio needs: ma_engine_listener_set_orientation(pEngine, 0, worldSpaceForward.x, worldSpaceForward.y, worldSpaceForward.z, worldSpaceUp.x, worldSpaceUp.y, worldSpaceUp.z);
        // If matrix columns are [Right, Up, Backwards]:
        // Forward = -matrix.col(2)
        // Up      =  matrix.col(1)
        // This depends on the exact convention of view_matrix_rotation_part.
        // For this placeholder, we'll assume a direct way to get these vectors.
        // If it's from a camera's view matrix (world -> camera space):
        // The third row of the view matrix (if row-major) or third column (if col-major)
        // often represents the camera's forward direction in world space (possibly negated).
        // Example: If view_matrix is column-major like OpenGL standard:
        //   Right vector: (m[0], m[1], m[2])
        //   Up vector:    (m[4], m[5], m[6])
        //   Forward vector: (-m[8], -m[9], -m[10]) (because view looks along -Z)
        // Let's assume `view_matrix_rotation_part` is such that:
        // Col 0 = Right_axis, Col 1 = Up_axis, Col 2 = Forward_axis (points out from camera's back)
        // So, actual forward is -Col2.
        // This is highly convention-dependent.
        // self.setOrientation(-view_matrix_rotation_part.zAxis(), view_matrix_rotation_part.yAxis());
        _ = view_matrix_rotation_part; // Placeholder to avoid unused warning
        @panic("setOrientationFromMatrix needs clear matrix convention definition.");
    }

    pub fn setOrientationFromQuaternion(self: *AudioListener, orientation_quat: Quaternion) void {
        // Default forward vector (e.g., (0,0,-1) if listener looks down -Z in its local space)
        const local_forward = Vec3.negative_z_axis();
        const local_up = Vec3.y_axis();

        self.setOrientation(
            orientation_quat.transformVector(local_forward),
            orientation_quat.transformVector(local_up)
        );
    }
};

test "AudioListener initialization and default values" {
    const listener = AudioListener.default();

    try std.testing.expect(listener.position.eql(Vec3.zero()));
    try std.testing.expect(listener.forward_vector.eql(Vec3.negative_z_axis()));
    try std.testing.expect(listener.up_vector.eql(Vec3.y_axis()));
    // try std.testing.expect(listener.velocity.eql(Vec3.zero()));

    std.log.info("AudioListener initialization test completed.", .{});
}

test "AudioListener setPosition and setOrientation" {
    var listener = AudioListener.default();

    const new_pos = Vec3.new(10, 20, 30);
    listener.setPosition(new_pos);
    try std.testing.expect(listener.position.eql(new_pos));

    const new_fwd = Vec3.x_axis(); // Look along +X
    const new_up = Vec3.y_axis();  // Y is still up
    listener.setOrientation(new_fwd, new_up);

    // setOrientation normalizes, so check against normalized versions
    try std.testing.expect(listener.forward_vector.eqlApprox(new_fwd.normalize(), 0.0001));
    // Up vector might be re-orthogonalized if new_fwd and new_up weren't perfectly orthogonal.
    // If they are orthogonal, up should remain new_up.normalize().
    try std.testing.expect(listener.up_vector.eqlApprox(new_up.normalize(), 0.0001));

    // Test with non-orthogonal up vector initially
    listener.setOrientation(Vec3.x_axis(), Vec3.new(1,1,0).normalize()); // Fwd=X, Up=(1,1,0)
    // Corrected up should be Y axis: right = X.cross((1,1,0).norm) = (0,0,Z).norm. up = (0,0,Z).cross(X) = Y
    try std.testing.expect(listener.forward_vector.eqlApprox(Vec3.x_axis(), 0.0001));
    try std.testing.expect(listener.up_vector.eqlApprox(Vec3.y_axis(), 0.0001));


    // Test setOrientationFromQuaternion
    // Rotate 90 degrees around Y axis. Default forward (-Z) should become (-X). Default up (Y) remains Y.
    const rot_quat = Quaternion.fromAxisAngle(Vec3.y_axis(), std.math.pi / 2.0);
    listener.setOrientationFromQuaternion(rot_quat);

    try std.testing.expect(listener.forward_vector.eqlApprox(Vec3.negative_x_axis(), 0.0001));
    try std.testing.expect(listener.up_vector.eqlApprox(Vec3.y_axis(), 0.0001));

    std.log.info("AudioListener setPosition/setOrientation test completed.", .{});
}
