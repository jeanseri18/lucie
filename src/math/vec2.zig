// src/math/vec2.zig
// 2D Vector (f32) structure and operations.

const std = @import("std");
const math = std.math; // For sqrt, trig functions etc.

pub const Vec2 = extern struct { // `extern` for C ABI compatibility if needed, often not strictly necessary.
    x: f32,
    y: f32,

    pub const zero = Vec2.new(0, 0);
    pub const one = Vec2.new(1, 1);
    pub const x_axis = Vec2.new(1, 0);
    pub const y_axis = Vec2.new(0, 1);

    pub fn new(x_val: f32, y_val: f32) Vec2 {
        return Vec2{ .x = x_val, .y = y_val };
    }

    // --- Basic Arithmetic ---
    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return Vec2.new(self.x + other.x, self.y + other.y);
    }
    pub fn sub(self: Vec2, other: Vec2) Vec2 {
        return Vec2.new(self.x - other.x, self.y - other.y);
    }
    pub fn scale(self: Vec2, scalar: f32) Vec2 {
        return Vec2.new(self.x * scalar, self.y * scalar);
    }
    pub fn mul(self: Vec2, other: Vec2) Vec2 { // Component-wise multiplication
        return Vec2.new(self.x * other.x, self.y * other.y);
    }
    pub fn div(self: Vec2, other: Vec2) Vec2 { // Component-wise division
        // Handle division by zero if necessary, or let it panic/return NaN.
        return Vec2.new(self.x / other.x, self.y / other.y);
    }
    pub fn scaleDiv(self: Vec2, scalar: f32) Vec2 {
        return Vec2.new(self.x / scalar, self.y / scalar);
    }
    pub fn negate(self: Vec2) Vec2 {
        return Vec2.new(-self.x, -self.y);
    }

    // --- Magnitude and Normalization ---
    pub fn lengthSq(self: Vec2) f32 {
        return self.x * self.x + self.y * self.y;
    }
    pub fn length(self: Vec2) f32 {
        return math.sqrt(self.lengthSq());
    }
    pub fn normalize(self: Vec2) Vec2 {
        const len = self.length();
        if (len == 0) return Vec2.zero; // Avoid division by zero
        return self.scale(1.0 / len);
    }
    // Normalize and return original length
    pub fn normalizeAndGetLength(self: *Vec2) f32 {
        const len = self.length();
        if (len > 0) {
            self.x /= len;
            self.y /= len;
        }
        return len;
    }

    // --- Dot and Cross Product ---
    pub fn dot(self: Vec2, other: Vec2) f32 {
        return self.x * other.x + self.y * other.y;
    }
    // 2D cross product (returns scalar z-component of the 3D cross product)
    // (v1.x, v1.y, 0) x (v2.x, v2.y, 0) = (0, 0, v1.x*v2.y - v1.y*v2.x)
    pub fn cross(self: Vec2, other: Vec2) f32 {
        return self.x * other.y - self.y * other.x;
    }

    // --- Distance ---
    pub fn distanceSq(self: Vec2, other: Vec2) f32 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        return dx * dx + dy * dy;
    }
    pub fn distance(self: Vec2, other: Vec2) f32 {
        return math.sqrt(self.distanceSq(other));
    }

    // --- Angle and Rotation ---
    // Angle of this vector from positive X-axis (in radians)
    pub fn angle(self: Vec2) f32 {
        return math.atan2(f32, self.y, self.x);
    }
    // Angle between this vector and another (in radians)
    pub fn angleTo(self: Vec2, other: Vec2) f32 {
        const dot_product = self.normalize().dot(other.normalize());
        // Clamp dot_product to [-1, 1] to avoid domain errors with acos due to precision issues
        const clamped_dot = math.clamp(dot_product, -1.0, 1.0);
        return math.acos(clamped_dot);
    }
    // Rotate this vector by an angle (radians) around the origin
    pub fn rotate(self: Vec2, angle_rad: f32) Vec2 {
        const cos_a = math.cos(angle_rad);
        const sin_a = math.sin(angle_rad);
        return Vec2.new(
            self.x * cos_a - self.y * sin_a,
            self.x * sin_a + self.y * cos_a
        );
    }
    // Rotate using precomputed cos/sin (optimization)
    pub fn rotateCosSin(self: Vec2, cos_a: f32, sin_a: f32) Vec2 {
         return Vec2.new(
            self.x * cos_a - self.y * sin_a,
            self.x * sin_a + self.y * cos_a
        );
    }

    // --- Other Utilities ---
    // Linear interpolation
    pub fn lerp(start: Vec2, end: Vec2, t: f32) Vec2 {
        const clamped_t = math.clamp(t, 0.0, 1.0);
        return start.add(end.sub(start).scale(clamped_t));
    }
    // Perpendicular vector (90-degree counter-clockwise rotation)
    pub fn perpendicular(self: Vec2) Vec2 {
        return Vec2.new(-self.y, self.x);
    }
    // Reflect vector v about normal n
    // R = V - 2 * dot(V, N) * N
    pub fn reflect(self: Vec2, normal: Vec2) Vec2 {
        const n_norm = normal.normalize(); // Ensure normal is unit length
        return self.sub(n_norm.scale(2.0 * self.dot(n_norm)));
    }
    // Project this vector onto another vector `onto`
    pub fn project(self: Vec2, onto: Vec2) Vec2 {
        const onto_norm_sq = onto.lengthSq();
        if (onto_norm_sq == 0) return Vec2.zero;
        const scale_factor = self.dot(onto) / onto_norm_sq;
        return onto.scale(scale_factor);
    }

    // Equality check with epsilon for float comparisons
    pub fn eql(self: Vec2, other: Vec2) bool {
        const epsilon = 0.00001; // Adjust epsilon as needed
        return math.approxEqAbs(self.x, other.x, epsilon) and
               math.approxEqAbs(self.y, other.y, epsilon);
    }
    // For std.fmt string formatting
    pub fn format(self: Vec2, comptime fmt_str: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt_str; _ = options; // Not using these for default format
        try writer.print("Vec2({d:.4}, {d:.4})", .{self.x, self.y});
    }
};

