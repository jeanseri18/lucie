// src/platform/window.zig
// Placeholder for windowing system interface and implementation.
// Actual implementation with a library like GLFW, SDL, etc., will be done later.

const std = @import("std");

pub const WindowError = error{
    InitFailed,
    WindowCreationFailed,
    ContextCreationFailed,
    GladLoadFailed, // Or similar for GL loading
    InvalidOperation,
    NotInitialized,
    UnknownError,
};

// ProcAddressGetter is a function pointer type for functions like glfwGetProcAddress
pub const ProcAddressGetter = *const fn (proc_name: [:0]const u8) ?*anyopaque;

pub const Window = struct {
    // Interface definition for a window
    // In a more complex scenario, this might be a `union(enum)` for different backends
    // or a vtable-like struct. For a placeholder, direct struct is fine.

    ptr: *anyopaque, // Pointer to the actual window implementation (e.g., AppWindow)
    // VTable for interface methods
    createFn: *const fn (self: *Window, allocator: std.mem.Allocator, title: []const u8, width: u32, height: u32) WindowError!void,
    destroyFn: *const fn (self: *Window) void,
    shouldCloseFn: *const fn (self: *const Window) bool,
    pollEventsFn: *const fn (self: *Window) void,
    swapBuffersFn: *const fn (self: *Window) void,
    getProcAddressFn: *const fn (self: *const Window, proc_name: [:0]const u8) ?*anyopaque,
    getSizeFn: *const fn(self: *const Window) struct{width: u32, height: u32},

    // Methods to call through the vtable
    pub fn create(self: *Window, allocator: std.mem.Allocator, title: []const u8, width: u32, height: u32) WindowError!void {
        return self.createFn(self, allocator, title, width, height);
    }
    pub fn destroy(self: *Window) void {
        return self.destroyFn(self);
    }
    pub fn shouldClose(self: *const Window) bool {
        return self.shouldCloseFn(self);
    }
    pub fn pollEvents(self: *Window) void {
        return self.pollEventsFn(self);
    }
    pub fn swapBuffers(self: *Window) void {
        return self.swapBuffersFn(self);
    }
    pub fn getProcAddress(self: *const Window, proc_name: [:0]const u8) ?*anyopaque {
        return self.getProcAddressFn(self, proc_name);
    }
    pub fn getSize(self: *const Window) struct{width: u32, height: u32} {
        return self.getSizeFn(self);
    }

    // Static function to create a new AppWindow (placeholder implementation)
    pub fn createAppWindow(allocator: std.mem.Allocator, title: []const u8, width: u32, height: u32) WindowError!Window {
        var app_window = try allocator.create(AppWindow);
        app_window.* = AppWindow.init(allocator);

        var window_interface = Window {
            .ptr = app_window,
            .createFn = AppWindow.interfaceCreate,
            .destroyFn = AppWindow.interfaceDestroy,
            .shouldCloseFn = AppWindow.interfaceShouldClose,
            .pollEventsFn = AppWindow.interfacePollEvents,
            .swapBuffersFn = AppWindow.interfaceSwapBuffers,
            .getProcAddressFn = AppWindow.interfaceGetProcAddress,
            .getSizeFn = AppWindow.interfaceGetSize,
        };
        // Call the create function on the interface to complete initialization
        try window_interface.create(allocator, title, width, height);
        return window_interface;
    }
};

