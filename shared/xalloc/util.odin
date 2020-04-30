package xalloc

import "core:mem"

MemoryLayout :: struct {
    base: rawptr,
    total_size: u64,
    main_size, temp_size, data_size: int,
    block_size: int,
}

back_allocator: mem.Allocator;
main_allocator: mem.Allocator;
temp_allocator: mem.Allocator;
data_allocator: mem.Allocator;

init_allocators :: proc(using layout: ^MemoryLayout) {
    back_allocator = block_allocator(base, total_size, block_size);
    assert(main_size != 0);
    main_allocator = stack_allocator(main_size, back_allocator);
    assert(temp_size != 0);
    temp_allocator = stack_allocator(temp_size, back_allocator);
    if data_size != 0 do data_allocator = bucket_allocator(data_size, back_allocator);
}

align :: proc(auto_cast base, round: uintptr) -> uintptr {
    if (base / round) == 0 do return base;
    return base + round - (base % round);
}

align_8 :: inline proc(value: int) -> int {
    return int(align(value, 8));
}

align_16 :: inline proc(value: int) -> int {
    return int(align(value, 16));
}

align_ptr_8 :: inline proc(base: rawptr) -> rawptr {
    return rawptr(align(base, 8));
}

align_ptr_16 :: inline proc(base: rawptr) -> rawptr {
    return rawptr(align(base, 16));
}

forward :: inline proc(auto_cast base, size: uintptr, round: int) -> rawptr {
    new_ptr := base + size;
    return rawptr(align(new_ptr, round));
}
