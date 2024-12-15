const js = @import("zig-js");
const HtmlElement = @import("./HtmlElement.zig");

const Document = @This();

val: js.Object,

pub fn querySelector(self: Document, query: []const u8) !HtmlElement {
    return .{ .val = try self.val.call(js.Object, "querySelector", .{js.string(query)}) };
}

pub fn deinit(self: Document) void {
    self.val.deinit();
}
