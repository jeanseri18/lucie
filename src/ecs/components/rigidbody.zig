// src/ecs/components/rigidbody.zig
// Defines the RigidBody component for physics simulation.

const std = @import("std");
const Vec2 = @import("../../math/vec2.zig").Vec2; // For 2D physics
const Vec3 = @import("../../math/vec3.zig").Vec3; // For 3D physics (if supported)

// Enum to define the type of rigid body
pub const RigidBodyType = enum {
    Static,       // Does not move, infinite mass (e.g., ground, walls)
    Kinematic,    // Moved by code (e.g., moving platforms), not by physics forces, but can push dynamic bodies
    Dynamic,      // Moved by physics forces, has finite mass
};

// For this component, we'll assume 2D physics for simplicity, using Vec2.
// If 3D physics is primary, Vec3 would be used for linear_velocity, forces etc.
pub const RigidBodyComponent = struct {
    body_type: RigidBodyType = .Static,

    // Physical properties
    mass: f32 = 1.0,          // Mass of the body (kg). Infinite for Static.
    inv_mass: f32 = 1.0,      // Inverse mass (1/mass). 0 for Static/Kinematic with infinite mass.
    inertia: f32 = 1.0,       // Moment of inertia (kg*m^2). Infinite for Static.
    inv_inertia: f32 = 1.0,   // Inverse moment of inertia (1/inertia). 0 for Static/Kinematic.

    // Material properties
    restitution: f32 = 0.5,   // Bounciness (0 = no bounce, 1 = perfect bounce)
    friction_static: f32 = 0.6, // Coefficient of static friction
    friction_dynamic: f32 = 0.4,// Coefficient of dynamic friction

    // Linear motion (2D)
    linear_velocity: Vec2 = Vec2.zero(),
    linear_damping: f32 = 0.1, // Damping factor to reduce linear velocity over time (e.g., air resistance)

    // Angular motion (2D - rotation around Z axis)
    angular_velocity: f32 = 0.0, // Radians per second
    angular_damping: f32 = 0.1,  // Damping factor for angular velocity

    // Forces and torques accumulated over a frame
    force_accumulator: Vec2 = Vec2.zero(), // Sum of forces applied this frame (Newtons)
    torque_accumulator: f32 = 0.0,       // Sum of torques applied this frame (Newton-meters)

    // Constraints
    is_gravity_enabled: bool = true,
    // fixed_rotation: bool = false, // If true, body cannot rotate due to physics

    // Optional: pointer to a physics shape / collider associated with this body
    // collider_handle: u32 = 0, // Or some Collider type

    pub fn init(body_type_param: RigidBodyType, mass_param: f32) RigidBodyComponent {
        var rb = RigidBodyComponent{
            .body_type = body_type_param,
            .mass = mass_param,
        };
        rb.updateMassProperties(mass_param, 0.0); // Default inertia, should be calculated from shape
        return rb;
    }

    pub fn updateMassProperties(self: *RigidBodyComponent, new_mass: f32, new_inertia: f32) void {
        if (self.body_type == .Static) {
            self.mass = 0.0; // Effectively infinite mass
            self.inv_mass = 0.0;
            self.inertia = 0.0; // Effectively infinite inertia
            self.inv_inertia = 0.0;
        } else {
            self.mass = std.math.max(0.001, new_mass); // Avoid zero or negative mass for dynamic bodies
            self.inv_mass = 1.0 / self.mass;

            // Inertia needs to be calculated based on the shape of the collider.
            // For a point mass or if not specified, it might be 0 or a default.
            // If new_inertia is 0, it implies it cannot rotate or has infinite rotational inertia.
            if (new_inertia <= 0.001 and self.body_type == .Dynamic) {
                self.inertia = 0.0; // effectively fixed rotation or point mass for rotation
                self.inv_inertia = 0.0;
            } else {
                 self.inertia = new_inertia;
                 self.inv_inertia = 1.0 / self.inertia;
            }
        }
    }

    pub fn addForce(self: *RigidBodyComponent, force: Vec2) void {
        // Static and Kinematic bodies are not affected by forces in the same way as Dynamic.
        // Kinematic bodies might record forces for interaction calculations but move programmatically.
        if (self.body_type == .Dynamic) {
            self.force_accumulator = self.force_accumulator.add(force);
        }
    }

    // Add force at a specific point relative to the body's center of mass (world space offset)
    pub fn addForceAtPoint(self: *RigidBodyComponent, force: Vec2, point_world_offset: Vec2) void {
        if (self.body_type == .Dynamic) {
            self.force_accumulator = self.force_accumulator.add(force);
            // Torque = r x F (cross product). In 2D, r = (px, py), F = (fx, fy)
            // Torque_z = px*fy - py*fx
            const torque = point_world_offset.cross(force); // Vec2.cross gives scalar z-component of torque
            self.torque_accumulator += torque;
        }
    }

    pub fn addTorque(self: *RigidBodyComponent, torque_value: f32) void {
        if (self.body_type == .Dynamic) {
            self.torque_accumulator += torque_value;
        }
    }

    pub fn clearAccumulators(self: *RigidBodyComponent) void {
        self.force_accumulator = Vec2.zero();
        self.torque_accumulator = 0.0;
    }
};


