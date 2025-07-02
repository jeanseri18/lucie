// src/physics/physics_world.zig
// Main physics world: manages rigid bodies, colliders, and simulation steps.

const std = @import("std");
const RigidBodyComponent = @import("../ecs/components/rigidbody.zig").RigidBodyComponent;
const TransformComponent = @import("../ecs/components/transform.zig").TransformComponent;
const Collider = @import("collider.zig").Collider;
const Collision = @import("collision.zig"); // For CollisionManifold, contact resolution etc.
const Vec2 = @import("../math/vec2.zig").Vec2; // Assuming 2D physics for now

// Settings for the physics simulation
pub const PhysicsWorldSettings = struct {
    gravity: Vec2 = Vec2.new(0, -9.81), // Default Earth gravity (m/s^2)
    time_step: f32 = 1.0 / 60.0,       // Fixed time step for simulation (e.g., 60Hz)
    velocity_iterations: u32 = 8,    // Solver iterations for velocity constraints
    position_iterations: u32 = 3,    // Solver iterations for position constraints (overlap resolution)
    // restitution_threshold: f32 = 1.0, // Velocity threshold for restitution to apply
    // sleep_epsilon: f32 = 0.05, // Energy threshold for bodies to fall asleep
};

// In a real physics engine, bodies and colliders would be registered with the world.
// The world would then use a broadphase (e.g., spatial hash grid, BVH tree) to find potential
// collision pairs, then a narrowphase to confirm collisions and generate contact points.
// Finally, a solver resolves these contacts and other constraints.

// This placeholder will be very simplified.
pub const PhysicsWorld = struct {
    allocator: std.mem.Allocator,
    settings: PhysicsWorldSettings,

    // Storage for physics objects.
    // In an ECS context, the PhysicsWorld might query entities with RigidBodyComponent and ColliderComponent.
    // For a standalone physics engine, it would have its own lists of bodies/colliders.
    // Let's assume it operates on components queried from an ECS World for now.
    // This means the PhysicsWorld itself doesn't "own" the RigidBodyComponents or Colliders,
    // but rather pointers or references to them obtained during the update step.

    // For this placeholder, we'll simulate a list of active rigid bodies.
    // In a real scenario, these would be references to ECS components.
    // active_bodies: std.ArrayList(*RigidBodyComponent),
    // active_transforms: std.ArrayList(*TransformComponent),
    // active_colliders: std.ArrayList(*Collider),

    // Accumulator for fixed time step simulation
    time_accumulator: f32 = 0.0,

    pub fn init(allocator_param: std.mem.Allocator, settings_param: PhysicsWorldSettings) PhysicsWorld {
        std.log.debug("Initializing PhysicsWorld...", .{});
        return PhysicsWorld{
            .allocator = allocator_param,
            .settings = settings_param,
            // .active_bodies = std.ArrayList(*RigidBodyComponent).init(allocator_param),
            // .active_transforms = std.ArrayList(*TransformComponent).init(allocator_param),
            // .active_colliders = std.ArrayList(*Collider).init(allocator_param),
        };
    }

    pub fn deinit(self: *PhysicsWorld) void {
        std.log.debug("Deinitializing PhysicsWorld...", .{});
        // self.active_bodies.deinit();
        // self.active_transforms.deinit();
        // self.active_colliders.deinit();
        _ = self; // Nothing to deinit if not owning the lists.
    }

    // Main simulation step.
    // `dt` is the frame delta time. The world uses a fixed internal time_step.
    // `bodies`, `transforms`, `colliders` would be slices of components from the ECS.
    pub fn step(
        self: *PhysicsWorld,
        dt: f32,
        // Assuming these are mutable slices of components from the ECS.
        // This is a simplified way to pass data from ECS to physics.
        // A real system might use queries or direct access to archetype data.
        ecs_world: ?*@import("../ecs/world.zig").World, // Pass the ECS world for component access
        // For testing, we can pass dummy slices.
        // For now, this function will be a placeholder for the simulation loop.
        // It would typically:
        // 1. Integrate forces and update velocities.
        // 2. Perform collision detection (broadphase, narrowphase).
        // 3. Resolve collisions and constraints (solver).
        // 4. Integrate velocities and update positions.
        // 5. Clear forces.
    ) void {
        _ = dt; _=ecs_world; // Mark as used for now
        // std.log.debug("PhysicsWorld.step (dt: {d:.4})", .{dt});

        self.time_accumulator += dt;
        while (self.time_accumulator >= self.settings.time_step) {
            self.internalFixedUpdate(self.settings.time_step, ecs_world);
            self.time_accumulator -= self.settings.time_step;
        }
    }

    fn internalFixedUpdate(self: *PhysicsWorld, fixed_dt: f32, ecs_world: ?*@import("../ecs/world.zig").World) void {
        // std.log.debug("PhysicsWorld.internalFixedUpdate (fixed_dt: {d:.4})", .{fixed_dt});
        if (ecs_world == null) return;
        const world = ecs_world.?; // Assume it's valid for this internal step

        // --- 1. Apply forces (e.g., gravity) ---
        // Iterate all dynamic rigid bodies
        // For entity_idx in 0..world.entities.items.len:
        //    const entity = world.entities.items[entity_idx];
        //    var rb = world.getComponent(entity, RigidBodyComponent);
        //    if (rb != null and rb.?.body_type == .Dynamic and rb.?.is_gravity_enabled) {
        //        rb.?.addForce(self.settings.gravity.scale(rb.?.mass));
        //    }
        // This is a placeholder for actual ECS query and component access.

        // --- 2. Integrate forces and update velocities (Symplectic Euler step 1) ---
        // For each dynamic body:
        //    var rb = ... ; var transform = ... ;
        //    if (rb.body_type == .Dynamic) {
        //        // Linear velocity
        //        const linear_acceleration = rb.force_accumulator.scale(rb.inv_mass);
        //        rb.linear_velocity = rb.linear_velocity.add(linear_acceleration.scale(fixed_dt));
        //        rb.linear_velocity = rb.linear_velocity.scale(1.0 - fixed_dt * rb.linear_damping); // Apply damping
        //
        //        // Angular velocity
        //        const angular_acceleration = rb.torque_accumulator * rb.inv_inertia;
        //        rb.angular_velocity += angular_acceleration * fixed_dt;
        //        rb.angular_velocity *= (1.0 - fixed_dt * rb.angular_damping); // Apply damping
        //    }

        // --- 3. Collision Detection (Broadphase + Narrowphase) ---
        // This is the most complex part.
        // var collision_manifolds = std.ArrayList(Collision.CollisionManifold).init(self.allocator);
        // defer collision_manifolds.deinit();
        // For every pair of colliders (i, j) where i < j:
        //    collider_i = ...; collider_j = ...;
        //    transform_i = ...; transform_j = ...;
        //    if (Collision.checkCollision(collider_i, transform_i, collider_j, transform_j)) |manifold| {
        //        try collision_manifolds.append(manifold);
        //    }
        // A broadphase would optimize finding pairs.

        // --- 4. Collision Resolution (Solver) ---
        // For self.settings.velocity_iterations:
        //    For each manifold in collision_manifolds:
        //        Collision.resolveVelocity(manifold, rb_i, rb_j, fixed_dt); // Updates velocities
        // For self.settings.position_iterations:
        //    For each manifold in collision_manifolds:
        //        Collision.resolvePosition(manifold, transform_i, transform_j, rb_i, rb_j); // Corrects positions directly

        // --- 5. Integrate velocities and update positions (Symplectic Euler step 2) ---
        // For each dynamic/kinematic body:
        //    var rb = ... ; var transform = ... ;
        //    transform.position = transform.position.add(rb.linear_velocity.scale(fixed_dt));
        //    // Update rotation (2D example: angle += angular_velocity * dt)
        //    // If transform.rotation is Quaternion:
        //    const angle_change = rb.angular_velocity * fixed_dt;
        //    const rotation_delta_quat = Quaternion.fromAxisAngle(Vec3.z_axis(), angle_change); // Assuming 2D rotation around Z
        //    transform.rotation = rotation_delta_quat.mul(transform.rotation).normalize();
        //    // transform.setDirty(); // If transform caches its matrix

        // --- 6. Clear forces and torques ---
        // For each dynamic body:
        //    rb.clearAccumulators();

        // Placeholder log for fixed update
        _ = fixed_dt; _ = world; // Mark as used
        // std.log.debug("PhysicsWorld fixed update completed for this step.",.{});
    }
};

