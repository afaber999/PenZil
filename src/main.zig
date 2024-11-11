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

    var r : u8 = 0;

    while (canvaz.update() == 0) {
        const delta = canvaz.delta();
        r +%=  @as(u8, @intFromFloat(delta * 100));

        const buffer = canvaz.dataBuffer();

        penzil.clear( Penzil.from_rgba(r, 0x80, 0x20, 0xFF));

        for (0..height) |y| {
            for (0..width) |x| {
                const col = penzil.getPixel(x,y);
                setPixel(buffer, width, x, y, col);
            }
        }

        Canvaz.sleep(16);
    }
}
