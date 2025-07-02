// src/tools/cli.zig
// Command-line interface utilities or argument parsing for tools bundled with the framework.
// This is for tools used *by* the framework or game developer, not necessarily a game's own CLI.

const std = @import("std");

// Example: A simple argument parser.
// More robust CLI parsing would use a library or more advanced logic.
pub const ArgsParser = struct {
    allocator: std.mem.Allocator,
    args: std.ArrayList([]const u8), // Stores the command line arguments

    // Parsed options/flags could be stored here
    // options: std.StringHashMap(ArgValue),
    // pub const ArgValue = union(enum) { Str: []const u8, Bool: bool, Int: i64 };

    pub fn init(allocator_param: std.mem.Allocator) !ArgsParser {
        var self = ArgsParser{
            .allocator = allocator_param,
            .args = std.ArrayList([]const u8).init(allocator_param),
        };

        // Fetch actual command line arguments
        // std.process.argsAlloc uses the provided allocator.
        var arg_iterator = std.process.argsiterator(self.allocator);
        // Skip the first argument (program name) if desired
        // _ = arg_iterator.next();
        while (arg_iterator.next()) |arg| {
            // `arg` is owned by the iterator/allocator. If we need to keep it longer,
            // we might need to dupe it, depending on `argsiterator`'s lifetime guarantees.
            // For this example, assume `arg` slice is valid for lifetime of `argsiterator`.
            // `std.ArrayList.append` will copy the slice header, not the data itself.
            // To be safe, especially if `argsiterator` goes out of scope, dupe the string.
            try self.args.append(try self.allocator.dupe(u8, arg));
        } else |err| {
             std.log.err("Error fetching command line arguments: {any}", .{err});
             // Depending on context, this might not be a fatal error for the parser itself.
             // For now, let's propagate it.
             return err;
        }

        return self;
    }

    pub fn deinit(self: *ArgsParser) void {
        // Free the duplicated argument strings
        for (self.args.items) |arg_slice| {
            self.allocator.free(arg_slice);
        }
        self.args.deinit();
        // Deinit options map if used
    }

    pub fn getArg(self: *const ArgsParser, index: usize) ?[]const u8 {
        if (index < self.args.items.len) {
            return self.args.items[index];
        }
        return null;
    }

    pub fn count(self: *const ArgsParser) usize {
        return self.args.items.len;
    }

    // Example function to find a specific option/flag
    // e.g., findOption("--verbose") or findOptionValue("--output", "default_value.txt")
    // This requires more sophisticated parsing logic (e.g. using `std. দর্শন.ArgIterator`).
    // For now, this is a placeholder.
};


// Example of a simple CLI tool structure that might use this parser.
// This could be part of a larger CLI application (e.g., `lucie-cli` tool).
pub fn runTool(tool_name: []const u8, args: *ArgsParser) !void {
    std.debug.print("Running tool: {s}\n", .{tool_name});
    std.debug.print("Arguments received ({d}):\n", .{args.count()});
    for (args.args.items) |arg, i| {
        std.debug.print("  Arg {d}: {s}\n", .{i, arg});
    }

    // Example: Check for a "--help" flag
    for (args.args.items) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            std.debug.print("Displaying help for {s}...\n", .{tool_name});
            // Print tool-specific help text
            return;
        }
    }

    // Actual tool logic would go here based on parsed args.
    if (std.mem.eql(u8, tool_name, "greet")) {
        var name: []const u8 = "World";
        // Example: find if there's a name after "greet" command
        // This is very basic parsing. `args.getArg(0)` is usually program name.
        // If `args` list here contains only actual args *after* program name and tool name:
        if (args.getArg(0)) |arg_val| { // Assuming arg(0) is first param to tool
            name = arg_val;
        }
        std.debug.print("Hello, {s}!\n", .{name});
    } else {
        std.debug.print("Unknown tool command or functionality for '{s}' not implemented here.\n", .{tool_name});
    }
}


