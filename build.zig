const std = @import("std");

pub fn build(b: *std.Build) void {

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const penzil_source_file = b.path("src/PenZil.zig");


    const penzilModuleName = "PenZil";
    const penzilModule = b.addModule(
        penzilModuleName,
        .{ .root_source_file = penzil_source_file  });

    const ExampleDir = "examples/";
    const Examples = [_][]const u8{ "gradient", "starfield", "squish" };

    inline for (Examples) |exampleName| {
        const nm = ExampleDir ++ exampleName ++ "/main.zig";

        const example = b.addExecutable(.{
            .name = exampleName,
            .root_source_file = b.path(nm),
            .target = target,
            .optimize = optimize,
        });

        // add PenZil as a dependency
        example.root_module.addImport(penzilModuleName, penzilModule);

        // use CanvaZ as a dependency
        const canvaz = @import("CanvaZ");
        canvaz.addCanvazDependencies(example, b, target, optimize, "CanvaZ");

        b.installArtifact(example);

        const run_cmd = b.addRunArtifact(example);
        run_cmd.step.dependOn(b.getInstallStep());
        
        if (b.args) |args| {
           run_cmd.addArgs(args);
        }

        const run_step = b.step("example_" ++ exampleName, "Run the app");
        run_step.dependOn(&run_cmd.step);
    }
}
