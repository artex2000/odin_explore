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
    layout := xm.MemoryLayout{};
    mem_size := u64(mem.megabytes(100));
    mem_base := get_arena(mem_size);
    layout.base = mem_base;
    layout.total_size = mem_size;
    layout.block_size = 0x1000;
    layout.temp_size = int(0.2 * f32(mem_size));
    //layout.data_size = int(0.4 * f32(mem_size));
    layout.main_size = int(0.4 * f32(mem_size));
    layout.data_size = 0;
    //layout.main_size = int(layout.total_size - u64((layout.temp_size + layout.data_size)));
    xm.init_allocators(&layout);
    context.allocator = xm.main_allocator;
    context.temp_allocator = xm.temp_allocator;
    run();
}

run :: proc() {
    data: win32.Find_Data_W;
    dir := "C:\\work\\misc\\*";
    search_handle := win32.find_first_file_w(win32.utf8_to_wstring(dir), &data);
    if search_handle == win32.INVALID_HANDLE {
        fmt.printf("Can't open directory %s\n", dir);
        return;
    }
    found : win32.Bool = true;
    for found {
        fmt.println(win32.utf16_to_utf8(data.file_name[:]));
        found = win32.find_next_file_w(search_handle, &data);
    }
    win32.find_close(search_handle);
}
