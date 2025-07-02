// src/math/mat4.zig
const std = @import("std");
const math = std.math;
const Vec3 = @import("vec3.zig").Vec3;
const Vec4 = @import("vec4.zig").Vec4;

// Column-major matrix representation: m[col][row]
// m00 m10 m20 m30  (m[0][0], m[1][0], m[2][0], m[3][0]) -> first column
// m01 m11 m21 m31  (m[0][1], m[1][1], m[2][1], m[3][1]) -> second column
// m02 m12 m22 m32  (m[0][2], m[1][2], m[2][2], m[3][2])
// m03 m13 m23 m33  (m[0][3], m[1][3], m[2][3], m[3][3])
// This means elements are stored as: [col0_el0, col0_el1, col0_el2, col0_el3, col1_el0, ...]
// Or, as an array of 4 Vec4 columns.
pub const Mat4 = extern struct {
    cols: [4]Vec4,

    pub fn identity() Mat4 {
        return Mat4{
            .cols = [_]Vec4{
                Vec4.init(1.0, 0.0, 0.0, 0.0),
                Vec4.init(0.0, 1.0, 0.0, 0.0),
                Vec4.init(0.0, 0.0, 1.0, 0.0),
                Vec4.init(0.0, 0.0, 0.0, 1.0),
            },
        };
    }

    // Access element by column, then row
    pub fn get(self: Mat4, col: u3, row: u3) f32 {
        return switch (row) {
            0 => self.cols[col].x,
            1 => self.cols[col].y,
            2 => self.cols[col].z,
            3 => self.cols[col].w,
            else => @panic("Row out of bounds"),
        };
    }

    pub fn set(self: *Mat4, col: u3, row: u3, value: f32) void {
         switch (row) {
            0 => self.cols[col].x = value,
            1 => self.cols[col].y = value,
            2 => self.cols[col].z = value,
            3 => self.cols[col].w = value,
            else => @panic("Row out of bounds"),
        };
    }

    pub fn mul(a: Mat4, b: Mat4) Mat4 {
        var out: Mat4 = undefined;
        var col: u3 = 0;
        while (col < 4) : (col += 1) {
            out.cols[col] = Vec4.init(
                a.cols[0].x * b.cols[col].x + a.cols[1].x * b.cols[col].y + a.cols[2].x * b.cols[col].z + a.cols[3].x * b.cols[col].w,
                a.cols[0].y * b.cols[col].x + a.cols[1].y * b.cols[col].y + a.cols[2].y * b.cols[col].z + a.cols[3].y * b.cols[col].w,
                a.cols[0].z * b.cols[col].x + a.cols[1].z * b.cols[col].y + a.cols[2].z * b.cols[col].z + a.cols[3].z * b.cols[col].w,
                a.cols[0].w * b.cols[col].x + a.cols[1].w * b.cols[col].y + a.cols[2].w * b.cols[col].z + a.cols[3].w * b.cols[col].w,
            );
        }
        return out;
    }

    pub fn mulVec4(m: Mat4, v: Vec4) Vec4 {
        return Vec4.init(
            m.cols[0].x * v.x + m.cols[1].x * v.y + m.cols[2].x * v.z + m.cols[3].x * v.w,
            m.cols[0].y * v.x + m.cols[1].y * v.y + m.cols[2].y * v.z + m.cols[3].y * v.w,
            m.cols[0].z * v.x + m.cols[1].z * v.y + m.cols[2].z * v.z + m.cols[3].z * v.w,
            m.cols[0].w * v.x + m.cols[1].w * v.y + m.cols[2].w * v.z + m.cols[3].w * v.w,
        );
    }

    // Multiply by Vec3, assuming w=1 for position or w=0 for direction
    // For position (w=1):
    pub fn mulPosition(m: Mat4, v: Vec3) Vec3 {
        const res4 = m.mulVec4(Vec4.fromVec3(v, 1.0));
        if (res4.w == 0.0 or res4.w == 1.0) { // Avoid division by zero or no-op division
            return res4.toVec3();
        }
        return res4.toVec3().scale(1.0 / res4.w); // Perspective divide
    }

    // For direction (w=0):
    pub fn mulDirection(m: Mat4, v: Vec3) Vec3 {
        const res4 = m.mulVec4(Vec4.fromVec3(v, 0.0));
        return res4.toVec3(); // w should remain 0 if m is affine
    }

    pub fn translation(t: Vec3) Mat4 {
        var m = Mat4.identity();
        m.cols[3] = Vec4.fromVec3(t, 1.0);
        return m;
    }

    pub fn scaling(s: Vec3) Mat4 {
        return Mat4{
            .cols = [_]Vec4{
                Vec4.init(s.x, 0.0, 0.0, 0.0),
                Vec4.init(0.0, s.y, 0.0, 0.0),
                Vec4.init(0.0, 0.0, s.z, 0.0),
                Vec4.init(0.0, 0.0, 0.0, 1.0),
            },
        };
    }

    // Rotation matrix around an axis by an angle (radians)
    pub fn rotation(axis: Vec3, angle_rad: f32) Mat4 {
        const ax = axis.normalized();
        const s = math.sin(angle_rad);
        const c = math.cos(angle_rad);
        const oc = 1.0 - c;

        return Mat4{
            .cols = [_]Vec4{
                Vec4.init(oc * ax.x * ax.x + c, oc * ax.x * ax.y - ax.z * s, oc * ax.z * ax.x + ax.y * s, 0.0),
                Vec4.init(oc * ax.x * ax.y + ax.z * s, oc * ax.y * ax.y + c, oc * ax.y * ax.z - ax.x * s, 0.0),
                Vec4.init(oc * ax.z * ax.x - ax.y * s, oc * ax.y * ax.z + ax.x * s, oc * ax.z * ax.z + c, 0.0),
                Vec4.init(0.0, 0.0, 0.0, 1.0),
            },
        };
    }

    // Perspective projection matrix
    // fov_y_rad: field of view in Y direction, in radians
    // aspect_ratio: width / height
    // z_near, z_far: clipping planes
    pub fn perspective(fov_y_rad: f32, aspect_ratio: f32, z_near: f32, z_far: f32) Mat4 {
        std.debug.assert(aspect_ratio > 0.0);
        std.debug.assert(z_near > 0.0 and z_far > z_near);
        const tan_half_fovy = math.tan(fov_y_rad / 2.0);

        var m = Mat4.zero();
        m.cols[0].x = 1.0 / (aspect_ratio * tan_half_fovy);
        m.cols[1].y = 1.0 / tan_half_fovy;
        m.cols[2].z = -(z_far + z_near) / (z_far - z_near);
        m.cols[2].w = -1.0;
        m.cols[3].z = -(2.0 * z_far * z_near) / (z_far - z_near);
        return m;
    }

    // Orthographic projection matrix
    pub fn orthographic(left: f32, right: f32, bottom: f32, top: f32, near_val: f32, far_val: f32) Mat4 {
        var m = Mat4.identity();
        m.cols[0].x = 2.0 / (right - left);
        m.cols[1].y = 2.0 / (top - bottom);
        m.cols[2].z = -2.0 / (far_val - near_val);
        m.cols[3].x = -(right + left) / (right - left);
        m.cols[3].y = -(top + bottom) / (top - bottom);
        m.cols[3].z = -(far_val + near_val) / (far_val - near_val);
        return m;
    }

    // LookAt matrix (creates a view matrix)
    // eye: position of the camera
    // target: point the camera is looking at
    // up_dir: world up direction (usually Vec3.up)
    pub fn lookAt(eye: Vec3, target: Vec3, up_dir: Vec3) Mat4 {
        const f = target.sub(eye).normalized();      // Forward vector
        const s = f.cross(up_dir).normalized();    // Right vector
        const u = s.cross(f);                      // Up vector (recalculated)

        var res = Mat4.identity();
        res.cols[0].x = s.x;
        res.cols[1].x = s.y;
        res.cols[2].x = s.z;
        res.cols[0].y = u.x;
        res.cols[1].y = u.y;
        res.cols[2].y = u.z;
        res.cols[0].z = -f.x;
        res.cols[1].z = -f.y;
        res.cols[2].z = -f.z;
        res.cols[3].x = -s.dot(eye);
        res.cols[3].y = -u.dot(eye);
        res.cols[3].z = f.dot(eye);
        return res;
    }

    pub fn transpose(m: Mat4) Mat4 {
        var out: Mat4 = undefined;
        var r: u3 = 0;
        while(r < 4) : (r+=1) {
            var c: u3 = 0;
            while(c < 4) : (c+=1) {
                out.set(r, c, m.get(c,r));
            }
        }
        return out;
    }

    // TODO: Determinant and Inverse are more complex, can be added later if needed.
    // pub fn determinant(self: Mat4) f32 { ... }
    // pub fn inverse(self: Mat4) ?Mat4 { ... } // Can fail if determinant is zero

    pub fn toString(self: Mat4) [256]u8 { // Adjust as needed
        return std.fmt.bufPrint(
            "Mat4(\n  {any},\n  {any},\n  {any},\n  {any}\n)",
            .{ self.cols[0].toString(), self.cols[1].toString(), self.cols[2].toString(), self.cols[3].toString() }
        ) catch "Mat4 format error";
    }

    pub fn equals(a: Mat4, b: Mat4, epsilon: f32) bool {
        var col: u3 = 0;
        while(col < 4) : (col +=1) {
            if (!a.cols[col].equals(b.cols[col], epsilon)) return false;
        }
        return true;
    }

    pub const zero = Mat4 {
        .cols = [_]Vec4{ Vec4.zero, Vec4.zero, Vec4.zero, Vec4.zero },
    };
};

