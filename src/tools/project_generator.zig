// src/tools/project_generator.zig
// Tool for generating new game project skeletons based on the Lucie framework.

const std = @import("std");
const fs = std.fs;

pub const ProjectGenerator = struct {
    allocator: std.mem.Allocator,
    project_name: []const u8,
    project_path: []const u8, // Full path to the new project directory

    // Options for generation
    // use_git: bool = true,
    // include_examples: bool = false,
    // framework_path_reference: ?[]const u8 = null, // For referencing framework in build.zig

    pub fn init(allocator_param: std.mem.Allocator, name: []const u8, path_prefix: ?[]const u8) !ProjectGenerator {
        // Sanitize project name (e.g., replace spaces, ensure valid directory name)
        // For now, assume name is simple (e.g., "MyGame")
        const sanitized_name = try allocator_param.dupe(u8, name); // Simple dupe for now

        // Determine full project path
        var full_path_list = std.ArrayList(u8).init(allocator_param);
        defer full_path_list.deinit();

        if (path_prefix) |prefix| {
            try full_path_list.appendSlice(prefix);
            if (!std.mem.endsWith(u8, prefix, fs.path.sep_str)) {
                try full_path_list.appendSlice(fs.path.sep_str);
            }
        }
        try full_path_list.appendSlice(sanitized_name);
        const project_full_path = try full_path_list.toOwnedSlice(); // Owned by full_path_list, then moved/duped

        return ProjectGenerator{
            .allocator = allocator_param,
            .project_name = sanitized_name,
            .project_path = project_full_path, // This needs to be owned by ProjectGenerator
                                               // Or ProjectGenerator's lifetime tied to `full_path_list`
                                               // Let's dupe it for safety.
                                               // project_path: try allocator_param.dupe(u8, project_full_path),
                                               // allocator_param.free(project_full_path); // if toOwnedSlice was used
                                               // Simpler: let project_path also be owned by ProjectGenerator directly
        };
    }

    // If project_name and project_path are owned, need deinit
    pub fn deinit(self: *ProjectGenerator) void {
        self.allocator.free(self.project_name);
        self.allocator.free(self.project_path);
    }


    pub fn generate(self: *const ProjectGenerator) !void {
        std.log.info("Generating new Lucie project: '{s}' at '{s}'", .{self.project_name, self.project_path});

        // 1. Create project directory
        try fs.cwd().makeDir(self.project_path);
        std.log.debug("Created directory: {s}", .{self.project_path});

        // 2. Create subdirectories (e.g., src, assets)
        const subdirs = [_][]const u8{ "src", "assets" };
        for (subdirs) |subdir_name| {
            const subdir_path = try fs.path.join(self.allocator, &[_][]const u8{self.project_path, subdir_name});
            defer self.allocator.free(subdir_path);
            try fs.cwd().makeDir(subdir_path);
            std.log.debug("Created subdirectory: {s}", .{subdir_path});
        }

        // 3. Create basic files (build.zig, build.zig.zon, src/main.zig, .gitignore)
        try self.createBuildZig();
        try self.createBuildZigZon();
        try self.createMainZig();
        try self.createGitignore();
        // try self.createReadme(); // Optional README for the new project

        // 4. Optional: Initialize Git repository
        // if (self.use_git) {
        //    try self.initGitRepository();
        // }

        std.log.info("Project '{s}' generated successfully!", .{self.project_name});
    }

    fn createBuildZig(self: *const ProjectGenerator) !void {
        const file_path = try fs.path.join(self.allocator, &[_][]const u8{self.project_path, "build.zig"});
        defer self.allocator.free(file_path);

        var file = try fs.cwd().createFile(file_path, .{});
        defer file.close();

        // Basic build.zig content
        // This needs to correctly reference the Lucie framework.
        // If Lucie is a local path: `const lucie_dep = b.dependency("../lucie", .{});`
        // If Lucie is a URL: `const lucie_dep = b.dependency("lucie", .{ .url = "...", .hash = "..."});`
        // For now, assume a placeholder for framework path.
        const lucie_framework_path = "../lucie"; // Placeholder, should be configurable

        const content_template =
            \\const std = @import("std");
            \\
            \\pub fn build(b: *std.Build) void {
            \\    const target = b.standardTargetOptions(.{{}});
            \\    const optimize = b.standardOptimizeOption(.{{}});
            \\
            \\    // Reference to Lucie Framework (adjust path or use package manager)
            \\    const lucie_dep = b.dependency("{s}", .{{ // Assuming path-based dependency
            \\        // .target = target,
            \\        // .optimize = optimize,
            \\    }});
            \\    const lucie_module = lucie_dep.module("lucie");
            \\
            \\    const exe = b.addExecutable(.{{
            \\        .name = "{s}",
            \\        .root_source_file = .{{ .path = "src/main.zig" }},
            \\        .target = target,
            \\        .optimize = optimize,
            \\    }});
            \\
            \\    exe.addModule("lucie", lucie_module);
            \\    // Link other necessary system libraries if Lucie requires them (e.g., for graphics, audio)
            \\    // exe.linkSystemLibrary("...");
            \\
            \\    b.installArtifact(exe);
            \\
            \\    const run_cmd = b.addRunArtifact(exe);
            \\    run_cmd.step.dependOn(b.getInstallStep());
            \\    if (b.args) |args| {
            \\        run_cmd.addArgs(args);
            \\    }
            \\
            \\    const run_step = b.step("run", "Run the app");
            \\    run_step.dependOn(&run_cmd.step);
            \\
            \\    // Example test step (if you have tests in your game project)
            \\    // const main_tests = b.addTest(.{{
            \\    //     .root_source_file = .{{ .path = "src/main.zig" }},
            \\    //     .target = target,
            \\    //     .optimize = optimize,
            \\    // }});
            \\    // main_tests.addModule("lucie", lucie_module);
            \\    // const test_step = b.step("test", "Run tests");
            \\    // test_step.dependOn(&main_tests.step);
            \\}
            \\
        ;
        try file.writer().print(content_template, .{ lucie_framework_path, self.project_name });
        std.log.debug("Created file: {s}", .{file_path});
    }

    fn createBuildZigZon(self: *const ProjectGenerator) !void {
        const file_path = try fs.path.join(self.allocator, &[_][]const u8{self.project_path, "build.zig.zon"});
        defer self.allocator.free(file_path);

        var file = try fs.cwd().createFile(file_path, .{});
        defer file.close();

        const content_template =
            \\{{
            \\    .name = "{s}",
            \\    .version = "0.1.0",
            \\    .dependencies = .{{
            \\        // Define Lucie framework dependency here if not path-based in build.zig
            \\        // .lucie = .{{
            \\        //     .url = "https://github.com/user/lucie-framework/archive/refs/tags/v0.1.0.tar.gz", // Example URL
            \\        //     .hash = "...", // SHA256 hash of the tarball
            \\        // }},
            \\    }},
            \\    .paths = .{{
            \\        "build.zig",
            \\        "build.zig.zon",
            \\        "src",
            \\        // "assets", // Add assets dir if needed by build system
            \\    }},
            \\}}
            \\
        ;
        try file.writer().print(content_template, .{self.project_name});
        std.log.debug("Created file: {s}", .{file_path});
    }

    fn createMainZig(self: *const ProjectGenerator) !void {
        const src_dir = try fs.path.join(self.allocator, &[_][]const u8{self.project_path, "src"});
        defer self.allocator.free(src_dir);
        const file_path = try fs.path.join(self.allocator, &[_][]const u8{src_dir, "main.zig"});
        defer self.allocator.free(file_path);

        var file = try fs.cwd().createFile(file_path, .{});
        defer file.close();

        const content =
            \\const std = @import("std");
            \\const lucie = @import("lucie"); // Assuming 'lucie' module is available via build.zig
            \\
            \\pub fn main() !void {
            \\    std.log.info("Starting {s}...", .{{@tagName(main)}}); // Project name can be passed if needed
            \\
            \\    // Initialize Lucie application
            \\    // Ensure your system's GeneralPurposeAllocator is appropriate, or use a specific one.
            \\    var gpa = std.heap.GeneralPurposeAllocator(.{{}}){};
            \\    defer _ = gpa.deinit(); // Check for leaks
            \\    const app_allocator = gpa.allocator();
            \\
            \\    var app = try lucie.Application.init(app_allocator);
            \\    defer app.deinit();
            \\
            \\    std.log.info("Application initialized. Entering main loop.", .{{}});
            \\
            \\    // Main game loop
            \\    while (app.isRunning()) {
            \\        // Process input
            \\        // input_manager.prepareFrame(); // If using InputManager globally
            \\        // pollEvents(); // Window events that update InputManager
            \\
            \\        // Update game logic
            \\        try app.update(); // This would call engine.update(), ECS system updates, etc.
            \\
            \\        // Render frame
            \\        try app.render(); // This would call engine.render()
            \\
            \\        // Temporary: Stop after a few iterations for console apps without window events.
            \\        // In a real game, app.isRunning() would depend on window close events or game state.
            \\        // For this template, let's make it run for a short while then exit.
            \\        // static var frame_count: u32 = 0;
            \\        // frame_count += 1;
            \\        // if (frame_count > 300) { // Run for ~5 seconds at 60fps
            \\        //     app.stop();
            \\        // }
            \\    }
            \\
            \\    std.log.info("Exiting {s}.", .{{@tagName(main)}});
            \\}
            \\
            \\test "basic test" {{
            \\    try std.testing.expect(true);
            \\}}
            \\
        ;
        // Using @tagName(main) is a trick to get the current function name string,
        // but for project name, self.project_name should be used.
        // std.fmt.format needs an allocator for formatting strings with runtime values.
        // For simplicity, keeping template basic or using fixed strings.
        // Let's use a simpler log message for now.
        const main_content_simple = std.fmt.allocPrint(self.allocator,
            comptime
            \\const std = @import("std");
            \\const lucie = @import("lucie");
            \\
            \\pub fn main() !void {{
            \\    std.log.info("Starting {s} (Lucie Project Template)...", .{{ "{s}" }});
            \\    var gpa = std.heap.GeneralPurposeAllocator(.{{}}){{}};
            \\    defer _ = gpa.deinit();
            \\    const app_allocator = gpa.allocator();
            \\    var app = try lucie.Application.init(app_allocator);
            \\    defer app.deinit();
            \\    while (app.isRunning()) {{
            \\        try app.update();
            \\        try app.render();
            \\        // Placeholder: Add logic to stop the app, e.g., via input or timer for console
            \\        // For now, a real app would need window event handling to stop.
            \\        // To make it runnable as a console test:
            \\        // app.stop(); // uncomment to run once and exit
            \\    }}
            \\    std.log.info("Exiting {s}.", .{{ "{s}" }});
            \\}}
            \\test "basic test" {{ try std.testing.expect(true); }}
            \\
            , .{ self.project_name, self.project_name, self.project_name }) catch unreachable; // Should not fail with basic format
        defer self.allocator.free(main_content_simple);

        try file.writer().writeAll(main_content_simple);
        std.log.debug("Created file: {s}", .{file_path});
    }

    fn createGitignore(self: *const ProjectGenerator) !void {
        const file_path = try fs.path.join(self.allocator, &[_][]const u8{self.project_path, ".gitignore"});
        defer self.allocator.free(file_path);

        var file = try fs.cwd().createFile(file_path, .{});
        defer file.close();

        const content =
            \\# Zig build artifacts
            \\zig-cache/
            \\zig-out/
            \\
            \\# User-specific files (e.g., IDE settings)
            \\.vscode/
            \\.idea/
            \\*.user
            \\*.suo
            \\
            \\# OS generated files
            \\.DS_Store
            \\Thumbs.db
            \\
            \\# Log files
            \\*.log
            \\
            \\# TODO: Add any other project-specific ignores
            \\
        ;
        try file.writer().writeAll(content);
        std.log.debug("Created file: {s}", .{file_path});
    }

    // fn initGitRepository(self: *const ProjectGenerator) !void {
    //     // Requires git to be installed and in PATH.
    //     // std.ChildProcess can be used to run `git init` in the project directory.
    //     std.log.info("Initializing Git repository in {s}...", .{self.project_path});
    //     var proc = std.ChildProcess.init(&[_][]const u8{"git", "init"}, self.allocator);
    //     proc.cwd = self.project_path; // Set working directory for the command
    //     const term = try proc.spawnAndWait();
    //     if (term.Exited == 0) {
    //         std.log.info("Git repository initialized.", .{});
    //     } else {
    //         std.log.err("Failed to initialize Git repository. `git init` exit code: {d}", .{term.Exited});
    //         // Optionally, try to get stderr from proc.stderr_bytes
    //     }
    // }
};

