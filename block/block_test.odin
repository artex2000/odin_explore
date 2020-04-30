package main

import "core:fmt"
import "core:mem"
import "core:sys/win32"

import xm "shared:xalloc"

main :: proc() {
    get_arena :: proc(auto_cast size: uint) -> rawptr {
        using win32;
        arena := virtual_alloc(nil, size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
        return arena;
    }

    size := u64(mem.megabytes(10));
    base := get_arena(size);
    allocator := xm.block_allocator(base, size, 0x1000);
    run(allocator);
}

run :: proc(a: mem.Allocator) {
    p := make([dynamic]uintptr, 5);
    for i :=1; i < 6; i += 1 {
        r := a.procedure(a.data, .Alloc, mem.megabytes(i), 0, nil, 0, 0);
        if r != nil {
            fmt.printf("allocated %d megabytes at address %p\n", i, r);
            append(&p, uintptr(r));
        } else {
            fmt.printf("can't allocate %d megabytes\n", i);
        }
    }
}
