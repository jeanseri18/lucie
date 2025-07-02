// src/tools/hot_reload.zig
// Utilities for hot reloading assets or code.
// This is a complex feature and this will be a very basic placeholder.

const std = @import("std");
const fs = std.fs;

// --- Hot Reloading for Assets ---

// Asset types that might be hot-reloadable
pub const ReloadableAssetType = enum {
    Texture,
    Shader, // GLSL/SPIR-V shaders
    Script, // e.g., Lua, Python, or custom scripting language
    JsonConfig, // Generic JSON configuration files
    // Model, // Models can be complex to hot reload seamlessly
    // Sound, // Sounds might be reloadable but less common for hot reload during gameplay
};

// Event structure for an asset change notification
pub const AssetChangeEvent = struct {
    path: []const u8, // Path to the changed asset (relative to asset root)
    asset_type: ReloadableAssetType,
    // timestamp: i64, // Modification timestamp
};

// FileWatcher observes a directory for changes.
// This is a simplified watcher. Real implementations use OS-specific APIs
// (inotify on Linux, FSEvents on macOS, ReadDirectoryChangesW on Windows)
// or polling for cross-platform simplicity with some latency.
pub const FileWatcher = struct {
    allocator: std.mem.Allocator,
    watch_path: []const u8, // Directory to watch

    // Stores last known modification times for files being watched.
    // Key: relative file path, Value: last modification timestamp (e.g., from fs.File.stat().mtime)
    file_timestamps: std.StringHashMap(i64),

    // Polling interval if not using OS events
    // poll_interval_ms: u32 = 1000, // e.g., check every 1 second
    // last_poll_time: i64,

    // Callback for when a file changes
    // on_file_changed_fn: ?fn(context: ?*anyopaque, path: []const u8) void = null,
    // on_file_changed_context: ?*anyopaque = null,

    pub fn init(allocator_param: std.mem.Allocator, path_to_watch: []const u8) !FileWatcher {
        // Ensure path_to_watch is a directory
        const stat = try fs.cwd().statFile(path_to_watch);
        if (stat.kind != .Directory) {
            std.log.err("FileWatcher: Path '{s}' is not a directory.", .{path_to_watch});
            return error.NotADirectory;
        }

        return FileWatcher{
            .allocator = allocator_param,
            .watch_path = try allocator_param.dupe(u8, path_to_watch),
            .file_timestamps = std.StringHashMap(i64).init(allocator_param),
            // .last_poll_time = std.time.nanoTimestamp(),
        };
    }

    pub fn deinit(self: *FileWatcher) void {
        self.allocator.free(self.watch_path);
        // Free keys in StringHashMap if they were allocated
        var key_it = self.file_timestamps.keyIterator();
        while (key_it.next()) |key_ptr| {
            self.allocator.free(key_ptr.*);
        }
        self.file_timestamps.deinit();
    }

    // Scans the watched directory and subdirectories for changes (polling approach).
    // Returns a list of changed file paths (relative to watch_path).
    pub fn pollForChanges(self: *FileWatcher) !std.ArrayList([]const u8) {
        var changed_files = std.ArrayList([]const u8).init(self.allocator);
        // This is a simplified recursive scan. A real one needs to handle errors, symlinks etc.
        try self.scanDirectoryRecursive(self.watch_path, "", &changed_files);
        return changed_files;
    }

    fn scanDirectoryRecursive(
        self: *FileWatcher,
        base_dir_abs: []const u8, // Absolute path to current directory being scanned
        current_rel_path: []const u8, // Path relative to self.watch_path
        changed_files_list: *std.ArrayList([]const u8),
    ) !void {
        var dir = try fs.cwd().openDir(base_dir_abs, .{ .iterate = true });
        defer dir.close();

        var iterator = dir.iterate();
        while (try iterator.next()) |entry| {
            const entry_abs_path = try fs.path.join(self.allocator, &[_][]const u8{base_dir_abs, entry.name});
            defer self.allocator.free(entry_abs_path);

            const entry_rel_path_list = if (current_rel_path.len == 0)
                std.ArrayList(u8).fromOwnedSlice(self.allocator, try self.allocator.dupe(u8, entry.name)) catch unreachable
            else
                std.ArrayList(u8).fromOwnedSlice(self.allocator, try fs.path.join(self.allocator, &[_][]const u8{current_rel_path, entry.name})) catch unreachable;
            defer entry_rel_path_list.deinit();
            const entry_rel_path = entry_rel_path_list.items;


            const stat = try fs.cwd().statFile(entry_abs_path);
            if (stat.kind == .Directory) {
                try self.scanDirectoryRecursive(entry_abs_path, entry_rel_path, changed_files_list);
            } else if (stat.kind == .File) {
                const current_mtime = stat.mtime;
                const existing_entry = self.file_timestamps.getEntry(entry_rel_path);

                if (existing_entry) |e| {
                    if (e.value_ptr.* != current_mtime) {
                        std.log.debug("File changed: {s} (mtime {d} -> {d})", .{entry_rel_path, e.value_ptr.*, current_mtime});
                        e.value_ptr.* = current_mtime; // Update timestamp
                        try changed_files_list.append(try self.allocator.dupe(u8, entry_rel_path));
                    }
                } else {
                    // New file found
                    std.log.debug("New file detected: {s} (mtime {d})", .{entry_rel_path, current_mtime});
                    // Need to dupe entry_rel_path as it's from a temporary list.
                    const owned_rel_path = try self.allocator.dupe(u8, entry_rel_path);
                    try self.file_timestamps.put(owned_rel_path, current_mtime);
                    // Optionally, report new files as "changed"
                    // try changed_files_list.append(try self.allocator.dupe(u8, entry_rel_path)));
                }
            }
        }
        // TODO: Handle deleted files (files in file_timestamps but not found in scan)
    }
};

