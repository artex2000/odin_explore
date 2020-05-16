package xalloc

import "core:mem"
import "core:fmt"

ALLOCATOR_NO_OVERHEAD :: 1;

MemoryLayout :: struct {
    base: rawptr,
    total_size: u64,
    block_size: int,
    work: int,
    data: int,
}

back_allocator: mem.Allocator;
main_allocator: mem.Allocator;
temp_allocator: mem.Allocator;
data_allocator: mem.Allocator;

init_allocators :: proc(using layout: ^MemoryLayout) {
    fmt.printf("arena %x:%x\n", base, total_size);
    back_allocator = block_allocator(base, total_size, block_size);
    ba := cast(^BlockAllocatorData)back_allocator.data;
    overhead := ba.overhead * ba.block_size;
    fmt.printf("overhead %d blocks\n", ba.overhead);
    available := int(total_size - u64(overhead));
    temp := available - work - data;
    fmt.printf("total, available, work, data, temp %x %x %x %x %x\n",
                total_size, available, work, data, temp);
    assert(work != 0);
    main_allocator = stack_allocator(work, back_allocator, ALLOCATOR_NO_OVERHEAD);
    assert(temp >= 0x10000);
    temp_allocator = stack_allocator(temp, back_allocator, 
                        ALLOCATOR_NO_OVERHEAD | STACK_ALLOCATOR_WRAP);
    if data != 0 do data_allocator = bucket_allocator(data, back_allocator,
                        ALLOCATOR_NO_OVERHEAD);
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