// Helper for Vec2.cross in 2D (scalar result for Z-component of torque)
// This might be better in vec2.zig if not already there.
// fn vec2Cross(v1: Vec2, v2: Vec2) f32 {
//    return v1.x * v2.y - v1.y * v2.x;
// }


test "RigidBodyComponent initialization and properties" {
    // Dynamic body
    var dynamic_rb = RigidBodyComponent.init(.Dynamic, 10.0);
    dynamic_rb.updateMassProperties(10.0, 5.0); // mass 10, inertia 5

    try std.testing.expect(dynamic_rb.body_type == .Dynamic);
    try std.testing.expect(dynamic_rb.mass == 10.0);
    try std.testing.expect(dynamic_rb.inv_mass == 0.1);
    try std.testing.expect(dynamic_rb.inertia == 5.0);
    try std.testing.expect(dynamic_rb.inv_inertia == 0.2);
    try std.testing.expect(dynamic_rb.restitution == 0.5); // Default

    // Static body
    var static_rb = RigidBodyComponent.init(.Static, 0.0); // Mass for static is effectively infinite
    static_rb.updateMassProperties(0.0, 0.0);

    try std.testing.expect(static_rb.body_type == .Static);
    try std.testing.expect(static_rb.mass == 0.0); // Represents infinite
    try std.testing.expect(static_rb.inv_mass == 0.0);
    try std.testing.expect(static_rb.inv_inertia == 0.0);

    // Kinematic body (similar to static in terms of mass properties for physics response)
    var kinematic_rb = RigidBodyComponent.init(.Kinematic, 100.0); // Mass can be set but often treated as infinite by solver for incoming forces
    kinematic_rb.updateMassProperties(100.0, 10.0); // For kinematic, inv_mass/inv_inertia usually also 0 if it's not to be pushed by dynamics
    // Let's assume kinematic also means infinite effective mass for response (but can have actual mass for pushing others)
    // This depends on physics engine interpretation. For now, same as static.
    kinematic_rb.body_type = .Kinematic; // ensure type is set
    kinematic_rb.updateMassProperties(0,0); // Treat as infinite mass/inertia for simplicity in this test against forces
    try std.testing.expect(kinematic_rb.inv_mass == 0.0);


    std.log.info("RigidBodyComponent initialization test completed.", .{});
}

test "RigidBodyComponent force and torque accumulation" {
    var rb = RigidBodyComponent.init(.Dynamic, 1.0);
    rb.updateMassProperties(1.0, 1.0); // Mass 1, Inertia 1

    // Add linear force
    rb.addForce(Vec2.new(10, 0));
    try std.testing.expect(rb.force_accumulator.x == 10.0);
    try std.testing.expect(rb.force_accumulator.y == 0.0);

    // Add torque
    rb.addTorque(5.0);
    try std.testing.expect(rb.torque_accumulator == 5.0);

    // Add force at point, generating torque
    // Force (0, 20) at point (1, 0) relative to CoM. Torque = 1*20 - 0*0 = 20
    rb.addForceAtPoint(Vec2.new(0, 20), Vec2.new(1, 0));
    try std.testing.expect(rb.force_accumulator.x == 10.0); // 10 + 0
    try std.testing.expect(rb.force_accumulator.y == 20.0); // 0 + 20
    try std.testing.expect(rb.torque_accumulator == 5.0 + 20.0); // 5 + 20

    // Clear accumulators
    rb.clearAccumulators();
    try std.testing.expect(rb.force_accumulator.x == 0.0);
    try std.testing.expect(rb.force_accumulator.y == 0.0);
    try std.testing.expect(rb.torque_accumulator == 0.0);

    // Test on static body (should not accumulate)
    var static_rb = RigidBodyComponent.init(.Static, 0.0);
    static_rb.updateMassProperties(0,0);
    static_rb.addForce(Vec2.new(100,100));
    static_rb.addTorque(100);
    try std.testing.expect(static_rb.force_accumulator.x == 0.0);
    try std.testing.expect(static_rb.torque_accumulator == 0.0);

    std.log.info("RigidBodyComponent force/torque test completed.", .{});
}
