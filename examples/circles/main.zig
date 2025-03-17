const std = @import("std");
const Canvaz = @import("CanvaZ");
const PenZil = @import("PenZil");

const CircleDemo = struct {

    pub fn init() CircleDemo {
        return CircleDemo{};
    }

    pub fn update(self: *CircleDemo, penzil : *PenZil, ofs : u8) void {

        _ = self;

        const cx = @as(i32,@intCast(penzil.width / 2 + ofs));
        const cy = @as(i32,@intCast(penzil.height / 2 - ofs));

        const r1 = 20 + @as(i32,ofs);
        const r2 = 10 + @as(i32,ofs/2);
        penzil.clear(PenZil.from_rgba(0x10, 0x10, 0x10, 0xFF));
        penzil.circle(cx, cy, r1, PenZil.from_rgba(0x80, 0x80, 0x30, 0xFF));
        penzil.circle_fill(cx, cy, r2, PenZil.from_rgba(0x40, 0x40, 0x30, 0xFF));
    }
};


pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var canvaz = try Canvaz.init(allocator);
    const width = 800;
    const height = 600;

    try canvaz.createWindow("Penzil circles demo", width, height);

    var penzil = try PenZil.init(allocator,width,height,width);
    const buffer = canvaz.dataBuffer();

    var circle_demo = CircleDemo.init();

    var ofs : u8 = 0;

    while (canvaz.update() == 0) {
        const delta = canvaz.delta();
        ofs +%=  @as(u8, @intFromFloat(delta * 100));

        circle_demo.update(&penzil,ofs);
        
        // copy line by line into canvaZ buffer
        for (0..height) |y| {
            const src = @as([*]u32, @ptrCast(penzil.pixelPtr(0, y)))[0..width];
            const dst = @as([*]u32, @ptrCast(&buffer[y * width]))[0..width];
            @memcpy(dst, src);
        }
        Canvaz.sleep(16);
    }
}
