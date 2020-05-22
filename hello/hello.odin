package main

import "core:fmt"
import "core:mem"
import "core:os"

main :: proc() {
//    struct_size();
 //   arguments();
  //  pointers();
    strings();
}

struct_size :: proc() {
    fmt.println("--------------- struct size -------------");
    hello :: struct #packed {
        name: string,
        data: []u64,
        data1: [dynamic]u64,
        addr: i32,
    };
    tmp: hello;
    so := size_of(int);
    ao := align_of(u64);
    io := typeid_of(hello);
    fmt.printf("size_of int %v\n", so);
    fmt.printf("align_of: %T, %v\n", ao, ao);
    fmt.printf("typeid_of: %T, %v\n", io, io);

    so = size_of(hello);
    str := offset_of(hello, data);
    sli := offset_of(hello, data1);
    dyn := offset_of(hello, addr);
    fmt.printf("size_of hello %v\n", so);
    fmt.printf("size of string: %T, %v\n", str, str);
    fmt.printf("size of slice: %T, %v\n",sli , sli - str);
    fmt.printf("size of dynamic: %T, %v\n",sli , dyn - sli);
}

arguments :: proc() {
    fmt.println("--------------- arguments -------------");
    argc := len(os.args);
    fmt.printf("number of arguments: %v\n", argc);
    for v in os.args do fmt.println(v);
}

pointers :: proc() {
    fmt.println("--------------- pointers -------------");
    u8array := [?]u8{1,2,3,4,5};

    u8p := &u8array[0];
    fmt.printf("type id %T\n", u8p);

    i := 0;
    for i < len(u8array) {
        fmt.printf("value: %v\n", u8p^);
        u8p = cast(^u8)(uintptr(u8p) + 1);
        i += 1;
    }
}

strings :: proc() {
    fmt.println("--------------- strings -------------");
    cstr: cstring = "artem";
    fmt.printf("length of %s: %v\n", cstr, len(cstr));

    max_len := 250;
    str := transmute(string)mem.Raw_String{cast(^byte)cstr, max_len};
    fmt.printf("type id %T\n", str);
    for v, i in str {
        if v == 0 {
            fmt.printf("char at index %v is zero\n", i);
            break;
        }
        fmt.printf("%v\n", v);
    }
}
