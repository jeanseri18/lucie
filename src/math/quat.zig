// src/math/quat.zig
const std = @import("std");
const math = std.math;
const Vec3 = @import("vec3.zig").Vec3;
const Mat4 = @import("mat4.zig").Mat4;

// Quaternion: x, y, z are vector part, w is scalar part (real part)
// q = w + xi + yj + zk
pub const Quat = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub const identity = Quat{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0 };

    pub fn init(x: f32, y: f32, z: f32, w: f32) Quat {
        return Quat{ .x = x, .y = y, .z = z, .w = w };
    }

    // From axis (must be normalized) and angle (radians)
    pub fn fromAxisAngle(axis: Vec3, angle_rad: f32) Quat {
        const half_angle = angle_rad / 2.0;
        const s = math.sin(half_angle);
        return Quat{
            .x = axis.x * s,
            .y = axis.y * s,
            .z = axis.z * s,
            .w = math.cos(half_angle),
        };
    }

    pub fn add(self: Quat, other: Quat) Quat {
        return Quat{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
            .w = self.w + other.w,
        };
    }

    pub fn scale(self: Quat, scalar: f32) Quat {
        return Quat{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
            .w = self.w * scalar,
        };
    }

    // Hamilton product: q1 * q2
    pub fn mul(q1: Quat, q2: Quat) Quat {
        return Quat{
            .x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y,
            .y = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x,
            .z = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w,
            .w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z,
        };
    }

    // Rotate a vector by this quaternion
    // Assumes this quaternion is normalized (represents a rotation)
    // v' = q * v * conjugate(q)
    // where v is a pure quaternion (0, vec.x, vec.y, vec.z)
    pub fn mulVec3(self: Quat, v: Vec3) Vec3 {
        const v_quat = Quat.init(v.x, v.y, v.z, 0.0);
        const conj = self.conjugate();
        // q * v_quat
        const temp = self.mul(v_quat);
        // (q * v_quat) * conj
        const final_quat = temp.mul(conj);
        return Vec3.init(final_quat.x, final_quat.y, final_quat.z);
    }


    pub fn conjugate(self: Quat) Quat {
        return Quat{ .x = -self.x, .y = -self.y, .z = -self.z, .w = self.w };
    }

    pub fn lengthSquared(self: Quat) f32 {
        return self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w;
    }

    pub fn length(self: Quat) f32 {
        return math.sqrt(self.lengthSquared());
    }

    pub fn normalized(self: Quat) Quat {
        const l = self.length();
        if (l == 0.0) return Quat.identity; // Or panic/error
        return self.scale(1.0 / l);
    }

    pub fn inverse(self: Quat) Quat {
        const len_sq = self.lengthSquared();
        if (len_sq == 0.0) return Quat.identity; // Or panic
        return self.conjugate().scale(1.0 / len_sq);
    }

    // Spherical Linear Interpolation
    // t is clamped between 0 and 1
    pub fn slerp(q1: Quat, q2_orig: Quat, t: f32) Quat {
        const t_clamped = math.clamp(t, 0.0, 1.0);
        var q2 = q2_orig;

        var cos_omega = q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w;

        // If dot product is negative, use -q2 to take the shorter path
        if (cos_omega < 0.0) {
            q2 = q2.scale(-1.0);
            cos_omega = -cos_omega;
        }

        var k0: f32 = undefined;
        var k1: f32 = undefined;

        if (cos_omega > 0.9999) { // Very close, use linear interpolation
            k0 = 1.0 - t_clamped;
            k1 = t_clamped;
        } else { // Spherical interpolation
            const sin_omega = math.sqrt(1.0 - cos_omega * cos_omega);
            const omega = math.atan2(sin_omega, cos_omega);
            const one_over_sin_omega = 1.0 / sin_omega;

            k0 = math.sin((1.0 - t_clamped) * omega) * one_over_sin_omega;
            k1 = math.sin(t_clamped * omega) * one_over_sin_omega;
        }

        return Quat{
            .x = k0 * q1.x + k1 * q2.x,
            .y = k0 * q1.y + k1 * q2.y,
            .z = k0 * q1.z + k1 * q2.z,
            .w = k0 * q1.w + k1 * q2.w,
        };
    }

    // Convert quaternion to 3x3 rotation matrix (or upper-left of Mat4)
    // Assumes quaternion is normalized
    pub fn toMat4(self: Quat) Mat4 {
        const x2 = self.x * self.x;
        const y2 = self.y * self.y;
        const z2 = self.z * self.z;
        const xy = self.x * self.y;
        const xz = self.x * self.z;
        const yz = self.y * self.z;
        const wx = self.w * self.x;
        const wy = self.w * self.y;
        const wz = self.w * self.z;

        return Mat4{
            .cols = [_]Vec4{
                Vec4.init(1.0 - 2.0 * (y2 + z2), 2.0 * (xy + wz), 2.0 * (xz - wy), 0.0),
                Vec4.init(2.0 * (xy - wz), 1.0 - 2.0 * (x2 + z2), 2.0 * (yz + wx), 0.0),
                Vec4.init(2.0 * (xz + wy), 2.0 * (yz - wx), 1.0 - 2.0 * (x2 + y2), 0.0),
                Vec4.init(0.0, 0.0, 0.0, 1.0),
            },
        };
    }

    // TODO: fromMat3 or fromMat4 (extract rotation) is more complex.

    pub fn equals(self: Quat, other: Quat, epsilon: f32) bool {
        // Note: q and -q represent the same rotation, so a simple component-wise check might fail
        // for equivalent rotations. For exact quaternion equality, this is fine.
        return math.fabs(self.x - other.x) < epsilon and
               math.fabs(self.y - other.y) < epsilon and
               math.fabs(self.z - other.z) < epsilon and
               math.fabs(self.w - other.w) < epsilon;
    }

    pub fn toString(self: Quat) [120]u8 { // Adjust buffer size as needed
        return std.fmt.bufPrint("Quat(x:{d:.4}, y:{d:.4}, z:{d:.4}, w:{d:.4})", .{ self.x, self.y, self.z, self.w }) catch "Quat format error";
    }
};

