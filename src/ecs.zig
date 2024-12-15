const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn Ecs(comptime Components: []const type) type {
    return struct {
        const Self = @This();

        pub const QueryEntitiesIterator = struct {
            iter_idx: usize,
            valid_it: std.bit_set.DynamicBitSet.Iterator(.{}),
            tag_mask: u32,
            tags: []u32,

            pub fn next(self: *@This()) ?u32 {
                const tag_mask = self.tag_mask;
                while (self.valid_it.next()) |idx| {
                    if (self.tags[idx] & tag_mask == tag_mask) {
                        return @intCast(idx);
                    }
                }
                return null;
            }
        };

        // Use the largest align of all Components for all.
        // component arrays
        const max_alignment = blk: {
            var a = 0;
            for (Components) |c| {
                a = @max(a, @alignOf(c));
            }
            break :blk a;
        };

        fn findSlot(comptime C: type) usize {
            inline for (Components, 0..) |c, i| {
                if (c == C) {
                    return i;
                }
            }
            @compileError("unknown component type: " ++ @typeName(C));
        }

        fn compTagBits(comptime C: type) u32 {
            inline for (Components, 0..) |c, i| {
                if (c == C) {
                    return 1 << i;
                }
            }
            @compileError("unhandled component type " ++ @typeName(C));
        }

        allocator: Allocator,
        bytes: [*]align(max_alignment) u8 = undefined,
        len: usize = 0,
        soa_ptrs: [Components.len][*]align(max_alignment) u8,

        // validity and component masks
        valid: std.DynamicBitSet,
        tags: []u32,

        // `sizes.bytes` is an array of @sizeOf each S field. Sorted by alignment, descending.
        // `sizes.comps` is an array mapping from `sizes.bytes` array index to component index.
        const sizes = blk: {
            const Data = struct {
                size: usize,
                size_index: usize,
                alignment: usize,
            };
            var data: [Components.len]Data = undefined;
            for (Components, 0..) |comp, i| {
                data[i] = .{
                    .size = @sizeOf(comp),
                    .size_index = i,
                    .alignment = @alignOf(comp),
                };
            }
            const Sort = struct {
                fn lessThan(context: void, lhs: Data, rhs: Data) bool {
                    _ = context;
                    return lhs.alignment > rhs.alignment;
                }
            };
            std.mem.sort(Data, &data, {}, Sort.lessThan);
            var sizes_bytes: [Components.len]usize = undefined;
            var comp_indexes: [Components.len]usize = undefined;
            for (data, 0..) |elem, i| {
                sizes_bytes[i] = elem.size;
                comp_indexes[i] = elem.size_index;
            }
            break :blk .{
                .bytes = sizes_bytes,
                .comps = comp_indexes,
            };
        };

        fn capacityInBytes(capacity: usize) usize {
            comptime var elem_bytes: usize = 0;
            inline for (sizes.bytes) |size| elem_bytes += size;
            return elem_bytes * capacity;
        }

        fn allocatedBytes(self: Self) []align(max_alignment) u8 {
            return self.bytes[0..capacityInBytes(self.len)];
        }

        pub fn init(allocator: Allocator, len: usize) !Self {
            const mem = try allocator.alignedAlloc(u8, max_alignment, capacityInBytes(len));

            var ptr: [*]u8 = mem.ptr;
            var soa_ptrs: [Components.len][*]align(max_alignment) u8 = undefined;
            for (sizes.bytes, sizes.comps) |comp_size, i| {
                soa_ptrs[i] = @alignCast(ptr);
                ptr += comp_size * len;
            }

            const valid = try std.DynamicBitSet.initEmpty(allocator, len);
            const tags = try allocator.alloc(u32, len);
            @memset(tags, 0);

            return .{
                .allocator = allocator,
                .bytes = mem.ptr,
                .len = len,
                .soa_ptrs = soa_ptrs,
                .valid = valid,
                .tags = tags,
            };
        }

        fn items(self: *Self, comptime C: type) []C {
            const comp_idx = findSlot(C);
            var ptr = @as([*]C, @ptrCast(self.soa_ptrs[comp_idx]));
            return ptr[0..self.len];
        }

        pub fn newEntity(self: *Self) u32 {
            var unset_it = self.valid.iterator(.{ .kind = .unset });
            const idx = while (unset_it.next()) |idx| {
                break idx;
            } else {
                @panic("out of entities -- shouldn't get here");
            };
            self.valid.set(idx);
            self.tags[idx] = 0;
            return @intCast(idx);
        }

        pub fn removeEntity(self: *Self, id: u32) void {
            self.valid.unset(id);
            self.tags[id] = 0;
        }

        pub fn get(self: *Self, comptime C: type, idx: usize) ?*C {
            const mask = compTagBits(C);
            if (self.valid.isSet(idx) and (self.tags[idx] & mask) != 0) {
                return &self.items(C)[idx];
            }
            return null;
        }

        pub fn set(self: *Self, idx: usize, c: anytype) void {
            self.valid.set(idx);
            self.tags[idx] |= compTagBits(@TypeOf(c));
            self.items(@TypeOf(c))[idx] = c;
        }

        pub fn queryEntities(self: *Self, comptime Comps: []const type) QueryEntitiesIterator {
            var tag_mask: u32 = 0;

            inline for (Comps) |c| {
                tag_mask |= compTagBits(c);
            }

            return .{
                .valid_it = self.valid.iterator(.{}),
                .iter_idx = 0,
                .tag_mask = tag_mask,
                .tags = self.tags,
            };
        }

        pub fn deinit(self: *Self) void {
            self.valid.deinit();
            self.allocator.free(self.tags);
            self.allocator.free(self.allocatedBytes());
        }
    };
}
