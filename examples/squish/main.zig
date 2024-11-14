const std = @import("std");
const Canvaz = @import("CanvaZ").CanvaZ;
const PenZil = @import("PenZil");

const SquishDemo = struct {
    image : PenZil,
    height : i32 = 200,
    dir : i32 = 10,

    pub fn init(allocator : std.mem.Allocator) !SquishDemo {
        const emedded_png = @embedFile("./pencil.png");
        var buffer_stream = std.io.fixedBufferStream(emedded_png);
        const image = try PenZil.read_png(allocator, buffer_stream.reader());
        std.debug.print("Image loaded: {d}x{d}\n", .{image.width, image.height});
        return SquishDemo{ .image = image };
    }

    pub fn deinit(self :* SquishDemo) void {
        self.image.deinit();
    }

    pub fn update(self : *SquishDemo, penzil : *PenZil, ofs : u8) void {
        const  upper_bound : i32  =@intCast(self.image.height);
        if (self.height >= upper_bound  or self.height <= @divFloor(upper_bound,2)) self.dir *= -1;
        self.height += self.dir;

        penzil.clear( PenZil.from_rgba(ofs, 0x80, 0x20, 0xFF));
        var view = penzil.view( 100,@as(i32,@intCast( penzil.height)) - self.height, @intCast(self.image.width), self.height);
        view.copy_nb(&self.image);
    }
};


pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var canvaz = Canvaz.init(allocator);
    const width = 800;
    const height = 600;

    try canvaz.createWindow("Penzil gradient demo", width, height);

    var squish_demo = try SquishDemo.init(allocator);
    defer squish_demo.deinit();

    var penzil = try PenZil.init(allocator,width,height,width);
    const buffer = canvaz.dataBuffer();

    var ofs : u8 = 0;

    while (canvaz.update() == 0) {
        const delta = canvaz.delta();
        ofs +%=  @as(u8, @intFromFloat(delta * 100));
        
        squish_demo.update(&penzil,ofs);
        
        // copy line by line into canvaZ buffer
        for (0..height) |y| {
            const src = @as([*]u32, @ptrCast(penzil.pixelPtr(0, y)))[0..width];
            const dst = @as([*]u32, @ptrCast(&buffer[y * width]))[0..width];
            @memcpy(dst, src);
        }
        Canvaz.sleep(16);
    }
}