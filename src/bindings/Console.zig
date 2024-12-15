const js = @import("zig-js");

pub const Console = @This();

object: js.Object,

pub fn log(self: Console, message: []const u8) !void {
    try self.object.call(void, "log", .{js.string(message)});
}

pub fn deinit(self: Console) void {
    self.object.deinit();
}
