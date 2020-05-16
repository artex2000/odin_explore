package array

import "core:mem"
import "core:fmt"
import "core:math/bits"

BIT_ARRAY_BASE :: 64;

BitArray :: distinct []u64;

bitarray_init :: proc(arena: rawptr, size: int) -> BitArray {
    r := cast(BitArray)mem.slice_ptr(cast(^u64)arena, size / BIT_ARRAY_BASE);
    return r;
}

bitarray_set_all :: proc(b: BitArray) {
    for _, i in b {
        b[i] = 0xFFFF_FFFF_FFFF_FFFF;
    }
}

bitarray_clear_all :: proc(b: BitArray) {
    for _, i in b {
        b[i] = 0;
    }
}

bitarray_set :: proc( b: BitArray, index: int) {
    assert(index < len(b) * BIT_ARRAY_BASE);
    base := index / BIT_ARRAY_BASE;
    offset := u32(index % BIT_ARRAY_BASE);
    b[base] |= u64(1 << offset);
}

bitarray_clear :: proc( b: BitArray, index: int) {
    assert(index < len(b) * BIT_ARRAY_BASE);
    base := index / BIT_ARRAY_BASE;
    offset := u32(index % BIT_ARRAY_BASE);
    b[base] &= ~(1 << offset);
}

bitarray_set_range :: proc( b: BitArray, index, range: int) {
    assert((index + range) <= len(b) * BIT_ARRAY_BASE);
    base_idx := index / BIT_ARRAY_BASE;
    offset := u32(index % BIT_ARRAY_BASE);
    wrap, head, tail, full := get_range_type(int(offset), range);
    if wrap {
        if head != 0 {
            //lead mask in form 1111110000
            lead_mask := u64((1 << u32(BIT_ARRAY_BASE - head)) - 1);
            lead_mask = ~lead_mask;
            b[base_idx] |= lead_mask;
            base_idx += 1;
        }
        for full > 0 {
            b[base_idx] = 0xFFFF_FFFF_FFFF_FFFF;
            full -= 1;
            base_idx += 1;
        }
        if tail != 0 {
            //trail mask in form 0000111111111
            trail_mask := u64((1 << u32(tail)) - 1);
            b[base_idx] |= trail_mask;
        }
    } else {
        //mask in form 000011110000
        mask := u64((1 << u32(range) - 1));
        mask = mask << u32(offset);
        b[base_idx] |= mask;
    }
}

bitarray_clear_range :: proc( b: BitArray, index, range: int) {
    assert((index + range) <= len(b) * BIT_ARRAY_BASE);
    base_idx := index / BIT_ARRAY_BASE;
    offset := u32(index % BIT_ARRAY_BASE);
    wrap, head, tail, full := get_range_type(int(offset), range);
    if wrap {
        if head != 0 {
            //lead mask in form 0000111111111
            lead_mask := u64((1 << u32(BIT_ARRAY_BASE - head)) - 1);
            b[base_idx] &= lead_mask;
            base_idx += 1;
        }
        for full > 0 {
            b[base_idx] = 0;
            full -= 1;
            base_idx += 1;
        }
        if tail != 0 {
            //trail mask in form 1111110000
            trail_mask := u64((1 << u32(tail)) - 1);
            trail_mask = ~trail_mask;
            b[base_idx] &= trail_mask;
        }
    } else {
        //mask in form 111100001111
        mask := u64((1 << u32(range) - 1));
        mask = ~(mask << u32(offset));
        b[base_idx] &= mask;
    }
}

bitarray_is_set :: proc( b: BitArray, index: int) -> bool {
    assert(index < len(b) * BIT_ARRAY_BASE);
    base := index / BIT_ARRAY_BASE;
    offset := u32(index % BIT_ARRAY_BASE);
    return ((b[base] & (1 << offset)) != 0);
}

bitarray_get_next_set_index :: proc(b: BitArray, index: int) -> int {
    assert(index < len(b) * BIT_ARRAY_BASE);
    base := index / BIT_ARRAY_BASE;
    offset := u32(index % BIT_ARRAY_BASE);
    if offset == 0 do return bitarray_get_next_set_index_aligned(b, base);

    v := b[base];
    v = v >> offset;
    if v != 0 {
        shift := bitarray_get_first_set_bit(v);
        return index + shift;
    }

    //if we're here b[base] doesn't have zeros after offset
    return bitarray_get_next_set_index_aligned(b, base + 1);
}

