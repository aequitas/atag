// read Atag protocol data dump from binary file and find all frames (data+crc pairs)

const warn = @import("std").debug.warn;
const assert = @import("std").debug.assert;
const std = @import("std");
const crc16 = @import("crc.zig").crc16_kermit;

const Frame = struct {
    data: []const u8,
    crc: u16,
};

pub fn main() void {
    warn("test");
}

fn find_frame(data: []u8) Frame {
    const head = 9;

    var start: u16 = head;

    var crc: u16 = 0;
    var frame: []u8 = undefined;

    while (true) {
        frame = data[start - head .. start];
        crc = std.mem.readIntSliceBig(u16, data[start .. start + 2]);
        var frame_crc = crc16(frame);

        warn("{} {} {}\n", start, frame_crc, crc);

        if (crc16(frame) == crc) {
            warn("found frame\n");
            break;
        }

        start = start + 1;
        if (start >= data.len - 1) {
            warn("exhausted\n");
            break;
        }
    }

    return Frame{
        .data = frame,
        .crc = crc,
    };
}

test "find_frame" {
    var in_data = [_]u8{ 0x0, 0x0, 0x0, 0x0, 0x0, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x9A, 0x4C };

    var expect = Frame{
        .data = @bytesToSlice(u8, [_]u8{ 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09 }),
        .crc = 0x9A4C,
    };

    var frame = find_frame(in_data[0..]);

    assert(frame.data.len == expect.data.len);
    assert(frame.crc == expect.crc);
}