test "Quat identity and initialization" {
    const q = Quat.init(1.0, 2.0, 3.0, 4.0);
    try std.testing.expect(q.x == 1.0 and q.y == 2.0 and q.z == 3.0 and q.w == 4.0);
    try std.testing.expect(Quat.identity.w == 1.0 and Quat.identity.x == 0.0);
}

test "Quat fromAxisAngle" {
    const axis = Vec3.up;
    const angle = math.pi / 2.0; // 90 degrees around Y
    const q = Quat.fromAxisAngle(axis, angle);
    // Expected: x=0, y=sin(pi/4)=sqrt(2)/2, z=0, w=cos(pi/4)=sqrt(2)/2
    const expected_val = math.sqrt(2.0) / 2.0;
    try std.testing.expect(math.fabs(q.x - 0.0) < 0.0001);
    try std.testing.expect(math.fabs(q.y - expected_val) < 0.0001);
    try std.testing.expect(math.fabs(q.z - 0.0) < 0.0001);
    try std.testing.expect(math.fabs(q.w - expected_val) < 0.0001);
}

test "Quat multiplication" {
    const q1 = Quat.fromAxisAngle(Vec3.up, math.pi / 2.0);    // 90 deg around Y
    const q2 = Quat.fromAxisAngle(Vec3.right, math.pi / 2.0); // 90 deg around X
    const q_res = q1.mul(q2);

    // Rotating (1,0,0) by q1 gives (0,0,-1)
    // Rotating (0,0,-1) by q2 (90 deg around X) gives (0,1,0)
    const v = Vec3.init(1,0,0);
    const v_rot_q1 = q1.mulVec3(v);
    try std.testing.expect(v_rot_q1.equals(Vec3.init(0,0,-1), 0.0001));
    const v_rot_q1_q2 = q2.mulVec3(v_rot_q1);
     try std.testing.expect(v_rot_q1_q2.equals(Vec3.init(0,1,0), 0.0001));

    const v_rot_qres = q_res.mulVec3(v);
    try std.testing.expect(v_rot_qres.equals(Vec3.init(0,1,0), 0.0001));
}