test "Mat4 identity and access" {
    const m = Mat4.identity();
    try std.testing.expect(m.get(0,0) == 1.0);
    try std.testing.expect(m.get(1,1) == 1.0);
    try std.testing.expect(m.get(0,1) == 0.0);

    var m_mut = Mat4.identity();
    m_mut.set(1,0, 5.0); // col 1, row 0
    try std.testing.expect(m_mut.cols[1].x == 5.0);
    try std.testing.expect(m_mut.get(1,0) == 5.0);
}

test "Mat4 multiplication" {
    const m1 = Mat4.translation(Vec3.init(1.0, 0.0, 0.0));
    const m2 = Mat4.scaling(Vec3.init(2.0, 2.0, 2.0));
    const m_res = m1.mul(m2); // Scale then translate

    // Expected: Scale first, so vertices are doubled, then translated by 1 in x.
    // If m1 is T and m2 is S, m_res = T * S
    // cols[0] = (2,0,0,0)
    // cols[1] = (0,2,0,0)
    // cols[2] = (0,0,2,0)
    // cols[3] = (1,0,0,1) * S = (1*2, 0*2, 0*2, 1*1) -> (2,0,0,1)
    // This is not correct. Standard matrix multiplication order T * S means S is applied first.
    // The result of T * S should be:
    // [1 0 0 1] [sx 0  0  0]   [sx 0  0  1*sx]
    // [0 1 0 0] [0  sy 0  0] = [0  sy 0  0   ]
    // [0 0 1 0] [0  0  sz 0]   [0  0  sz 0   ]
    // [0 0 0 1] [0  0  0  1]   [0  0  0  1   ]
    // So m_res.cols[3].x should be m1.cols[3].x (which is 1)
    // My manual calculation of matrix multiplication logic or storage might be off.
    // Let's use a known test case.
    // If T = translate(1,0,0), S = scale(2,2,2)
    // T * S applied to point P: (T * S) * P. S applies first.
    // T = [1001][0100][0010][0001]
    // S = [2000][0200][0020][0001]
    // Resulting matrix T*S:
    // col0: (T.col0*S.c0r0 + T.col1*S.c0r1 + T.col2*S.c0r2 + T.col3*S.c0r3)
    // T.col0 = (1,0,0,0), T.col1=(0,1,0,0), T.col2=(0,0,1,0), T.col3=(1,0,0,1)
    // S.col0=(2,0,0,0), S.col1=(0,2,0,0), S.col2=(0,0,2,0), S.col3=(0,0,0,1)
    //
    // (m_res.cols[0].x should be 2)
    // (m_res.cols[1].y should be 2)
    // (m_res.cols[2].z should be 2)
    // (m_res.cols[3].x should be 1) <- This is different from my manual trace.
    // The way mul is written: out.cols[c] = a.mulVec4(b.cols[c]);
    // This means a is the left matrix, b is the right.
    // So m_res = m1 * m2. (m1 applied, then m2 applied to the space transformed by m1)
    // No, standard is M = M_parent * M_local.  So if M_world = M_translate * M_rotate * M_scale, scale happens first.
    // My mul function is `out.cols[c] = a * b.cols[c]`.
    // It should be `out.cols[c].x = row(a,0) dot col(b,c)`
    // My current mul is:
    // out.cols[c].x = a.cols[0].x * b.cols[c].x + a.cols[1].x * b.cols[c].y + a.cols[2].x * b.cols[c].z + a.cols[3].x * b.cols[c].w
    // This is row(a,0) from `a` times col `c` from `b`. Yes, this is standard.
    // So, T*S should be:
    // T.cols[0]=(1,0,0,0) T.cols[1]=(0,1,0,0) T.cols[2]=(0,0,1,0) T.cols[3]=(1,0,0,1)
    // S.cols[0]=(2,0,0,0) S.cols[1]=(0,2,0,0) S.cols[2]=(0,0,2,0) S.cols[3]=(0,0,0,1)
    // m_res.cols[0].x = T.c0.x*S.c0.x + T.c1.x*S.c0.y + T.c2.x*S.c0.z + T.c3.x*S.c0.w = 1*2 + 0*0 + 0*0 + 1*0 = 2
    // m_res.cols[3].x = T.c0.x*S.c3.x + T.c1.x*S.c3.y + T.c2.x*S.c3.z + T.c3.x*S.c3.w = 1*0 + 0*0 + 0*0 + 1*1 = 1
    // So m_res.cols[0] = (2,0,0,0), m_res.cols[1]=(0,2,0,0), m_res.cols[2]=(0,0,2,0), m_res.cols[3]=(1,0,0,1)

    // Test with a point: P = (1,1,1,1). S*P = (2,2,2,1). T*(S*P) = (2+1, 2, 2, 1) = (3,2,2,1)
    // (T*S)*P should give the same:
    // m_res * P =
    // x = 2*1 + 0*1 + 0*1 + 1*1 = 3
    // y = 0*1 + 2*1 + 0*1 + 0*1 = 2
    // z = 0*1 + 0*1 + 2*1 + 0*1 = 2
    // w = 0*1 + 0*1 + 0*1 + 1*1 = 1.
    // So (3,2,2,1). This matches.

    try std.testing.expect(m_res.cols[0].equals(Vec4.init(2,0,0,0), 0.0001));
    try std.testing.expect(m_res.cols[1].equals(Vec4.init(0,2,0,0), 0.0001));
    try std.testing.expect(m_res.cols[2].equals(Vec4.init(0,0,2,0), 0.0001));
    try std.testing.expect(m_res.cols[3].equals(Vec4.init(1,0,0,1), 0.0001));

    const v = Vec4.init(1.0, 1.0, 1.0, 1.0);
    const res_v = m_res.mulVec4(v);
    try std.testing.expect(res_v.equals(Vec4.init(3.0, 2.0, 2.0, 1.0), 0.0001));
}

