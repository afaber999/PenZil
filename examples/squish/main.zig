const std = @import("std");
const Canvaz = @import("CanvaZ");
const PenZil = @import("PenZil");

const SliceReader = struct {
    bytes: []const u8,
    pos: usize = 0,

    pub fn readNoEof(self: *SliceReader, out: []u8) !void {
        if (self.pos + out.len > self.bytes.len) return error.EndOfStream;
        @memcpy(out, self.bytes[self.pos .. self.pos + out.len]);
        self.pos += out.len;
    }

    pub fn readBytesNoEof(self: *SliceReader, comptime n: usize) ![n]u8 {
        var out: [n]u8 = undefined;
        try self.readNoEof(&out);
        return out;
    }

    pub fn readInt(self: *SliceReader, comptime T: type, endian: std.builtin.Endian) !T {
        const bytes = try self.readBytesNoEof(@sizeOf(T));
        return std.mem.readInt(T, &bytes, endian);
    }

    pub fn isBytes(self: *SliceReader, expected: []const u8) !bool {
        if (self.pos + expected.len > self.bytes.len) return false;
        const found = self.bytes[self.pos .. self.pos + expected.len];
        self.pos += expected.len;
        return std.mem.eql(u8, found, expected);
    }
};

const SquishDemo = struct {
    image : PenZil,
    height : i32 = 200,
    dir : i32 = 10,
    ofs : u8 = 0,

    pub fn init(allocator : std.mem.Allocator) !SquishDemo {
        const emedded_png = @embedFile("./pencil.png");
        var reader = SliceReader{ .bytes = emedded_png };
        const image = try PenZil.read_png(allocator, &reader);
        return SquishDemo{ .image = image };
    }

    pub fn deinit(self :* SquishDemo) void {
        self.image.deinit();
    }

    pub fn update(self : *SquishDemo, penzil : *PenZil, delta : f32) void {

        self.ofs +%=  @as(u8, @intFromFloat(delta * 50));

        const  upper_bound : i32  =@intCast(self.image.height);
        if (self.height >= upper_bound  or self.height <= @divFloor(upper_bound,2)) self.dir *= -1;
        self.height += self.dir;

        penzil.clear( PenZil.from_rgba(self.ofs, 0x80, 0x40, 0xFF));
        var view = penzil.view( @intCast(self.ofs),@as(i32,@intCast( penzil.height)) - self.height, @intCast(self.image.width), self.height);
        view.copy_nb(&self.image);
        view = penzil.view( 50 + @as(i32,@intCast(self.ofs)),@as(i32,@intCast( penzil.height)) - self.height, @intCast(self.image.width), self.height);
        view.copy_nb(&self.image);

        // view = penzil.view( 100,@as(i32,@intCast( penzil.height)) - self.height, -@as(i32,@intCast(self.image.width)), self.height);
        // view.copy_nb(&self.image);


    }
};


pub fn main() !void {

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();

    var canvaz = try Canvaz.init(allocator);
    const width = 800;
    const height = 600;

    try canvaz.createWindow("Penzil gradient demo", width, height);

    var squish_demo = try SquishDemo.init(allocator);
    defer squish_demo.deinit();

    var penzil = try PenZil.init(allocator,width,height,width);
    const buffer = canvaz.dataBuffer();


    while (canvaz.update() == 0) {
        const delta = canvaz.delta();
        
        squish_demo.update(&penzil,delta);
        
        // copy line by line into canvaZ buffer
        for (0..height) |y| {
            const src = @as([*]u32, @ptrCast(penzil.pixelPtr(0, y)))[0..width];
            const dst = @as([*]u32, @ptrCast(&buffer[y * width]))[0..width];
             @memcpy(dst, src);
        }
        Canvaz.sleep(16);
    }
}
