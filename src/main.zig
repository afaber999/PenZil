const std = @import("std");
const Canvaz = @import("CanvaZ").CanvaZ;
const Penzil = @import("PenZil.zig");

fn setPixel(buffer: []u32, width: usize, x: usize, y: usize, color: u32) void {
    const index = y * width + x;
    buffer[index] = color;
}

pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var canvaz = Canvaz.init(allocator);
    const width = 800;
    const height = 600;

    try canvaz.createWindow("Penzil Demo", width, height);

    var penzil = try Penzil.init(allocator,width,height,width);
    const buffer = canvaz.dataBuffer();

    var r : u8 = 0;

    while (canvaz.update() == 0) {
        const delta = canvaz.delta();
        r +%=  @as(u8, @intFromFloat(delta * 100));


        penzil.clear( Penzil.from_rgba(r, 0x80, 0x20, 0xFF));

        // copy line by line into canvaZ buffer
        for (0..height) |y| {
            const src = @as([*]u32, @ptrCast(penzil.pixelPtr(0, y)))[0..width];
            const dst = @as([*]u32, @ptrCast(&buffer[y * width]))[0..width];
            @memcpy(dst, src);
        }

        Canvaz.sleep(16);
    }
}
