const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exes = .{
        .{ .name = "rsqf", .test_macro = "TEST_RSQF", .c_files = .{ "rsqf.c", "murmur3.c", "bit_util.c", "set.c" } },
        .{ .name = "exaf", .test_macro = "TEST_EXAF", .c_files = .{ "exaf.c", "arcd.c", "murmur3.c", "bit_util.c", "set.c" } },
        .{ .name = "utaf", .test_macro = "TEST_UTAF", .c_files = .{ "utaf.c", "arcd.c", "murmur3.c", "bit_util.c", "set.c" } },
        .{ .name = "taf", .test_macro = "TEST_TAF", .c_files = .{ "taf.c", "arcd.c", "murmur3.c", "bit_util.c", "set.c" } },
        .{ .name = "arcd", .test_macro = "TEST_ARCD", .c_files = .{"arcd.c"} },
    };

    const test_all_step = b.step("test", "test all");

    const c_flags = &.{"-lm", "-g", "-O0", "-Wall"};

    inline for (exes) |opts| {
        const exe = b.addExecutable(.{
            .name = opts.name,
            // .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.linkLibC();
        exe.defineCMacro(opts.test_macro, "1");
        exe.addCSourceFiles(.{ .files = &opts.c_files, .flags = c_flags, .root = b.path("src") });

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);

        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const test_step = b.step(opts.name, "test " ++ opts.name);
        test_step.dependOn(&run_cmd.step);
        test_all_step.dependOn(test_step);
    }

    // const lib_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
    // test_step.dependOn(&run_exe_unit_tests.step);
}
