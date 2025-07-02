// src/math/vec3.zig
const std = @import("std");
const math = std.math;
const Vec2 = @import("vec2.zig").Vec2; // For potential conversions or shared functions

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub const zero = Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 };
    pub const one = Vec3{ .x = 1.0, .y = 1.0, .z = 1.0 };
    pub const up = Vec3{ .x = 0.0, .y = 1.0, .z = 0.0 };
    pub const down = Vec3{ .x = 0.0, .y = -1.0, .z = 0.0 };
    pub const left = Vec3{ .x = -1.0, .y = 0.0, .z = 0.0 };
    pub const right = Vec3{ .x = 1.0, .y = 0.0, .z = 0.0 };
    pub const forward = Vec3{ .x = 0.0, .y = 0.0, .z = -1.0 }; // Common convention in RH systems
    pub const backward = Vec3{ .x = 0.0, .y = 0.0, .z = 1.0 };

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{ .x = x, .y = y, .z = z };
    }

    pub fn fromVec2(v: Vec2, z_val: f32) Vec3 {
        return Vec3{ .x = v.x, .y = v.y, .z = z_val };
    }

    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    pub fn sub(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    pub fn scale(self: Vec3, scalar: f32) Vec3 {
        return Vec3{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
        };
    }

    pub fn div(self: Vec3, scalar: f32) Vec3 {
        std.debug.assert(scalar != 0.0);
        return Vec3{
            .x = self.x / scalar,
            .y = self.y / scalar,
            .z = self.z / scalar,
        };
    }

    pub fnnegate(self: Vec3) Vec3 {
        return Vec3{ .x = -self.x, .y = -self.y, .z = -self.z };
    }

    pub fn dot(self: Vec3, other: Vec3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn cross(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = self.y * other.z - self.z * other.y,
            .y = self.z * other.x - self.x * other.z,
            .z = self.x * other.y - self.y * other.x,
        };
    }

    pub fn lengthSquared(self: Vec3) f32 {
        return self.dot(self);
    }

    pub fn length(self: Vec3) f32 {
        return math.sqrt(self.lengthSquared());
    }

    pub fn normalized(self: Vec3) Vec3 {
        const l = self.length();
        if (l == 0.0) return Vec3.zero; // Or handle error/panic
        return self.div(l);
    }

    pub fn distance(self: Vec3, other: Vec3) f32 {
        return self.sub(other).length();
    }

    pub fn lerp(start: Vec3, end: Vec3, t: f32) Vec3 {
        const t_clamped = math.clamp(t, 0.0, 1.0);
        return start.add(end.sub(start).scale(t_clamped));
    }

    pub fn equals(self: Vec3, other: Vec3, epsilon: f32) bool {
        return math.fabs(self.x - other.x) < epsilon and
               math.fabs(self.y - other.y) < epsilon and
               math.fabs(self.z - other.z) < epsilon;
    }

    pub fn toString(self: Vec3) [100]u8 { // Adjust buffer size as needed
        return std.fmt.bufPrint("Vec3({d:.4}, {d:.4}, {d:.4})", .{ self.x, self.y, self.z }) catch "Vec3 format error";
    }
};

test "Vec3 initialization and constants" {
    const v = Vec3.init(1.0, 2.0, 3.0);
    try std.testing.expect(v.x == 1.0 and v.y == 2.0 and v.z == 3.0);
    try std.testing.expect(Vec3.zero.x == 0.0 and Vec3.zero.y == 0.0 and Vec3.zero.z == 0.0);
    try std.testing.expect(Vec3.up.y == 1.0);
}

test "Vec3 arithmetic" {
    const v1 = Vec3.init(1.0, 2.0, 3.0);
    const v2 = Vec3.init(4.0, 5.0, 6.0);

    const sum = v1.add(v2);
    try std.testing.expect(sum.x == 5.0 and sum.y == 7.0 and sum.z == 9.0);

    const diff = v2.sub(v1);
    try std.testing.expect(diff.x == 3.0 and diff.y == 3.0 and diff.z == 3.0);

    const scaled = v1.scale(2.0);
    try std.testing.expect(scaled.x == 2.0 and scaled.y == 4.0 and scaled.z == 6.0);

    const negated = v1.negate();
    try std.testing.expect(negated.x == -1.0 and negated.y == -2.0 and negated.z == -3.0);
}

test "Vec3 dot product" {
    const v1 = Vec3.init(1.0, 2.0, 3.0);
    const v2 = Vec3.init(4.0, -5.0, 6.0);
    const dot_prod = v1.dot(v2); // 1*4 + 2*(-5) + 3*6 = 4 - 10 + 18 = 12
    try std.testing.expect(dot_prod == 12.0);
}

test "Vec3 cross product" {
    const v1 = Vec3.init(1.0, 0.0, 0.0); // x-axis
    const v2 = Vec3.init(0.0, 1.0, 0.0); // y-axis
    const cross_prod = v1.cross(v2); // Should be z-axis (0,0,1)
    try std.testing.expect(cross_prod.x == 0.0 and cross_prod.y == 0.0 and cross_prod.z == 1.0);

    const v3 = Vec3.init(1.0, 2.0, 3.0);
    const v4 = Vec3.init(4.0, 5.0, 6.0);
    const cross_v3_v4 = v3.cross(v4);
    // x = 2*6 - 3*5 = 12 - 15 = -3
    // y = 3*4 - 1*6 = 12 - 6 = 6
    // z = 1*5 - 2*4 = 5 - 8 = -3
    try std.testing.expect(cross_v3_v4.x == -3.0 and cross_v3_v4.y == 6.0 and cross_v3_v4.z == -3.0);
}

test "Vec3 length and normalization" {
    const v = Vec3.init(3.0, 4.0, 0.0); // Length should be 5
    try std.testing.expect(v.lengthSquared() == 25.0);
    try std.testing.expect(v.length() == 5.0);

    const norm_v = v.normalized();
    try std.testing.expect(norm_v.x == 0.6 and norm_v.y == 0.8 and norm_v.z == 0.0);
    try std.testing.expect(Vec3.zero.normalized().equals(Vec3.zero, 0.0001));
}

test "Vec3 distance" {
    const v1 = Vec3.init(1.0, 2.0, 3.0);
    const v2 = Vec3.init(4.0, 6.0, 3.0); // dx=3, dy=4, dz=0. dist = 5
    try std.testing.expect(v1.distance(v2) == 5.0);
}

test "Vec3 lerp" {
    const v1 = Vec3.init(0.0, 0.0, 0.0);
    const v2 = Vec3.init(10.0, 10.0, 10.0);
    const mid = Vec3.lerp(v1, v2, 0.5);
    try std.testing.expect(mid.equals(Vec3.init(5,5,5), 0.0001));
    const start = Vec3.lerp(v1,v2,0.0);
    try std.testing.expect(start.equals(v1, 0.0001));
    const end = Vec3.lerp(v1,v2,1.0);
    try std.testing.expect(end.equals(v2, 0.0001));
    const over = Vec3.lerp(v1,v2, 1.5); // Should clamp to v2
    try std.testing.expect(over.equals(v2, 0.0001));
}

test "Vec3 equals" {
    const v1 = Vec3.init(1.0, 2.0, 3.0);
    const v2 = Vec3.init(1.00001, 2.00001, 3.00001);
    try std.testing.expect(v1.equals(v2, 0.0001));
    try std.testing.expect(!v1.equals(v2, 0.000001));
}
