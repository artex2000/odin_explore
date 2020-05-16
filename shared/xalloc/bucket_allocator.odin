package xalloc

import "core:mem"
import "core:fmt"
import rt "core:runtime"

BucketAllocatorData :: struct {
    base: rawptr,
    free_ptr: rawptr,
    size: int,
    back: mem.Allocator, 
    next: rawptr
}

bucket_allocator :: proc(size: int, back: mem.Allocator, flags: u64 = 0) -> mem.Allocator {
    //make sure backup allocator is our block allocator
    assert(is_block_allocator(back));
    ba := cast(^BlockAllocatorData)back.data;

    needed := size;
    if (flags & ALLOCATOR_NO_OVERHEAD) == 0 {
        //calculate needed size including overhead
        required := size + size_of(BucketAllocatorData);
        blocks := required / ba.block_size;
        if (required % ba.block_size) != 0 do blocks += 1;
        needed = blocks * ba.block_size;
    }
    back_mem := back.procedure(back.data, .Alloc, needed, 0, nil, 0, 0);
    assert(back_mem != nil);
    fmt.printf("bucket allocator base %x\n", back_mem);

    data := cast(^BucketAllocatorData)back_mem;
    data.back = back;
    data.base = forward(back_mem, size_of(BucketAllocatorData), 16);
    data.free_ptr = data.base;
    data.size = needed - int(uintptr(data.base) - uintptr(data));
    data.next = nil;

    return mem.Allocator { bucket_allocator_proc, data };
}

bucket_allocator_proc :: proc(data: rawptr, mode: mem.Allocator_Mode,
                             size, alignment: int,
                             old_mem: rawptr, old_size: int, flags: u64 = 0,
                             loc: rt.Source_Code_Location = #caller_location) -> rawptr {

    bucket_alloc :: proc(this: ^BucketAllocatorData, size: int) -> rawptr {
        save := this;
        walk := this;
        needed := align_8(size);
        for walk != nil {
            free := walk.size - int(uintptr(walk.free_ptr) - uintptr(walk.base));
            ret_ptr := walk.free_ptr;
            if(needed < free) {
                walk.free_ptr = forward(walk.free_ptr, size, 8);
                return ret_ptr;
            } else {
                save = walk;    //we need to keep previous pointer
                walk = cast(^BucketAllocatorData)(walk.next);
            }
        }
        //if we're here there are no required free space in previous buckets
        //grab a new one
        walk = save;
        //now how much do we really need? If allocation is small we allocate
        //same size as before. However if allocation is substantial get twice its size
        margin := needed << 6;
        if (margin > walk.size) do margin = margin << 1;
        else                    do margin = walk.size;

        //Align required size to blocks
        ba := cast(^BlockAllocatorData)walk.back.data;
        blocks := margin / ba.block_size;
        if (margin % ba.block_size) != 0 do blocks += 1;

        back_mem := walk.back.procedure(walk.back.data, .Alloc, margin, 0, nil, 0, 0);
        assert(back_mem != nil);

        walk.next = back_mem;

        data := cast(^BucketAllocatorData)back_mem;
        data.back = walk.back;
        data.base = forward(back_mem, size_of(BucketAllocatorData), 16);
        data.free_ptr = data.base;
        data.size = blocks * ba.block_size - int(uintptr(data.base) - uintptr(data));
        data.next = nil;

        //now as we have memory let's give it to the caller
        ret_ptr := data.free_ptr;
        data.free_ptr = forward(data.free_ptr, needed, 8);
        return ret_ptr;
    }

    bucket_free :: proc(this: ^BucketAllocatorData, mem: rawptr) {
        assert(false);
    }

    bucket_free_all :: proc(this: ^BucketAllocatorData) {
        //we will clear all buckets except the first one and return freed memory
        //back to block allocator
        this.free_ptr = this.base;
        save := this;
        walk := cast(^BucketAllocatorData)(this.next);
        for walk != nil {
            save = walk;
            walk = cast(^BucketAllocatorData)(walk.next);
            save.back.procedure(save.back.data, .Free, 0, 0, rawptr(save), 0, 0);
        }
    }

    bucket_resize :: proc(this: ^BucketAllocatorData, size: int,
                        old_mem: rawptr, old_size: int) -> rawptr {
        assert(false);
        return nil;
    }

    this := cast(^BucketAllocatorData)data;
    switch mode {
    case .Alloc:
        return bucket_alloc(this, size);
    case .Free:
        bucket_free(this, old_mem);
    case .Free_All:
        bucket_free_all(this);
    case .Resize:
        return bucket_resize(this, size, old_mem, old_size);
    }
    return nil;
}
