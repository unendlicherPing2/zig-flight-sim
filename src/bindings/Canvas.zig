const std = @import("std");
const js = @import("zig-js");

const Context = @import("./Context.zig");

pub const Canvas = @This();

canvas: js.Object,

pub fn getContext(self: Canvas) !Context {
    return .{ .context = try self.canvas.callAlloc(js.Object, std.heap.wasm_allocator, "getContext", .{js.string("2d")}) };
}

pub fn deinit(self: Canvas) void {
    self.canvas.deinit();
}
