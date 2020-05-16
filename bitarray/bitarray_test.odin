package main

import "core:fmt"
import "core:mem"
import "core:sys/win32"
import bt "shared:array"

main :: proc() {
    slice := make([]u64, 100);
    arena := get_arena();
    bitarray := bt.bitarray_init(arena, 64 * 100);
    set_bit_test(bitarray);
    clear_bit_test(bitarray);
    is_bit_set_test(bitarray);
    set_bit_range_test(bitarray);
    clear_bit_range_test(bitarray);
    get_next_set_index_test(bitarray);
    get_next_clear_index_test(bitarray);
    is_bit_range_clear_test(bitarray);
    count_ones_before_index_test(bitarray);
    find_clear_bit_range_test(bitarray);
}

set_bit_test :: proc(b: bt.BitArray) {
    fmt.println("Set bit test");
    bt.bitarray_clear_all(b);
    for i := 1; i < 64; i += 2 {
        bt.bitarray_set(b, i);
        bt.bitarray_set(b, i + 128);
        bt.bitarray_set(b, i + 256);
    }
    if b[0] != 0xAAAA_AAAA_AAAA_AAAA {
        fmt.printf("Expected AA, get %x\n", b[0]);
        assert(false);
    }
    if b[2] != 0xAAAA_AAAA_AAAA_AAAA {
        fmt.printf("Expected AA, get %x\n", b[2]);
        assert(false);
    }
    if b[4] != 0xAAAA_AAAA_AAAA_AAAA {
        fmt.printf("Expected AA, get %x\n", b[4]);
        assert(false);
    }
    fmt.println("---Passed");
}

clear_bit_test :: proc(b: bt.BitArray) {
    fmt.println("Clear bit test");
    bt.bitarray_set_all(b);
    for i := 0; i < 64; i += 2 {
        bt.bitarray_clear(b, i);
        bt.bitarray_clear(b, i + 128);
        bt.bitarray_clear(b, i + 256);
    }
    if b[0] != 0xAAAA_AAAA_AAAA_AAAA {
        fmt.printf("Expected AA, get %x\n", b[0]);
        assert(false);
    }
    if b[2] != 0xAAAA_AAAA_AAAA_AAAA {
        fmt.printf("Expected AA, get %x\n", b[2]);
        assert(false);
    }
    if b[4] != 0xAAAA_AAAA_AAAA_AAAA {
        fmt.printf("Expected AA, get %x\n", b[4]);
        assert(false);
    }
    fmt.println("---Passed");
}

set_bit_range_test :: proc(b: bt.BitArray) {
    fmt.println("Set bit range test");
    //test 1
    bt.bitarray_clear_all(b);
    bt.bitarray_set_range(b, 32, 64);
    if b[0] != 0xFFFF_FFFF_0000_0000 {
        fmt.printf("Expected F0, get %x\n", b[0]);
        assert(false);
    }
    if b[1] != 0x0000_0000_FFFF_FFFF {
        fmt.printf("Expected 0F, get %x\n", b[1]);
        assert(false);
    }
    //test 2
    test_idx := [5]int {12, 45, 214, 126, 305};
    test_sz := [5]int {134, 12, 45, 68, 256};
    for i := 0; i < 5; i +=1 {
        bt.bitarray_clear_all(b);
        bt.bitarray_set_range(b, test_idx[i], test_sz[i]);
        for j := 0; j < test_sz[i]; j += 1 {
            if !bt.bitarray_is_set(b, test_idx[i] + j) {
                fmt.printf("Error: expect bit %d to be set\n", test_idx[i] + j);
                assert(false);
            }
        }
    }
    fmt.println("---Passed");
}

clear_bit_range_test :: proc(b: bt.BitArray) {
    fmt.println("Clear bit range test");
    //test 1
    bt.bitarray_set_all(b);
    bt.bitarray_clear_range(b, 32, 64);
    if b[0] != 0x0000_0000_FFFF_FFFF {
        fmt.printf("Expected 0F, get %x\n", b[1]);
        assert(false);
    }
    if b[1] != 0xFFFF_FFFF_0000_0000 {
        fmt.printf("Expected F0, get %x\n", b[0]);
        assert(false);
    }
    //test 2
    test_idx := [5]int {12, 45, 214, 126, 305};
    test_sz := [5]int {134, 12, 45, 68, 256};
    for i := 0; i < 5; i +=1 {
        bt.bitarray_set_all(b);
        bt.bitarray_clear_range(b, test_idx[i], test_sz[i]);
        for j := 0; j < test_sz[i]; j += 1 {
            if bt.bitarray_is_set(b, test_idx[i] + j) {
                fmt.printf("Error: expect bit %d to be clear\n", test_idx[i] + j);
                assert(false);
            }
        }
    }
    fmt.println("---Passed");
}

