package array

import "core:mem"
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
    assert((index + range) < len(b) * BIT_ARRAY_BASE);
    for i := index; i < index + range; i += 1 {
        bitarray_set(b, i);
    }
}

bitarray_clear_range :: proc( b: BitArray, index, range: int) {
    assert((index + range) < len(b) * BIT_ARRAY_BASE);
    for i := index; i < index + range; i += 1 {
        bitarray_clear(b, i);
    }
}

bitarray_is_set :: proc( b: BitArray, index: int) -> bool {
    assert(index < len(b) * BIT_ARRAY_BASE);
    base := index / BIT_ARRAY_BASE;
    offset := u32(index % BIT_ARRAY_BASE);
    return ((b[base] & (1 << offset)) != 0);
}

bitarray_get_first_zero_index :: proc(b: BitArray) -> int {
    for v, i in b {
        cnt := bits.count_zeros64(v);
        if(cnt == 0) do continue;
        //we've got one with zero inside
        base := i * BIT_ARRAY_BASE;
        tmp := v;
        offset := 0;
        for tmp > 0 {
            if (tmp & 1) == 0 do return base + offset;
            tmp = tmp >> 1; 
            offset += 1;
        }
        return base + offset;
    }
    return -1;
}

bitarray_is_range_clear :: proc(b: BitArray, index, range: int) -> bool {
    assert((index + range) < len(b) * BIT_ARRAY_BASE);
    for i := index; i < index + range; i += 1 {
        r := bitarray_is_set(b, i);
        if r do return false;
    }
    return true;
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
    if size >= BIT_ARRAY_BASE do return bitarray_find_clear_range_big(b, size);
    //we keep leading zeros from previous step to catch free range spread between two u64
    tail_size := 0;
    for v, i in b {
        cz := int(bits.count_zeros64(v)); //total zeros
        lz := int(bits.leading_zeros64(v));
        tz := int(bits.trailing_zeros64(v));
        if tz + tail_size >= size {
            if tail_size == 0 do return i * BIT_ARRAY_BASE;
            else do return (i - 1) * BIT_ARRAY_BASE + (BIT_ARRAY_BASE - tail_size);
        }
        if lz >= size do return i * BIT_ARRAY_BASE + (BIT_ARRAY_BASE - lz);
        zeros_left := cz - lz - tz;
        if zeros_left >= size { //we still may have range in the middle
            //we skipping "1" bit that follows right after trailing zeros
            range_left := BIT_ARRAY_BASE - lz - tz - 1;
            tmp := v;
            tmp = tmp >> u32(tz + 1);
            new_offset := tz + 1;
            for range_left >= size {
                tz = int(bits.trailing_zeros64(tmp));
                if(tz >= size) do return i * BIT_ARRAY_BASE + new_offset;
                //we skipping "1" bit that follows right after trailing zeros
                tmp = tmp >> u32(tz + 1);
                new_offset += tz + 1;
                range_left -= tz + 1;
            }
        }
        //didn't find anything on this step
        tail_size = lz;
    }
    return -1;
}

bitarray_find_clear_range_big :: proc(b: BitArray, size: int) -> int {
    //number of clear u64 words we need
    full := size / BIT_ARRAY_BASE;
    //if not zero we will need one extra word (part of it)
    tail := size % BIT_ARRAY_BASE;
    //total words
    total: int;
    if tail != 0 do total = full + 1;
    else         do total = full;

    for i := 0; i < len(b); i += 1 {
        if bits.count_ones64(b[i]) != 0 do continue;

        //here is the start of empty range, but is it big enough?
        if (i + total) >= len(b) do return -1;

        //scan empty u64 words for required amount
        j := 1;
        for ; j < full; j += 1 {
            if bits.count_ones64(b[i + j]) != 0 do break;
        }

        if (j == full) && (cast(int)bits.trailing_zeros64(b[i + j]) >= tail) {
            return i * BIT_ARRAY_BASE;
        } else {
            //empty range wasn't big enough, search further
            i += j;
        }
    }
    return -1;
}




