const js = @import("zig-js");

pub const Context = @This();

context: js.Object,

pub fn deinit(self: Context) void {
    self.context.deinit();
}

pub fn fillRect(self: Context, x: f64, y: f64, width: f64, height: f64) !void {
    try self.context.call(void, "fillRect", .{ x, y, width, height });
}