is_bit_set_test :: proc(b: bt.BitArray) {
    test := [5]int {2, 8, 102, 54, 64};
    fmt.println("Is bit set test");
    bt.bitarray_clear_all(b);
    for v in test {
        bt.bitarray_set(b, v);
    }
    for v in test {
        if !bt.bitarray_is_set(b, v) {
            fmt.printf("Error: expect bit %d to be set\n", v);
            assert(false);
        }
    }
    fmt.println("---Passed");
}

get_next_set_index_test :: proc(b: bt.BitArray) {
    test := [5]int {2, 48, 102, 268, 645};
    fmt.println("Get next set index test");
    bt.bitarray_clear_all(b);
    for v in test {
        bt.bitarray_set(b, v);
    }
    idx := 0;
    for v in test {
        r := bt.bitarray_get_next_set_index(b, idx);
        if r != v {
            fmt.printf("Error: expect index %v get %v\n", v, r);
            assert(false);
        }
        idx = r + 1;
    }
    fmt.println("---Passed");
}

get_next_clear_index_test :: proc(b: bt.BitArray) {
    test := [5]int {2, 48, 102, 268, 645};
    fmt.println("Get next clear index test");
    bt.bitarray_set_all(b);
    for v in test {
        bt.bitarray_clear(b, v);
    }
    idx := 0;
    for v in test {
        r := bt.bitarray_get_next_clear_index(b, idx);
        if r != v {
            fmt.printf("Error: expect index %v get %v\n", v, r);
            assert(false);
        }
        idx = r + 1;
    }
    fmt.println("---Passed");
}

is_bit_range_clear_test :: proc(b: bt.BitArray) {
    test_idx := [5]int {12, 45, 214, 126, 305};
    test_sz := [5]int {134, 12, 45, 68, 256};
    fmt.println("Is bit range clear test");
    for i := 0; i < 5; i +=1 {
        bt.bitarray_set_all(b);
        bt.bitarray_clear_range(b, test_idx[i], test_sz[i]);
        r := bt.bitarray_is_range_clear(b, test_idx[i], test_sz[i]);
        if !r {
            fmt.printf("Expected range %d:%d to be clear\n", test_idx[i], test_sz[i]);
            assert(false);
        }
    }
    fmt.println("---Passed");
}

count_ones_before_index_test :: proc(b: bt.BitArray) {
    test := [5]int {42, 91, 215, 429, 645};
    fmt.println("Count ones before index test");
    bt.bitarray_clear_all(b);
    for i in test {
        bt.bitarray_set(b, i);
    }
    for v, i in test {
        r := bt.bitarray_count_ones_before_index(b, v - 1);
        if r != i {
            fmt.printf("Expected count %d, got %d\n", i, r);
            assert(false);
        }
    }
    fmt.println("---Passed");
}

find_clear_bit_range_test :: proc(b: bt.BitArray) {
    fmt.println("Find clear bit range test");
    bt.bitarray_set_all(b);
    //find range inside one u64
    bt.bitarray_clear_range(b, 10, 44);
    r := bt.bitarray_find_clear_range(b, 44);
    if r != 10 {
        fmt.printf("Expected 10, got %d\n", r);
        assert(false);
    }
    //find range split between two u64
    bt.bitarray_clear_range(b, 109, 44);
    bt.bitarray_clear_range(b, 198, 61);
    r = bt.bitarray_find_clear_range(b, 61);
    if r != 198 {
        fmt.printf("Expected 98, got %d\n", r);
        assert(false);
    }
    //find big range
    bt.bitarray_clear_range(b, 435, 512);
    r = bt.bitarray_find_clear_range(b, 294);
    if r != 435 {
        fmt.printf("Expected 435, got %d\n", r);
        assert(false);
    }

    fmt.println("---Passed");
}

get_arena :: proc() -> rawptr {
    using win32;
    arena := virtual_alloc(nil, cast(uint)mem.megabytes(10), MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    return arena;
}

