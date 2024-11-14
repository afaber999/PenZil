const std = @import("std");
const Canvaz = @import("CanvaZ").CanvaZ;
const PenZil = @import("PenZil");

const Star = struct {
    x: f32,
    y: f32,
    z: f32,
};

const StarField = struct {
    stars : [] Star = undefined,
    const speed : f32 = 0.2;
    const spread : f32 = 0.8;
    var rand = std.crypto.random;

    pub fn init(allocator: std.mem.Allocator, number : usize) !StarField {
        const stars= try allocator.alloc(Star, number);

        for (stars) |*star| {
            star.x = spread * ( rand.float(f32) * 2.0 - 1.0);
            star.y = spread * (rand.float(f32) * 2.0 - 1.0);
            star.z = spread * (rand.float(f32) + 0.0001);
        }

        return StarField{ .stars = stars };
    }

    pub fn update(self:*StarField, penzil : *PenZil, delta : f32) void {

        penzil.clear(PenZil.from_rgba(0x10, 0x10, 0x10, 0xFF));

        const fw = @as(f32,@floatFromInt(penzil.width)) / 2.0; 
        const fh = @as(f32,@floatFromInt(penzil.height)) / 2.0;

        for (self.stars) |*star| {
            star.z -= delta * speed;
            if ( star.z <= 0.00001 ) {
                star.z = spread * (rand.float(f32) + 0.0001);
            }
            const x = @as(i32, @intFromFloat( star.x / star.z * fw + fw));
            const y = @as(i32, @intFromFloat( star.y / star.z * fh + fh));

            if ( x>=0 and x < @as(i32,@intCast( penzil.width)) and y>=0 and y < @as(i32,@intCast(penzil.height)) ) {
                penzil.setPixel(@intCast(x), @intCast(y), PenZil.from_rgba(0xFF, 0xFF, 0x00, 0xFF));
            }
        }
    }
};

pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var canvaz = Canvaz.init(allocator);
    const width = 800;
    const height = 600;

    try canvaz.createWindow("PenZil starfield demo", width, height);

    var star_field = try StarField.init(allocator, 8000);

    var penzil = try PenZil.init(allocator,width,height,width);
    const buffer = canvaz.dataBuffer();

    while (canvaz.update() == 0) {
        star_field.update(&penzil, canvaz.delta());
        
        // copy line by line into canvaZ buffer
        for (0..height) |y| {
            const src = @as([*]u32, @ptrCast(penzil.pixelPtr(0, y)))[0..width];
            const dst = @as([*]u32, @ptrCast(&buffer[y * width]))[0..width];
            @memcpy(dst, src);
        }
        Canvaz.sleep(16);
    }
}