test "ArgsParser initialization and argument retrieval" {
    // Testing ArgsParser is tricky because it depends on actual process arguments.
    // We can't easily mock `std.process.argsiterator` directly in a test.
    // One way is to have the test executable run itself with specific arguments,
    // but that's complex for a simple unit test.

    // For this test, we'll focus on the structure assuming `args` list could be populated manually.
    // This doesn't test the `std.process.argsiterator` part.
    const allocator = std.testing.allocator;
    var parser = ArgsParser{ // Manual init for testing
        .allocator = allocator,
        .args = std.ArrayList([]const u8).init(allocator),
    };
    defer parser.deinit();

    // Simulate adding args (as if they were parsed)
    try parser.args.append(try allocator.dupe(u8, "arg1"));
    try parser.args.append(try allocator.dupe(u8, "--option"));
    try parser.args.append(try allocator.dupe(u8, "value"));

    try std.testing.expect(parser.count() == 3);
    try std.testing.expectEqualStrings("arg1", parser.getArg(0).?);
    try std.testing.expectEqualStrings("--option", parser.getArg(1).?);
    try std.testing.expectEqualStrings("value", parser.getArg(2).?);
    try std.testing.expect(parser.getArg(3) == null);

    std.log.info("ArgsParser structure test completed (manual arg population).", .{});
    // A full integration test would involve running a compiled binary with args.
}

test "runTool placeholder function" {
    // Test the example `runTool` function with a manually populated parser.
    const allocator = std.testing.allocator;
    var parser = ArgsParser{
        .allocator = allocator,
        .args = std.ArrayList([]const u8).init(allocator),
    };
    defer parser.deinit();

    // Test "greet" tool without extra args
    try runTool("greet", &parser);
    // Visual check of output: "Hello, World!"

    // Test "greet" tool with an argument
    try parser.args.append(try allocator.dupe(u8, "Ziggy"));
    try runTool("greet", &parser);
    // Visual check: "Hello, Ziggy!"
    parser.allocator.free(parser.args.pop()); // Clean up added arg

    // Test "--help" flag
    try parser.args.append(try allocator.dupe(u8, "--help"));
    try runTool("some_tool", &parser);
    // Visual check: "Displaying help for some_tool..."
    parser.allocator.free(parser.args.pop());

    std.log.info("runTool placeholder test completed.", .{});
    // This test relies on visual inspection of std.debug.print output.
    // More robust tests would capture output or check side effects.
}

// To run this as a standalone CLI for testing:
// pub fn main() !void {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer _ = gpa.deinit();
//     const allocator = gpa.allocator();
//
//     var parser = try ArgsParser.init(allocator);
//     defer parser.deinit();
//
//     if (parser.count() < 1) { // Expects at least program name, then tool name
//         std.debug.print("Usage: <cli_tool_name> [args...]\n", .{});
//         std.debug.print("Example: greet Alice\n", .{});
//         return;
//     }
//     // Assuming parser.args[0] is program name, parser.args[1] is tool name
//     const tool_name_arg = parser.getArg(1) orelse "unknown_tool";
//
//     // Create a new parser for tool-specific args (excluding prog name and tool name)
//     var tool_args_list = std.ArrayList([]const u8).init(allocator);
//     defer tool_args_list.deinit();
//     var i : usize = 2;
//     while(i < parser.count()) : (i+=1) {
//         try tool_args_list.append(try allocator.dupe(u8, parser.getArg(i).?));
//     }
//     var tool_parser = ArgsParser { // Manual construction for sub-args
//         .allocator = allocator,
//         .args = tool_args_list, // This list will be deinit'd with tool_args_list
//     };
//     // Defer for tool_parser.args items needs to be handled carefully if they are also freed by tool_args_list.deinit()
//     // For this specific structure, tool_parser doesn't need its own deinit for .args if tool_args_list handles it.
//     // Let's adjust runTool to take a slice or make ArgsParser more flexible for sub-parsing.
//
//     // Simplified for now: runTool gets all args, including program name.
//     // It should then parse out its own name and sub-arguments.
//     // Or, the main CLI dispatcher prepares args for the specific tool.
//     // Let's assume runTool gets args *after* the tool name itself.
//     // This main() is just a conceptual test harness.
//
//     try runTool(tool_name_arg, &parser); // Pass the full parser for now, tool can inspect.
// }