// Placeholder AppWindow implementation
const AppWindow = struct {
    allocator: std.mem.Allocator,
    title: []const u8 = "",
    width: u32 = 0,
    height: u32 = 0,
    close_requested: bool = false,

    // For placeholder simulation of auto-closing
    current_poll_count: u32 = 0,
    max_poll_count_before_close: u32 = 200, // Default, can be changed for tests

    // internal_glfw_window: ?*anyopaque = null, // Example if using GLFW

    pub fn init(allocator: std.mem.Allocator) AppWindow {
        return AppWindow {
            .allocator = allocator,
            // Max polls can be configured after init if needed by tests
        };
    }

    // Implementation of create
    fn appCreate(self: *AppWindow, title_str: []const u8, w: u32, h: u32) WindowError!void {
        self.title = try self.allocator.dupe(u8, title_str);
        self.width = w;
        self.height = h;
        std.log.info("AppWindow: Created window '{s}' ({d}x{d}) (placeholder)", .{self.title, self.width, self.height});
        // TODO: Actual window creation using GLFW/SDL
        // e.g., glfwInit(), glfwCreateWindow(), glfwMakeContextCurrent()
        // e.g., SDL_Init(SDL_INIT_VIDEO), SDL_CreateWindow(), SDL_GL_CreateContext()
        // Load GL procedures here if successful context creation:
        // try gl.load(self, getProcAddress);
    }

    // Implementation of destroy
    fn appDestroy(self: *AppWindow) void {
        std.log.info("AppWindow: Destroyed window '{s}' (placeholder)", .{self.title});
        self.allocator.free(self.title);
        // TODO: Actual window destruction
        // e.g., glfwDestroyWindow(self.internal_glfw_window), glfwTerminate()
        // e.g., SDL_GL_DeleteContext(), SDL_DestroyWindow(), SDL_Quit()

        // Important: Free the AppWindow instance itself
        self.allocator.destroy(self);
    }

    // Implementation of shouldClose
    fn appShouldClose(self: *const AppWindow) bool {
        // std.log.debug("AppWindow: shouldClose check (placeholder): {any}", .{self.close_requested});
        return self.close_requested;
    }

    // Implementation of pollEvents
    fn appPollEvents(self: *AppWindow) void {
        if (self.close_requested) return;

        // std.log.debug("AppWindow: Polling events (placeholder, count: {d}/{d})", .{self.current_poll_count, self.max_poll_count_before_close});

        self.current_poll_count += 1;
        if (self.current_poll_count >= self.max_poll_count_before_close) {
            std.log.info("AppWindow: Max poll count ({d}) reached, requesting close.", .{self.max_poll_count_before_close});
            self.close_requested = true;
        }
        // In a real app, this would also dispatch events to an input manager, etc.
    }

    // Implementation of swapBuffers
    fn appSwapBuffers(self: *AppWindow) void {
        _ = self;
        // std.log.debug("AppWindow: Swapping buffers (placeholder)", .{});
        // TODO: Actual buffer swapping
        // e.g., glfwSwapBuffers(self.internal_glfw_window);
    }

    // Implementation of getProcAddress
    fn appGetProcAddress(self: *const AppWindow, proc_name: [:0]const u8) ?*anyopaque {
        _ = self;
        _ = proc_name;
        // std.log.debug("AppWindow: getProcAddress for '{s}' (placeholder, returning null)", .{proc_name});
        // TODO: Actual getProcAddress
        // e.g., return glfwGetProcAddress(proc_name);
        return null; // Placeholder, will prevent GL loading
    }

    fn appGetSize(self: *const AppWindow) struct{width: u32, height: u32} {
        return .{ .width = self.width, .height = self.height };
    }

    // Interface functions that cast ptr and call AppWindow methods
    fn interfaceCreate(window_iface: *Window, allocator: std.mem.Allocator, title: []const u8, width: u32, height: u32) WindowError!void {
        // Note: app_window's allocator is already set during init
        // The allocator passed here is for the window_interface itself or future needs.
        _ = allocator;
        const self = @ptrCast(*AppWindow, @alignCast(@alignOf(AppWindow), window_iface.ptr));
        return self.appCreate(title, width, height);
    }
    fn interfaceDestroy(window_iface: *Window) void {
        const self = @ptrCast(*AppWindow, @alignCast(@alignOf(AppWindow), window_iface.ptr));
        self.appDestroy();
    }
    fn interfaceShouldClose(window_iface: *const Window) bool {
        const self = @ptrCast(*const AppWindow, @alignCast(@alignOf(AppWindow), window_iface.ptr));
        return self.appShouldClose();
    }
    fn interfacePollEvents(window_iface: *Window) void {
        const self = @ptrCast(*AppWindow, @alignCast(@alignOf(AppWindow), window_iface.ptr));
        self.appPollEvents();
    }
    fn interfaceSwapBuffers(window_iface: *Window) void {
        const self = @ptrCast(*AppWindow, @alignCast(@alignOf(AppWindow), window_iface.ptr));
        self.appSwapBuffers();
    }
    fn interfaceGetProcAddress(window_iface: *const Window, proc_name: [:0]const u8) ?*anyopaque {
        const self = @ptrCast(*const AppWindow, @alignCast(@alignOf(AppWindow), window_iface.ptr));
        return self.appGetProcAddress(proc_name);
    }
    fn interfaceGetSize(window_iface: *const Window) struct{width: u32, height: u32} {
        const self = @ptrCast(*const AppWindow, @alignCast(@alignOf(AppWindow), window_iface.ptr));
        return self.appGetSize();
    }
};


test "AppWindow placeholder creation and lifecycle" {
    const allocator = std.testing.allocator;
    var window = try Window.createAppWindow(allocator, "Test Window", 800, 600);
    defer window.destroy();

    try std.testing.expectEqualStrings("Test Window", @ptrCast(*AppWindow, @alignCast(@alignOf(AppWindow), window.ptr)).title);
    try std.testing.expectEqual(@as(u32, 800), @ptrCast(*AppWindow, @alignCast(@alignOf(AppWindow), window.ptr)).width);

    var i: u32 = 0;
    while (!window.shouldClose() and i < 5) : (i += 1) { // Limit iterations for test
        window.pollEvents();
        // In a real app, rendering would happen here
        window.swapBuffers();
    }
    // Simulate forcing close for test if not closed by pollEvents placeholder
    @ptrCast(*AppWindow, @alignCast(@alignOf(AppWindow), window.ptr)).close_requested = true;
    try std.testing.expect(window.shouldClose());
}

test "AppWindow getProcAddress placeholder" {
    const allocator = std.testing.allocator;
    var window = try Window.createAppWindow(allocator, "Test GetProcAddress", 100, 100);
    defer window.destroy();

    const proc = window.getProcAddress("glTestFunc");
    try std.testing.expect(proc == null);
}

test "AppWindow getSize placeholder" {
    const allocator = std.testing.allocator;
    var window = try Window.createAppWindow(allocator, "Test GetSize", 320, 240);
    defer window.destroy();

    const size = window.getSize();
    try std.testing.expectEqual(@as(u32, 320), size.width);
    try std.testing.expectEqual(@as(u32, 240), size.height);
}