// HotReloadManager would use FileWatcher and dispatch AssetChangeEvents.
// pub const HotReloadManager = struct { ... };


// --- Hot Reloading for Code (Zig) ---
// Hot reloading Zig code is very advanced. It typically involves:
// 1. Compiling changed code into a dynamic library (.so, .dll, .dylib).
// 2. The main application loading this library.
// 3. A mechanism to transfer state from the old code to the new code.
// 4. Replacing function pointers or re-linking parts of the application.
//
// This is far beyond a simple utility and often requires specific architectural choices.
// Zig's comptime and build system flexibility can aid this, but it's not trivial.
// `std.dynamic_library.DynamicLibrary` can be used to load/unload shared libraries.
//
// For this placeholder, we'll just acknowledge its complexity.
pub const CodeHotReloader = struct {
    // Placeholder. Real implementation would be complex.
    pub fn checkForUpdatesAndReload() !bool { // Returns true if reload occurred
        std.log.info("CodeHotReloader: Checking for code updates (placeholder - always no updates).", .{});
        // 1. Check if a new version of a dynamic library is available.
        // 2. If yes, load it (e.g., `std.dynamic_library.open`).
        // 3. Get function pointers to new functions/entry points.
        // 4. Transfer state if possible/needed.
        // 5. Unload the old library.
        // 6. Update application's function pointers to use new code.
        return false;
    }
};


