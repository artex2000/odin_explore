package xalloc

import "core:mem"
import "core:fmt"
import rt "core:runtime"

STACK_ALLOCATOR_WRAP :: 0x2;
STACK_ALLOCATOR_BIG_STACK :: 0x4;

DEFAULT_STACK_SIZE :: 0x400;

StackAllocatorData :: struct {
    base: rawptr,
    free_ptr: rawptr,
    size: int,
    wrap: bool,
    stack: []uintptr,
    index: int
}

stack_allocator_backed :: proc(size: int, back: mem.Allocator, flags: u64 = 0) -> mem.Allocator {
    //make sure backup allocator is our block allocator
    assert(is_block_allocator(back));
    ba := cast(^BlockAllocatorData)back.data;
    stack_size := DEFAULT_STACK_SIZE;
    if (flags & STACK_ALLOCATOR_BIG_STACK) != 0 do stack_size <<= 2;

    needed := size;
    overhead := size_of(StackAllocatorData) + size_of(int) * stack_size;
    if (flags & ALLOCATOR_NO_OVERHEAD) == 0 {
        //calculate needed size including overhead
        required := overhead + size;
        blocks := required / ba.block_size;
        if (required % ba.block_size) != 0 do blocks += 1;
        needed = blocks * ba.block_size;
    }
    back_mem := back.procedure(back.data, .Alloc, needed, 0, nil, 0, 0);
    assert(back_mem != nil);
    fmt.printf("stack allocator base %x\n", back_mem);

    data := cast(^StackAllocatorData)back_mem;
    if (flags & STACK_ALLOCATOR_WRAP) != 0 do data.wrap = true;
    else                                   do data.wrap = false;
    data.base = forward(back_mem, overhead, 16);
    data.free_ptr = data.base;
    data.size = needed - int(uintptr(data.base) - uintptr(data));
    stack_offset := forward(back_mem, size_of(StackAllocatorData), 8);
    data.stack = mem.slice_ptr(cast(^uintptr)stack_offset, stack_size);
    mem.zero_slice(data.stack);

    return mem.Allocator { stack_allocator_proc, data };
}

stack_allocator_raw :: proc(base: rawptr, size: u64, stack_size: int, wrap: bool = true) -> mem.Allocator {
    data := cast(^StackAllocatorData)base;
    data.wrap = wrap;
    overhead := size_of(StackAllocatorData) + size_of(int) * stack_size;
    data.base = forward(base, overhead, 16);
    data.free_ptr = data.base;
    data.size = int(size) - int(uintptr(data.base) - uintptr(data));
    stack_offset := forward(base, size_of(StackAllocatorData), 8);
    data.stack = mem.slice_ptr(cast(^uintptr)stack_offset, stack_size);
    mem.zero_slice(data.stack);

    return mem.Allocator { stack_allocator_proc, data };
}

stack_allocator :: proc {stack_allocator_raw, stack_allocator_backed};

stack_allocator_proc :: proc(data: rawptr, mode: mem.Allocator_Mode,
                             size, alignment: int,
                             old_mem: rawptr, old_size: int, flags: u64 = 0,
                             loc: rt.Source_Code_Location = #caller_location) -> rawptr {

    stack_alloc :: proc(this: ^StackAllocatorData, size: int) -> rawptr {
        assert(this.index < len(this.stack));
        fmt.printf("alloc %v bytes\n", size);
        free := this.size - int(uintptr(this.free_ptr) - uintptr(this.base));
        needed := align_8(size);
        ret_ptr := this.free_ptr;
        if needed < free {
            this.free_ptr = forward(this.free_ptr, size, 8);
            this.stack[this.index] = uintptr(ret_ptr);
            this.index += 1;
            fmt.printf("return %v\n", ret_ptr);
            return ret_ptr;
        }
        if this.wrap {
            ret_ptr = this.base;
            this.free_ptr = forward(this.base, size, 8);
            this.stack[0] = uintptr(ret_ptr);
            this.index = 1;
            return ret_ptr;
        }
        return nil;
    }

    stack_free :: proc(this: ^StackAllocatorData, mem: rawptr) {
        assert(this.index > 0);
        fmt.printf("free %v ptr\n", mem);
        if uintptr(mem) == this.stack[this.index - 1] {
            //if this was the last allocation we can roll back
            this.free_ptr = mem;
            this.index -= 1;
            //TODO: clear freed memory
        }
    }

    stack_free_all :: proc(this: ^StackAllocatorData) {
        this.free_ptr = this.base;
        this.index = 0;
        mem.zero_slice(this.stack);
    }

    stack_resize :: proc(this: ^StackAllocatorData, size: int,
                        old_mem: rawptr, old_size: int) -> rawptr {
        stack_free(this, old_mem);
        return stack_alloc(this, size);
    }

    this := cast(^StackAllocatorData)data;
    switch mode {
    case .Alloc:
        return stack_alloc(this, size);
    case .Free:
        stack_free(this, old_mem);
    case .Free_All:
        stack_free_all(this);
    case .Resize:
        return stack_resize(this, size, old_mem, old_size);
    }
    return nil;
}