test "Quat length, normalization, conjugate, inverse" {
    const q = Quat.init(1.0, 2.0, 3.0, 4.0); // Non-unit quaternion
    const len_sq = 1.0 + 4.0 + 9.0 + 16.0; // 30
    try std.testing.expect(q.lengthSquared() == len_sq);
    try std.testing.expect(q.length() == math.sqrt(len_sq));

    const norm_q = q.normalized();
    try std.testing.expect(math.fabs(norm_q.lengthSquared() - 1.0) < 0.0001);

    const conj = q.conjugate();
    try std.testing.expect(conj.x == -1.0 and conj.y == -2.0 and conj.z == -3.0 and conj.w == 4.0);

    const inv = q.inverse();
    const prod = q.mul(inv); // q * q^-1 should be identity
    try std.testing.expect(prod.equals(Quat.identity, 0.0001));
}

test "Quat slerp" {
    const q_id = Quat.identity;
    const q_y90 = Quat.fromAxisAngle(Vec3.up, math.pi / 2.0);

    const q_mid = Quat.slerp(q_id, q_y90, 0.5);
    const q_y45 = Quat.fromAxisAngle(Vec3.up, math.pi / 4.0); // Expected mid rotation
    // Slerp result and fromAxisAngle might differ by sign if w < 0, but represent same rotation.
    // Ensure w is positive for comparison or compare rotation matrices.
    var q_mid_cmp = q_mid;
    if (q_mid_cmp.w < 0) q_mid_cmp = q_mid_cmp.scale(-1);
    var q_y45_cmp = q_y45;
    if (q_y45_cmp.w < 0) q_y45_cmp = q_y45_cmp.scale(-1);

    try std.testing.expect(q_mid_cmp.equals(q_y45_cmp, 0.0001));

    const q_end = Quat.slerp(q_id, q_y90, 1.0);
     var q_end_cmp = q_end;
    if (q_end_cmp.w < 0) q_end_cmp = q_end_cmp.scale(-1);
    var q_y90_cmp = q_y90;
    if (q_y90_cmp.w < 0) q_y90_cmp = q_y90_cmp.scale(-1);
    try std.testing.expect(q_end_cmp.equals(q_y90_cmp, 0.0001));
}

test "Quat toMat4" {
    const q_y90 = Quat.fromAxisAngle(Vec3.up, math.pi / 2.0); // 90 deg around Y
    const m_rot_y90 = Mat4.rotation(Vec3.up, math.pi/2.0);
    const m_from_q = q_y90.toMat4();

    try std.testing.expect(m_from_q.equals(m_rot_y90, 0.0001));

    const q_id = Quat.identity;
    const m_id = Mat4.identity();
    const m_from_q_id = q_id.toMat4();
    try std.testing.expect(m_from_q_id.equals(m_id, 0.0001));
}

test "Quat mulVec3 rotation" {
    const q_y90 = Quat.fromAxisAngle(Vec3.up, math.pi / 2.0);
    const v_x_axis = Vec3.init(1,0,0);
    const rotated_v = q_y90.mulVec3(v_x_axis); // Rotating X-axis by +90deg around Y should yield -Z axis
    try std.testing.expect(rotated_v.equals(Vec3.init(0,0,-1), 0.0001));

    const v_z_axis = Vec3.init(0,0,1);
    const rotated_vz = q_y90.mulVec3(v_z_axis); // Rotating Z-axis by +90deg around Y should yield +X axis
    try std.testing.expect(rotated_vz.equals(Vec3.init(1,0,0), 0.0001));
}