test "FileWatcher initialization (placeholder)" {
    const allocator = std.testing.allocator;
    const temp_watch_dir = "./temp_watch_dir_hr";

    // Create dummy directory for watching
    fs.cwd().makeDir(temp_watch_dir) catch |err| {
        // If it already exists from a previous failed test, try to clean it.
        if (err == error.PathAlreadyExists) {
            fs.cwd().deleteTree(temp_watch_dir) catch {}; // Ignore cleanup error
            fs.cwd().makeDir(temp_watch_dir) catch |e2| {
                 std.log.err("Failed to create temp_watch_dir for test even after cleanup: {any}", .{e2});
                 return; // Cannot run test
            };
        } else {
            std.log.err("Failed to create temp_watch_dir for test: {any}", .{err});
            return; // Cannot run test
        }
    };
    defer fs.cwd().deleteTree(temp_watch_dir) catch {}; // Cleanup

    var watcher = try FileWatcher.init(allocator, temp_watch_dir);
    defer watcher.deinit();

    try std.testing.expectEqualStrings(temp_watch_dir, watcher.watch_path);
    try std.testing.expect(watcher.file_timestamps.count() == 0);

    std.log.info("FileWatcher initialization test completed.", .{});
}

test "FileWatcher pollForChanges (basic file creation/modification)" {
    const allocator = std.testing.allocator;
    const base_dir = "./temp_poll_test";
    try fs.cwd().makeDir(base_dir) catch { // Ensure clean slate or create
        fs.cwd().deleteTree(base_dir) catch {};
        try fs.cwd().makeDir(base_dir);
    };
    defer fs.cwd().deleteTree(base_dir) catch {};

    var watcher = try FileWatcher.init(allocator, base_dir);
    defer watcher.deinit();

    // --- Initial scan (should find no changes, but populate timestamps for new files) ---
    var initial_changes = try watcher.pollForChanges();
    defer { for(initial_changes.items) |item_path| allocator.free(item_path); initial_changes.deinit(); }
    try std.testing.expect(initial_changes.items.len == 0); // No "changes" on first poll, just discovery.

    // --- Create a new file ---
    const file1_rel_path = "file1.txt";
    const file1_abs_path = try fs.path.join(allocator, &[_][]const u8{base_dir, file1_rel_path});
    defer allocator.free(file1_abs_path);
    var file1 = try fs.cwd().createFile(file1_abs_path, .{});
    try file1.writeAll("hello");
    file1.close();

    // Poll again: file1 should be detected (as new, or changed if initial poll adds it)
    // The current `scanDirectoryRecursive` adds new files to `file_timestamps` but doesn't report them as "changed"
    // on the first discovery poll. A subsequent poll after mtime update would.
    // Let's test that behavior. First poll discovers it.
    var changes_after_create = try watcher.pollForChanges();
    defer { for(changes_after_create.items) |p| allocator.free(p); changes_after_create.deinit(); }
    // If new files are not reported as "changed" immediately:
    try std.testing.expect(changes_after_create.items.len == 0);
    try std.testing.expect(watcher.file_timestamps.contains(file1_rel_path));


    // --- Modify the file (update mtime) ---
    // std.time.sleep(1 * std.time.ns_per_s); // Ensure mtime is different if resolution is low. Not always reliable.
    // Re-opening and writing usually updates mtime.
    file1 = try fs.cwd().openFile(file1_abs_path, .{ .mode = .write_only, .truncate = false });
    try file1.writer().writeAll(" world"); // Append
    file1.close();

    var changes_after_modify = try watcher.pollForChanges();
    defer { for(changes_after_modify.items) |p| allocator.free(p); changes_after_modify.deinit(); }
    try std.testing.expect(changes_after_modify.items.len == 1);
    if (changes_after_modify.items.len == 1) {
        try std.testing.expectEqualStrings(file1_rel_path, changes_after_modify.items[0]);
    }

    std.log.info("FileWatcher pollForChanges test completed.", .{});
}

test "CodeHotReloader placeholder" {
    // This is just a placeholder test.
    const reloaded = CodeHotReloader.checkForUpdatesAndReload() catch |err| {
        std.log.err("CodeHotReloader.checkForUpdatesAndReload failed: {any}", .{err});
        try std.testing.expect(false); // Should not fail in placeholder
        return;
    };
    try std.testing.expect(reloaded == false); // Placeholder always returns false
    std.log.info("CodeHotReloader placeholder test completed.", .{});
}