test "PhysicsWorld initialization" {
    const allocator = std.testing.allocator;
    const settings = PhysicsWorldSettings{}; // Default settings
    var world = PhysicsWorld.init(allocator, settings);
    defer world.deinit();

    try std.testing.expect(world.settings.gravity.y == -9.81);
    try std.testing.expect(world.time_accumulator == 0.0);

    std.log.info("PhysicsWorld initialization test completed.", .{});
}

test "PhysicsWorld step accumulation" {
    const allocator = std.testing.allocator;
    var settings = PhysicsWorldSettings{ .time_step = 0.1 }; // Easier to test accumulation
    var p_world = PhysicsWorld.init(allocator, settings);
    defer p_world.deinit();

    // Mock ECS world for the step function (not actually used by placeholder internalFixedUpdate)
    var ecs_placeholder_world = @import("../ecs/world.zig").World.init(allocator);
    defer ecs_placeholder_world.deinit();

    // First step, dt < time_step
    p_world.step(0.05, &ecs_placeholder_world);
    try std.testing.expect(std.math.approxEqAbs(p_world.time_accumulator, 0.05, 0.0001));
    // internalFixedUpdate should not have run yet.

    // Second step, accumulator now >= time_step
    p_world.step(0.05, &ecs_placeholder_world); // Total dt = 0.1
    // internalFixedUpdate should run once. Accumulator becomes 0.0.
    try std.testing.expect(std.math.approxEqAbs(p_world.time_accumulator, 0.0, 0.0001));

    // Third step, dt causes multiple fixed updates
    p_world.step(0.25, &ecs_placeholder_world); // Accumulator = 0.25. Should run fixed update twice.
    // 0.25 -> 0.15 (1st run) -> 0.05 (2nd run). Accumulator = 0.05.
    try std.testing.expect(std.math.approxEqAbs(p_world.time_accumulator, 0.05, 0.0001));

    std.log.info("PhysicsWorld step accumulation test completed.", .{});
    // Note: This test doesn't verify `internalFixedUpdate` calls directly, only accumulator logic.
    // A more complex test would need to mock/spy on `internalFixedUpdate` or check its side effects.
}
