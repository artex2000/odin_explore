package main

import "core:mem"
import "core:fmt"
import "core:sys/win32"
import xm "shared:xalloc"
import ar "shared:array"

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
    //we give percentages of the whole available memory to allocate for specific
    //purposes. We still have to leave some space for temporary memory, size of which
    //will be calculated as remainder of what's left after other allocator are
    //satisfied
    layout.work = mem.megabytes(50);  //percentage of whole available memory
    layout.data = mem.megabytes(40); //percentage of whole available memory
    xm.init_allocators(&layout);
    context.allocator = xm.main_allocator;
    context.temp_allocator = xm.temp_allocator;
    run();
}

run :: proc() {
    data: win32.Find_Data_W;
    dir := "C:\\work\\misc\\*";
    dir8 := transmute(ar.str8)dir;
    search_handle := win32.find_first_file_w(cast(win32.Wstring)ar.str8_to_cstr16(dir8), &data);
    if search_handle == win32.INVALID_HANDLE {
        fmt.printf("Can't open directory %s\n", dir);
        return;
    }
    found : win32.Bool = true;
    no_print := false;
    for found {
        if !dot_folder(data.file_name[0],data.file_name[1], data.file_name[2]) {
            fmt.printf("%v\n", cast(string)ar.cstr16_to_str8(cast(ar.cstr16)&data.file_name[0]));
        }
        //print_file_name(data.file_name[:]);
        found = win32.find_next_file_w(search_handle, &data);
    }
    win32.find_close(search_handle);
}

dot_folder :: proc(c1, c2, c3: u16) -> bool {
    if c1 == 46 && c2 == 0 do return true;
    if c1 == 46 && c2 == 46 && c3 == 0 do return true;
    return false;
}

print_file_name :: proc(name: []u16) {
    i := 0;
    j := 0;
    for i < len(name) {
        for j < 10 {
            if name[i + j] == 0 {
                fmt.println("");
                return;
            }
            fmt.printf("%x, ", name[i + j]);
            j += 1;
        }
        i += 10;
    }
}
