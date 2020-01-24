const std = @import("std");
const warn = @import("std").debug.warn;
const assert = @import("std").debug.assert;
const input = [_]u8{ 0x10, 0x20, 0x01, 0x21, 0xf1 };
const output: u16 = 0x22bd;

pub fn crc16_kermit(data: []const u8) u16 {
    var crc: u16 = 0x0;
    var q: u16 = 0;

    for (data) |byte| {
        q = (crc ^ byte) & 0x0f;
        crc = (crc >> 4) ^ (q * 0x1081);
        q = (crc ^ (byte >> 4)) & 0xf;
        crc = (crc >> 4) ^ (q * 0x1081);
    }

    return (crc >> 8) ^ (crc << 8);
}

test "crc16_kermit" {
    assert(crc16_kermit(input[0..]) == output);
    assert(crc16_kermit([_]u8{0}) == 0x0000);
    assert(crc16_kermit([_]u8{0x1}) == 0x8911);
}
