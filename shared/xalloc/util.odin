package xalloc

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
