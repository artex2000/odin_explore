package main

import "core:fmt"
import "core:os"

main :: proc() {
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


    argc := len(os.args);
    fmt.printf("number of arguments: %v\n", argc);
    for v in os.args do fmt.println(v);
}
