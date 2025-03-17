const std = @import("std");
const Canvaz = @import("CanvaZ");
const PenZil = @import("PenZil");

pub fn update(penzil : *PenZil, ofs : u8) void {

    const fw = @as(f32,@floatFromInt(penzil.width)); 
    const fh = @as(f32,@floatFromInt(penzil.height));

    for (0..penzil.height) |y| {
        for (0..penzil.width) |x| {

            const dx = (fw/2.0 - @as(f32,@floatFromInt(x)) ) / fw;
            const dy = (fh/2.0 - @as(f32,@floatFromInt(y)) ) / fh;
            const d = @sqrt(dx*dx + dy*dy);
            const t = std.math.atan2(dy,dx);

            const r = @as(u8, @intFromFloat( std.math.sin(d*std.math.tau * 2.0 + t + 4.0) * 127.0 + 128.0)) +% ofs;
            const g = @as(u8, @intFromFloat( std.math.sin(d*std.math.tau + t + 3.0) * 127.0 + 128.0));
            const b = @as(u8, @intFromFloat( std.math.sin(d*std.math.tau + t + 2.0) * 127.0 + 128.0));

            const color = PenZil.from_rgba(r, g, b, 0xFF);
            penzil.setPixel(x,y, color);
            
        }
    }
}


pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var canvaz = try Canvaz.init(allocator);
    const width = 800;
    const height = 600;

    try canvaz.createWindow("Penzil gradient demo", width, height);

    var penzil = try PenZil.init(allocator,width,height,width);
    const buffer = canvaz.dataBuffer();

    var ofs : u8 = 0;

    while (canvaz.update() == 0) {
        const delta = canvaz.delta();
        ofs +%=  @as(u8, @intFromFloat(delta * 100));

        update(&penzil,ofs);
        
        // copy line by line into canvaZ buffer
        for (0..height) |y| {
            const src = @as([*]u32, @ptrCast(penzil.pixelPtr(0, y)))[0..width];
            const dst = @as([*]u32, @ptrCast(&buffer[y * width]))[0..width];
            @memcpy(dst, src);
        }
        Canvaz.sleep(16);
    }
}