test "ProjectGenerator initialization and structure creation" {
    const allocator = std.testing.allocator;
    const test_proj_name = "TestLucieGame";
    const test_base_dir = "./temp_test_projects"; // Create in a temporary location

    // Ensure base dir exists for the test
    fs.cwd().makeDir(test_base_dir) catch {}; // Ignore error if already exists

    var generator = try ProjectGenerator.init(allocator, test_proj_name, test_base_dir);
    defer generator.deinit(); // Frees project_name and project_path

    const expected_proj_path_list = try std.ArrayList(u8).init(allocator);
    defer expected_proj_path_list.deinit();
    try expected_proj_path_list.appendSlice(test_base_dir);
    try expected_proj_path_list.appendSlice(fs.path.sep_str);
    try expected_proj_path_list.appendSlice(test_proj_name);
    const expected_proj_path = expected_proj_path_list.items;

    try std.testing.expectEqualStrings(test_proj_name, generator.project_name);
    try std.testing.expectEqualStrings(expected_proj_path, generator.project_path);

    // Generate the project
    // This creates actual files and directories. Clean up afterwards.
    try generator.generate();

    // Check if main directory and some key files/subdirs exist
    try std.testing.expect(fs.cwd().access(generator.project_path, .{}) == .ok);
    const src_path = try fs.path.join(allocator, &[_][]const u8{generator.project_path, "src"});
    defer allocator.free(src_path);
    try std.testing.expect(fs.cwd().access(src_path, .{}) == .ok);

    const main_zig_path = try fs.path.join(allocator, &[_][]const u8{src_path, "main.zig"});
    defer allocator.free(main_zig_path);
    try std.testing.expect(fs.cwd().access(main_zig_path, .{}) == .ok);

    const build_zig_path = try fs.path.join(allocator, &[_][]const u8{generator.project_path, "build.zig"});
    defer allocator.free(build_zig_path);
    try std.testing.expect(fs.cwd().access(build_zig_path, .{}) == .ok);

    std.log.info("ProjectGenerator generate test completed. Project at: {s}", .{generator.project_path});

    // Cleanup: Remove the generated project directory
    // fs.cwd().deleteTree(generator.project_path) catch |err| {
    //    std.log.warn("Failed to cleanup test project '{s}': {any}", .{generator.project_path, err});
    // };
    // For safety in tests, manual cleanup might be preferred or use a dedicated test sandbox.
    // std.fs.deleteTree is powerful.
    // Let's delete individual files/dirs created for more control if needed, or just the top dir.
    // This requires careful implementation if tests run in parallel or have shared state.
    // For now, the test implies manual cleanup or relies on sandbox behavior.
    // If running locally, this will leave `temp_test_projects/TestLucieGame` directory.
}
