// read Atag protocol data dump from binary file and find all frames (data+crc pairs)

const warn = @import("std").debug.warn;
const assert = @import("std").debug.assert;
const std = @import("std");
const crc16 = @import("crc.zig").crc16_kermit;
const Allocator = std.mem.Allocator;
const io = std.io;

const Frame = struct {
    data: []const u8,
    crc: u16,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.direct_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var stdin = try io.getStdIn();
    var file_in_stream = stdin.inStream();

    var buf_stream = io.BufferedInStream(std.fs.File.ReadError).init(&file_in_stream.stream);
    const st = &buf_stream.stream;
    const data = try st.readAllAlloc(allocator, 10 * 1024);

    var frames = find_frames(allocator, data);

    for (frames.items) |frame, n| {
        // warn("{}\n", n);
        // warn("{}: {x}\n", n, frame.data, frame.crc);
    }
}

fn find_frames(allocator: *Allocator, data: []u8) std.ArrayList(Frame) {
    var frames = std.ArrayList(Frame).init(allocator);

    var crc: u16 = 0;

    const min_frame = 4;

    var prev_frame_start: u16 = 0;
    var crc_start: u16 = min_frame;
    while (crc_start < data.len - 2) : (crc_start += 1) {
        crc = std.mem.readIntSliceBig(u16, data[crc_start .. crc_start + 2]);

        var frame_start = crc_start - min_frame;
        while (frame_start > prev_frame_start) : (frame_start -= 1) {
            var frame_data = data[frame_start..crc_start];

            var frame_crc = crc16(frame_data);

            // warn("{} {} {} {} {} {}\n", prev_frame_start, frame_start, crc_start, frame_data.len, frame_crc, crc);

            if (frame_crc == 0) {
                // warn("zero crc\n");
                continue;
            }

            if (frame_crc == crc) {
                var discard = data[prev_frame_start..frame_start];

                warn("found frame {x} {x} {x}\n", discard, frame_data, crc);
                var frame = Frame{
                    .data = frame_data,
                    .crc = crc,
                };
                frames.append(frame) catch unreachable;
                prev_frame_start = crc_start + 2;
                crc_start = crc_start + 1 + min_frame;
                break;
            }
        }
    }

    return frames;
}

test "find_frames" {
    var arena = std.heap.ArenaAllocator.init(std.heap.direct_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var in_data = [_]u8{ 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x9A, 0x4C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };

    var expect = Frame{
        .data = @bytesToSlice(u8, [_]u8{ 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09 }),
        .crc = 0x9A4C,
    };

    var frames = find_frames(allocator, in_data[0..]);

    assert(frames.items[0].data.len == expect.data.len);
    assert(frames.items[0].crc == expect.crc);
}
