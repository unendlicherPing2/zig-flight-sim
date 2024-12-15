const ecs = @import("../ecs.zig");
const main = @import("../main.zig");

const Canvas = @import("../components/Canvas.zig");
const Rectangle = @import("../components/Rectangle.zig");

const RenderingError = error{ CanvasNotFound, CanNotDrawRect };

pub fn rendering(registry: *main.ECS) RenderingError!void {
    var canvas_query = registry.queryEntities(&[_]type{Canvas});
    const canvas_entity = canvas_query.next() orelse return RenderingError.CanvasNotFound;
    const canvas = registry.get(Canvas, canvas_entity) orelse unreachable;

    var rectangles = registry.queryEntities(&[_]type{Rectangle});
    while (rectangles.next()) |rect| {
        const rectangle = registry.get(Rectangle, rect) orelse unreachable;
        canvas.context.fillRect(rectangle.x, rectangle.y, rectangle.width, rectangle.height) catch return RenderingError.CanNotDrawRect;
    }
}
