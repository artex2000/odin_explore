package xalloc

import "core:mem"
import rt "core:runtime"

DEFAULT_STACK_SIZE :: 0x1000;

StackAllocatorData :: struct {
    base: rawptr,
    free_ptr: rawptr,
    size: int,
    back: mem.Allocator, 
    stack: []uintptr,
    index: int
}

stack_allocator :: proc(size: int, back: mem.Allocator) -> mem.Allocator {
    //make sure backup allocator is our block allocator
    assert(is_block_allocator(back));
    ba := cast(^BlockAllocatorData)back.data;

    //calculate required size and allocate memory
    overhead := size_of(StackAllocatorData) + size_of(int) * DEFAULT_STACK_SIZE;
    required := overhead + size;
    blocks := required / ba.block_size;
    if (required % ba.block_size) != 0 do blocks += 1;
    back_mem := back.procedure(back.data, .Alloc, blocks * ba.block_size, 0, nil, 0, 0);
    assert(back_mem != nil);

    data := cast(^StackAllocatorData)back_mem;
    data.back = back;
    data.size = size;
    stack_offset := forward(back_mem, size_of(StackAllocatorData), 8);
    data.stack = mem.slice_ptr(cast(^uintptr)stack_offset, DEFAULT_STACK_SIZE);
    mem.zero_slice(data.stack);
    data.base = forward(back_mem, overhead, 16);
    data.free_ptr = data.base;

    return mem.Allocator { stack_allocator_proc, data };
}

stack_allocator_proc :: proc(data: rawptr, mode: mem.Allocator_Mode,
                             size, alignment: int,
                             old_mem: rawptr, old_size: int, flags: u64 = 0,
                             loc: rt.Source_Code_Location = #caller_location) -> rawptr {

    stack_alloc :: proc(this: ^StackAllocatorData, size: int) -> rawptr {
        free := this.size - int(uintptr(this.free_ptr) - uintptr(this.base));
        needed := align_8(size);
        ret_ptr := this.free_ptr;
        if(needed < free) {
            this.free_ptr = forward(this.free_ptr, needed, 8);
            this.stack[this.index] = uintptr(ret_ptr);
            this.index += 1;
            return ret_ptr;
        }
        return nil;
    }

    stack_free :: proc(this: ^StackAllocatorData, mem: rawptr) {
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

