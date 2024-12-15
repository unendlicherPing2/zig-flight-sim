const js = @import("zig-js");
const Canvas = @import("./Canvas.zig");

pub const HtmlElement = @This();

val: js.Object,

pub fn innerHTML(self: HtmlElement, inner: []const u8) !void {
    try self.val.set("innerHTML", js.string(inner));
}

pub fn deinit(self: HtmlElement) void {
    self.val.deinit();
}

pub fn toCanvas(self: HtmlElement) Canvas {
    return .{ .canvas = self.val };
}
