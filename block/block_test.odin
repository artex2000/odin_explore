package main

import "core:fmt"
import "core:mem"
import "core:sys/win32"
import rt "core:runtime"

import xm "shared:xalloc"

main :: proc() {
    arena := get_arena();
    allocator := xm.block_allocator(arena, u64(mem.megabytes(100)), 0x10000);
    fmt.printf("Got arena at address %x\n", arena);
}

get_arena :: proc() -> rawptr {
    using win32;
    arena := virtual_alloc(nil, cast(uint)mem.megabytes(100), MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    return arena;
}
