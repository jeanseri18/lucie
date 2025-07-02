// src/math/vec4.zig
const std = @import("std");
const math = std.math;
const Vec3 = @import("vec3.zig").Vec3; // For potential conversions

pub const Vec4 = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub const zero = Vec4{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 };
    pub const one = Vec4{ .x = 1.0, .y = 1.0, .z = 1.0, .w = 1.0 };
    // Common use for w=1 (position vector) or w=0 (direction vector)
    // Colors also use Vec4 (RGBA)

    pub fn init(x: f32, y: f32, z: f32, w: f32) Vec4 {
        return Vec4{ .x = x, .y = y, .z = z, .w = w };
    }

    pub fn fromVec3(v: Vec3, w_val: f32) Vec4 {
        return Vec4{ .x = v.x, .y = v.y, .z = v.z, .w = w_val };
    }

    pub fn toVec3(self: Vec4) Vec3 {
        // Perspective divide if w is not 0 or 1 (optional, depends on use case)
        // For now, direct conversion.
        // if (self.w != 0.0 and self.w != 1.0) {
        //     return Vec3{ .x = self.x / self.w, .y = self.y / self.w, .z = self.z / self.w};
        // }
        return Vec3{ .x = self.x, .y = self.y, .z = self.z };
    }

    pub fn add(self: Vec4, other: Vec4) Vec4 {
        return Vec4{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
            .w = self.w + other.w,
        };
    }

    pub fn sub(self: Vec4, other: Vec4) Vec4 {
        return Vec4{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
            .w = self.w - other.w,
        };
    }

    pub fn scale(self: Vec4, scalar: f32) Vec4 {
        return Vec4{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
            .w = self.w * scalar,
        };
    }

    pub fnnegate(self: Vec4) Vec4 {
        return Vec4{ .x = -self.x, .y = -self.y, .z = -self.z, .w = -self.w };
    }

    pub fn dot(self: Vec4, other: Vec4) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w;
    }

    pub fn lengthSquared(self: Vec4) f32 {
        return self.dot(self);
    }

    pub fn length(self: Vec4) f32 {
        return math.sqrt(self.lengthSquared());
    }

    pub fn normalized(self: Vec4) Vec4 {
        const l = self.length();
        if (l == 0.0) return Vec4.zero;
        return Vec4{
            .x = self.x / l,
            .y = self.y / l,
            .z = self.z / l,
            .w = self.w / l,
        };
    }

    pub fn lerp(start: Vec4, end: Vec4, t: f32) Vec4 {
        const t_clamped = math.clamp(t, 0.0, 1.0);
        return start.add(end.sub(start).scale(t_clamped));
    }

    pub fn equals(self: Vec4, other: Vec4, epsilon: f32) bool {
        return math.fabs(self.x - other.x) < epsilon and
               math.fabs(self.y - other.y) < epsilon and
               math.fabs(self.z - other.z) < epsilon and
               math.fabs(self.w - other.w) < epsilon;
    }

    pub fn toString(self: Vec4) [120]u8 { // Adjust buffer size as needed
        return std.fmt.bufPrint("Vec4({d:.4}, {d:.4}, {d:.4}, {d:.4})", .{ self.x, self.y, self.z, self.w }) catch "Vec4 format error";
    }
};

test "Vec4 initialization and constants" {
    const v = Vec4.init(1.0, 2.0, 3.0, 4.0);
    try std.testing.expect(v.x == 1.0 and v.y == 2.0 and v.z == 3.0 and v.w == 4.0);
    try std.testing.expect(Vec4.zero.w == 0.0);
    try std.testing.expect(Vec4.one.w == 1.0);
}

test "Vec4 arithmetic" {
    const v1 = Vec4.init(1.0, 2.0, 3.0, 4.0);
    const v2 = Vec4.init(5.0, 6.0, 7.0, 8.0);

    const sum = v1.add(v2);
    try std.testing.expect(sum.x == 6.0 and sum.y == 8.0 and sum.z == 10.0 and sum.w == 12.0);

    const diff = v2.sub(v1);
    try std.testing.expect(diff.x == 4.0 and diff.y == 4.0 and diff.z == 4.0 and diff.w == 4.0);

    const scaled = v1.scale(2.0);
    try std.testing.expect(scaled.x == 2.0 and scaled.y == 4.0 and scaled.z == 6.0 and scaled.w == 8.0);

    const negated = v1.negate();
    try std.testing.expect(negated.x == -1.0 and negated.w == -4.0);
}

test "Vec4 dot product" {
    const v1 = Vec4.init(1.0, 2.0, 3.0, 4.0);
    const v2 = Vec4.init(1.0, -1.0, 1.0, -1.0);
    const dot_prod = v1.dot(v2); // 1*1 + 2*(-1) + 3*1 + 4*(-1) = 1 - 2 + 3 - 4 = -2
    try std.testing.expect(dot_prod == -2.0);
}

test "Vec4 length and normalization" {
    const v = Vec4.init(1.0, 2.0, 2.0, 0.0); // Length should be sqrt(1+4+4) = 3
    try std.testing.expect(v.lengthSquared() == 9.0);
    try std.testing.expect(v.length() == 3.0);

    const norm_v = v.normalized();
    try std.testing.expect(norm_v.equals(Vec4.init(1.0/3.0, 2.0/3.0, 2.0/3.0, 0.0), 0.0001));
    try std.testing.expect(Vec4.zero.normalized().equals(Vec4.zero, 0.0001));
}

test "Vec4 lerp" {
    const v1 = Vec4.zero;
    const v2 = Vec4.one;
    const mid = Vec4.lerp(v1, v2, 0.5);
    try std.testing.expect(mid.equals(Vec4.init(0.5,0.5,0.5,0.5), 0.0001));
}

test "Vec4 conversion" {
    const v3 = Vec3.init(1.0,2.0,3.0);
    const v4 = Vec4.fromVec3(v3, 1.0);
    try std.testing.expect(v4.x == 1.0 and v4.y == 2.0 and v4.z == 3.0 and v4.w == 1.0);
    const v3_again = v4.toVec3();
    try std.testing.expect(v3_again.x == v3.x and v3_again.y == v3.y and v3_again.z == v3.z);
}
