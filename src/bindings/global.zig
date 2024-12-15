const js = @import("zig-js");

pub const Document = @import("./Document.zig");
pub const Context = @import("./Context.zig");
pub const Canvas = @import("./Canvas.zig");
pub const HtmlElement = @import("./HtmlElement.zig");
pub const Console = @import("./Console.zig");

pub fn document() !Document {
    return .{ .val = try js.global.get(js.Object, "document") };
}

pub fn console() !Console {
    return .{ .object = try js.global.get(js.Object, "console") };
}