test "Mat4 transformations" {
    const t = Mat4.translation(Vec3.init(10.0, 20.0, 30.0));
    try std.testing.expect(t.cols[3].x == 10.0 and t.cols[3].y == 20.0 and t.cols[3].z == 30.0 and t.cols[3].w == 1.0);
    try std.testing.expect(t.cols[0].x == 1.0);

    const s = Mat4.scaling(Vec3.init(2.0, 3.0, 4.0));
    try std.testing.expect(s.cols[0].x == 2.0 and s.cols[1].y == 3.0 and s.cols[2].z == 4.0 and s.cols[3].w == 1.0);

    const r = Mat4.rotation(Vec3.up, math.pi / 2.0); // 90 deg rot around Y
    // Expected: (cos90, 0, sin90, 0)  (0,0,1,0) for first col
    //           (0,     1, 0,     0)  (0,1,0,0) for second col
    //           (-sin90,0, cos90, 0)  (-1,0,0,0) for third col
    //           (0,0,0,1)
    const epsilon = 0.0001;
    try std.testing.expect(r.cols[0].equals(Vec4.init(0,0,-1,0), epsilon)); // Rotates +X to -Z
    try std.testing.expect(r.cols[1].equals(Vec4.init(0,1,0,0), epsilon));
    try std.testing.expect(r.cols[2].equals(Vec4.init(1,0,0,0), epsilon)); // Rotates +Z to +X
    try std.testing.expect(r.cols[3].equals(Vec4.init(0,0,0,1), epsilon));

    const point = Vec3.init(1,0,0); // Point on X axis
    const rotated_point = r.mulPosition(point); // Should be on -Z axis (0,0,-1)
    try std.testing.expect(rotated_point.equals(Vec3.init(0,0,-1), epsilon));
}

