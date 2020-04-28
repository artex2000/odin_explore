package main

import "core:mem"
import "core:fmt"
import "core:sys/win32"
import xm "shared:xalloc"

main :: proc() {
    get_arena :: proc(auto_cast size: uint) -> rawptr {
        using win32;
        arena := virtual_alloc(nil, size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
        return arena;
    }
    arena := get_arena(mem.megabytes(100));
    block_allocator := xm.block_allocator(arena, u64(mem.megabytes(100)), 0x1000);
    temp_allocator := xm.stack_allocator(mem.megabytes(1), block_allocator);
    main_allocator := xm.stack_allocator(mem.megabytes(99), block_allocator);
    context.allocator = main_allocator;
    context.temp_allocator = temp_allocator;
    run();
}

run :: proc() {
    jazz := make([dynamic]string, 100);
    for _, i in jazz {
        jazz[i] = "Artem Shchygel";
    }
    for v in jazz {
        fmt.println(v);
    }
}
