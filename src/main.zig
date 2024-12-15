const std = @import("std");
const js = @import("zig-js");
const global = @import("./bindings/global.zig");
const ecs = @import("./ecs.zig");

const Canvas = @import("./components/Canvas.zig");
const Rectangle = @import("./components/Rectangle.zig");

const rendering = @import("./systems/rendering.zig").rendering;

pub const ECS = ecs.Ecs(&[_]type{ Canvas, Rectangle });

export fn run() void {
    const document = global.document() catch unreachable;
    defer document.deinit();

    const app = document.querySelector("#app") catch unreachable;
    defer app.deinit();

    const canvas = app.toCanvas();
    defer canvas.deinit();

    const context = canvas.getContext() catch unreachable;
    defer canvas.deinit();

    context.fillRect(0, 0, 200, 200) catch unreachable;

    var registry = ECS.init(std.heap.wasm_allocator, 100) catch unreachable;
    defer registry.deinit();

    const canvas_entity = registry.newEntity();
    registry.set(canvas_entity, Canvas{ .context = context });

    const rect_entity1 = registry.newEntity();
    registry.set(rect_entity1, Rectangle{ .x = 0, .y = 0, .width = 200, .height = 200 });

    const rect_entity2 = registry.newEntity();
    registry.set(rect_entity2, Rectangle{ .x = 200, .y = 200, .width = 200, .height = 200 });

    rendering(&registry) catch unreachable;
}