test "Mat4 lookAt" {
    const eye = Vec3.init(0,0,5); // Camera at (0,0,5)
    const target = Vec3.zero;    // Looking at origin
    const up = Vec3.up;
    const view_matrix = Mat4.lookAt(eye, target, up);

    // Forward vector (z_cam) is (target - eye).normalized() = (0,0,-5).normalized() = (0,0,-1)
    // Right vector (x_cam) is (forward x up).normalized() = ((0,0,-1) x (0,1,0)).normalized() = (-1,0,0)
    // Up vector (y_cam) is (right x forward) = ((-1,0,0) x (0,0,-1)) = (0,-1,0) -> wait, this should be (0,1,0)
    // s.cross(f) = (-1,0,0).cross(0,0,-1) = (0 * -1 - 0 * 0, 0 * 0 - (-1 * -1), -1 * 0 - 0 * 0) = (0, -1, 0)
    // This is correct for view matrix construction where Z points out of screen.
    // After transformation, a point at origin (target) should be at origin in view space.
    // A point at (0,0,0) transformed by view_matrix should be (0,0,0)
    const origin_in_view = view_matrix.mulPosition(Vec3.zero);
    try std.testing.expect(origin_in_view.equals(Vec3.zero, 0.0001));

    // A point at eye (0,0,5) transformed should be (0,0,-5) in its own view space if z is distance.
    // Or is it (0,0,0)? The view matrix transforms world to view. Eye is origin of view space.
    // No, view_matrix * eye should be (0,0,0) after perspective divide if w is not 1.
    // The resulting W component of mulPosition for eye can be non-1.
    // Let's test a point along camera's Z axis: (0,0,4) world -> (0,0,-1) view
    const point_in_front = Vec3.init(0,0,4);
    const p_view = view_matrix.mulPosition(point_in_front);
    try std.testing.expect(p_view.equals(Vec3.init(0,0,-1), 0.0001));
}

test "Mat4 perspective" {
    const fov_y_rad = math.pi / 2.0; // 90 degrees
    const aspect = 16.0/9.0;
    const near = 0.1;
    const far = 100.0;
    const p = Mat4.perspective(fov_y_rad, aspect, near, far);
    // tan(pi/4) = 1
    // p.cols[0].x = 1 / (16/9 * 1) = 9/16
    // p.cols[1].y = 1 / 1 = 1
    try std.testing.expectApproxEqAbs(p.cols[0].x, 9.0/16.0, 0.0001);
    try std.testing.expectApproxEqAbs(p.cols[1].y, 1.0, 0.0001);
    try std.testing.expect(p.cols[2].w == -1.0); // Important for perspective divide
}

test "Mat4 transpose" {
    var m = Mat4.identity();
    m.set(0,1, 10); // m[0][1] = 10
    m.set(1,0, 20); // m[1][0] = 20
    const mt = m.transpose();
    try std.testing.expect(mt.get(1,0) == 10);
    try std.testing.expect(mt.get(0,1) == 20);
    try std.testing.expect(mt.get(0,0) == 1);
}