bitarray_get_next_set_index_aligned :: proc(b: BitArray, index: int) -> int {
    assert(index < len(b));
    idx := index;
    for idx < len(b) {
        cnt := bits.count_ones64(b[idx]);
        if cnt != 0 {
            v := b[idx];
            shift := bitarray_get_first_set_bit(v);
            return idx * BIT_ARRAY_BASE + shift;
        }
        idx += 1;
    }
    return -1;
}

bitarray_get_next_clear_index :: proc(b: BitArray, index: int) -> int {
    assert(index < len(b) * BIT_ARRAY_BASE);
    base := index / BIT_ARRAY_BASE;
    offset := u32(index % BIT_ARRAY_BASE);
    if offset == 0 do return bitarray_get_next_clear_index_aligned(b, base);

    v := ~b[base]; //turn all zeros to ones
    v = v >> offset;
    if v != 0 {
        shift := bitarray_get_first_set_bit(v);
        return index + shift;
    }

    //if we're here b[base] doesn't have zeros after offset
    return bitarray_get_next_clear_index_aligned(b, base + 1);
}

bitarray_get_next_clear_index_aligned :: proc(b: BitArray, index: int) -> int {
    assert(index < len(b));
    idx := index;
    for idx < len(b) {
        cnt := bits.count_zeros64(b[idx]);
        if cnt != 0 {
            v := ~b[idx]; //turn all zeros to ones
            shift := bitarray_get_first_set_bit(v);
            return idx * BIT_ARRAY_BASE + shift;
        }
        idx += 1;
    }
    return -1;
}

bitarray_get_first_set_bit :: inline proc(value: u64) -> int {
    assert(value != 0);
    tmp := value;
    r := 0;
    for tmp != 0 {
        if (tmp & 1) != 0 do return r;
        r += 1;
        tmp = tmp >> 1;
    }
    //should never get here
    assert(false);
    return -1;
}

bitarray_is_range_clear :: proc(b: BitArray, index, range: int) -> bool {
    assert((index + range) <= len(b) * BIT_ARRAY_BASE);
    //check if the start is clear
    if bitarray_is_set(b, index) do return false;
    next := bitarray_get_next_set_index(b, index);
    if (next == -1) || ((next - index) >= range) do return true;
    return false;
}

bitarray_count_ones_before_index :: proc(b: BitArray, index: int) -> int {
    assert(index < len(b) * BIT_ARRAY_BASE);
    base := index / BIT_ARRAY_BASE;
    offset := u32(index % BIT_ARRAY_BASE);
    cnt := 0;
    for i := 0; i < base; i += 1 do cnt += int(bits.count_ones64(b[i]));
    if (offset == 0) do return cnt;
    mask := u64((1 << offset) - 1);
    return cnt + int(bits.count_ones64(b[base] & mask));
}

bitarray_find_clear_range :: proc(b: BitArray, size: int) -> int {
    total := len(b) * BIT_ARRAY_BASE;
    i := 0;
    for i < total {
        i = bitarray_get_next_clear_index(b, i);
        fmt.printf("next clear index %x\n", i);
        if (i == -1) || ((i + size) > total) do break;
        if bitarray_is_range_clear(b, i, size) do return i;
        i = bitarray_get_next_set_index(b, i);
        if i == -1 do break;
        fmt.printf("next set index %x\n", i);
    }
    return -1;
}

get_range_type :: proc(offset, size: int) -> (wrap: bool, tail, head, full: int) {
    if (offset + size) < BIT_ARRAY_BASE {
        wrap = false;
        tail = 0;
        head = 0;
        full = 0;
        return wrap, head, tail, full;
    }

    wrap = true;
    head = BIT_ARRAY_BASE - offset;
    full = (size - head) / BIT_ARRAY_BASE;
    tail = (size - head) % BIT_ARRAY_BASE;
    return wrap, head, tail, full;
}
