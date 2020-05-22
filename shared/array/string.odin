package array

import "core:mem"

MAX_CSTRING_LENGTH :: 0x400;

UTF8_2_BYTE_HEADER :: 0b110_00000;
UTF8_3_BYTE_HEADER :: 0b1110_0000;
UTF8_C_BYTE :: 0b10_000000;

UTF8_6_BIT_MASK :: 0b00_111111;
UTF8_5_BIT_MASK :: 0b000_11111;
UTF8_4_BIT_MASK :: 0b0000_1111;

str8 :: distinct []u8;
str16 :: distinct []u16;
str32 :: distinct []u32;

cstr8 :: distinct ^u8;
cstr16 :: distinct ^u16;
cstr32 :: distinct ^u32;

cstr8_to_str8 :: proc(s: cstr8) -> str8 {
    tmp := transmute([]u8)mem.Raw_Slice{rawptr(s), MAX_CSTRING_LENGTH};
    idx := 0;
    for v in tmp {
        if v == 0 do break;
        idx += 1;
    }
    return transmute(str8)mem.Raw_Slice{rawptr(s), idx};
}

cstr16_to_str16 :: proc(s: cstr16) -> str16 {
    tmp := transmute([]u16)mem.Raw_Slice{rawptr(s), MAX_CSTRING_LENGTH};
    idx := 0;
    for v in tmp {
        if v == 0 do break;
        idx += 1;
    }
    return transmute(str16)mem.Raw_Slice{rawptr(s), idx};
}

//For now cover only 0x0000-0xFFFF range
//TODO temp vs main allocator
cstr16_to_str8 :: proc(s: cstr16) -> str8 {
    tmp := transmute([]u16)mem.Raw_Slice{rawptr(s), MAX_CSTRING_LENGTH};
    idx := 0;
    len := 0;
    for v in tmp {
        if v == 0 do break;

        if v <= 0x7f  do len += 1;
        else if v <=  0x7ff do len += 2;
        else do len += 3;

        idx += 1;
    }

    data := make([]u8, len);
    idx = 0;
    for v in tmp {
        if v == 0 do break;

        if v <= 0x7f {
            data[idx] = u8(v);
            idx += 1;
        } else if v <=  0x7ff {
            data[idx + 1] = u8(UTF8_C_BYTE | (v & UTF8_6_BIT_MASK));
            data[idx] = u8(UTF8_2_BYTE_HEADER | ((v >> 6) & UTF8_5_BIT_MASK));
            idx += 2;
        } else {
            data[idx + 2] = u8(UTF8_C_BYTE | (v & UTF8_6_BIT_MASK));
            data[idx + 1] = u8(UTF8_C_BYTE | ((v >> 6) & UTF8_6_BIT_MASK));
            data[idx] = u8(UTF8_3_BYTE_HEADER | ((v >> 12) & UTF8_4_BIT_MASK));
            idx += 3;
        }
    }
    return str8(data);
}

//TODO temp vs main allocator
str8_to_cstr16 :: proc(s: str8) -> cstr16 {
    len := 1; //for null-terminator
    for v in s {
        if v <= 0x7f do len += 1;
        else if (v & ~u8(UTF8_5_BIT_MASK)) == UTF8_2_BYTE_HEADER do len += 1;
        else if (v & ~u8(UTF8_4_BIT_MASK)) == UTF8_3_BYTE_HEADER do len += 1;
        else if (v & ~u8(UTF8_6_BIT_MASK)) == UTF8_C_BYTE do continue;
        else do assert(false);
    }

    data := make([]u16, len);
    idx := 0;
    for v, i in s {
        if v <= 0x7f {
            data[idx] = u16(v);
        } else if (v & ~u8(UTF8_5_BIT_MASK)) == UTF8_2_BYTE_HEADER {
            data[idx] = u16((s[i] & UTF8_5_BIT_MASK) << 6) | 
                         u16(s[i + 1] & UTF8_6_BIT_MASK);
        } else if (v & ~u8(UTF8_4_BIT_MASK)) == UTF8_3_BYTE_HEADER {
            data[idx] = u16((s[i] & UTF8_4_BIT_MASK) << 12) | 
                         u16((s[i + 1] & UTF8_6_BIT_MASK) << 6) |
                         u16(s[i + 2] & UTF8_6_BIT_MASK);
        } else {
            continue;
        }
        idx += 1;
    }
    data[idx] = 0;

    //unwrap the slice to get raw pointer
    raw := transmute(mem.Raw_Slice)data;
    return cast(cstr16)raw.data;
}
            






