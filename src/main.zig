const std = @import("std");
const js = @import("zig-js");
const global = @import("./bindings/global.zig");
const ecs = @import("./ecs.zig");

const Canvas = @import("./components/Canvas.zig");
const Rectangle = @import("./components/Rectangle.zig");

const rendering = @import("./systems/rendering.zig").rendering;

pub const ECS = ecs.Ecs(&[_]type{ Canvas, Rectangle });

export fn run() void {
    const document = global.document() catch @panic("error");
    defer document.deinit();

    const app = document.querySelector("#ap") catch @panic("error");
    defer app.deinit();

    const canvas = app.toCanvas();
    defer canvas.deinit();

    const context = canvas.getContext() catch @panic("error");
    defer canvas.deinit();

    context.fillRect(0, 0, 200, 200) catch @panic("error");

    var registry = ECS.init(std.heap.wasm_allocator, 2) catch @panic("error");
    defer registry.deinit();

    const canvas_entity = registry.newEntity();
    registry.set(canvas_entity, Canvas{ .context = context });

    const rect_entity1 = registry.newEntity();
    registry.set(rect_entity1, Rectangle{ .x = 0, .y = 0, .width = 200, .height = 200 });

    const rect_entity2 = registry.newEntity();
    registry.set(rect_entity2, Rectangle{ .x = 200, .y = 200, .width = 200, .height = 200 });

    rendering(&registry) catch @panic("error");
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    const console = global.console() catch unreachable;
    defer console.deinit();
    console.log(msg) catch unreachable;

    suspend {}
}