test "Vec2 creation and constants" {
    const v1 = Vec2.new(1.0, 2.0);
    try std.testing.expect(v1.x == 1.0 and v1.y == 2.0);
    try std.testing.expect(Vec2.zero.x == 0 and Vec2.zero.y == 0);
    try std.testing.expect(Vec2.one.eql(Vec2.new(1,1)));
    try std.testing.expect(Vec2.x_axis.eql(Vec2.new(1,0)));
}

test "Vec2 arithmetic operations" {
    const v1 = Vec2.new(1, 2);
    const v2 = Vec2.new(3, 4);
    try std.testing.expect(v1.add(v2).eql(Vec2.new(4, 6)));
    try std.testing.expect(v1.sub(v2).eql(Vec2.new(-2, -2)));
    try std.testing.expect(v1.scale(2.0).eql(Vec2.new(2, 4)));
    try std.testing.expect(v1.mul(v2).eql(Vec2.new(3, 8))); // Component-wise
    try std.testing.expect(v1.negate().eql(Vec2.new(-1,-2)));
}

test "Vec2 magnitude and normalization" {
    const v = Vec2.new(3, 4); // Length 5
    try std.testing.expect(v.lengthSq() == 25.0);
    try std.testing.expect(v.length() == 5.0);
    try std.testing.expect(v.normalize().eql(Vec2.new(0.6, 0.8)));

    var v_mut = Vec2.new(3,4);
    const len = v_mut.normalizeAndGetLength();
    try std.testing.expect(len == 5.0);
    try std.testing.expect(v_mut.eql(Vec2.new(0.6, 0.8)));

    try std.testing.expect(Vec2.zero.normalize().eql(Vec2.zero));
}

test "Vec2 dot and cross products" {
    const v1 = Vec2.new(1, 2);
    const v2 = Vec2.new(3, -1);
    try std.testing.expect(v1.dot(v2) == (1*3 + 2*-1)); // 3 - 2 = 1
    try std.testing.expect(v1.cross(v2) == (1*-1 - 2*3)); // -1 - 6 = -7
}

test "Vec2 distance" {
    const v1 = Vec2.new(1,1);
    const v2 = Vec2.new(4,5); // dx=3, dy=4, dist=5
    try std.testing.expect(v1.distanceSq(v2) == 25.0);
    try std.testing.expect(v1.distance(v2) == 5.0);
}

test "Vec2 angle and rotation" {
    const v_x = Vec2.x_axis; // (1,0)
    try std.testing.expect(math.approxEqAbs(v_x.angle(), 0.0, 0.0001));

    const v_y = Vec2.y_axis; // (0,1)
    try std.testing.expect(math.approxEqAbs(v_y.angle(), math.pi / 2.0, 0.0001));

    const v_45deg = Vec2.new(1,1).normalize(); // Approx (0.707, 0.707)
    try std.testing.expect(math.approxEqAbs(v_45deg.angle(), math.pi / 4.0, 0.0001));
    try std.testing.expect(math.approxEqAbs(v_x.angleTo(v_y), math.pi / 2.0, 0.0001));

    const rotated_vx_90deg = v_x.rotate(math.pi / 2.0); // Rotate (1,0) by 90 deg -> (0,1)
    try std.testing.expect(rotated_vx_90deg.eql(Vec2.y_axis));
}

test "Vec2 other utilities" {
    const v_start = Vec2.new(0,0);
    const v_end = Vec2.new(10,20);
    try std.testing.expect(Vec2.lerp(v_start, v_end, 0.5).eql(Vec2.new(5,10)));
    try std.testing.expect(Vec2.lerp(v_start, v_end, 0.0).eql(v_start));
    try std.testing.expect(Vec2.lerp(v_start, v_end, 1.0).eql(v_end));
    try std.testing.expect(Vec2.lerp(v_start, v_end, 1.5).eql(v_end)); // Clamped t

    const v = Vec2.new(2,3);
    try std.testing.expect(v.perpendicular().eql(Vec2.new(-3,2)));

    const incident = Vec2.new(1, -1); // Coming down and right
    const normal_up = Vec2.y_axis; // Reflect off horizontal surface
    const reflected_up = incident.reflect(normal_up); // Should be (1,1)
    try std.testing.expect(reflected_up.eql(Vec2.new(1,1)));

    const to_project = Vec2.new(2,2);
    const onto_vec = Vec2.new(3,0); // Project onto x-axis
    try std.testing.expect(to_project.project(onto_vec).eql(Vec2.new(2,0)));
}

test "Vec2 equality" {
    const v1 = Vec2.new(1.000001, 2.000002);
    const v2 = Vec2.new(1.000000, 2.000001);
    try std.testing.expect(v1.eql(v2));

    const v3 = Vec2.new(1.0, 2.5);
    try std.testing.expect(!v1.eql(v3));
}

test "Vec2 formatting" {
    const v = Vec2.new(1.23456, 7.89);
    var buf: [64]u8 = undefined;
    const slice = try std.fmt.bufPrint(&buf, "{}", .{v});
    try std.testing.expectEqualStrings("Vec2(1.2346, 7.8900)", slice);
}
