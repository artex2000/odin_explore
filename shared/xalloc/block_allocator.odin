package xalloc


import "core:mem"
import rt "core:runtime"
import ar "shared:array"

BLOCK_ALLOCATOR_SIGNATURE :: 0xBBBB_1111_0000_CCCC;

BlockAllocatorData :: struct {
    signature: u64,
    base: rawptr,
    block_size: int,
    overhead: int,
    toc: ar.BitArray,
    cnt: []u8,
}

block_allocator :: proc(base: rawptr, size: u64, block_size: int) -> mem.Allocator {
    assert((int(uintptr(base)) % block_size) == 0);
    assert((size % u64(block_size)) == 0);
    data := cast(^BlockAllocatorData)base;
    data.block_size = block_size;
    data.base = base;
    data.signature = BLOCK_ALLOCATOR_SIGNATURE;

    //calculate number of blocks required to track
    nb := int(size / u64(block_size));

    //toc data starts right after BlockAllocatorData header
    toc_offset := cast(rawptr)(uintptr(base) + size_of(BlockAllocatorData));
    data.toc = ar.bitarray_init(toc_offset, nb);
    ar.bitarray_clear_all(data.toc);

    //cnt data starts after toc data in bytes( nb / 64 * 8)
    cnt_offset := cast(rawptr)(uintptr(toc_offset) + uintptr(len(data.toc) * 8));
    data.cnt = mem.slice_ptr(cast(^u8)cnt_offset, nb); 
    mem.zero_slice(data.cnt);

    //calc total overhead
    total := size_of(BlockAllocatorData) + len(data.toc) * 8 + len(data.cnt);
    nb = total / block_size;
    if (total % block_size) != 0 do nb += 1;
    data.overhead = nb;

    //reserve first blocks for Allocator data
    if nb == 1 {
        ar.bitarray_set(data.toc, 0);
    } else {
        ar.bitarray_set_range(data.toc, 0, nb);
    }

    return mem.Allocator { block_allocator_proc, data };
}

block_allocator_proc :: proc(data: rawptr, mode: mem.Allocator_Mode,
                             size, alignment: int,
                             old_mem: rawptr, old_size: int, flags: u64 = 0,
                             loc: rt.Source_Code_Location = #caller_location) -> rawptr {

    block_alloc :: proc(this: ^BlockAllocatorData, size: int) -> rawptr {
        assert((size % this.block_size) == 0);
        nb := size / this.block_size;
        idx := -1;
        if nb == 1 {
            idx = ar.bitarray_get_first_zero_index(this.toc);
        } else {
            idx = ar.bitarray_find_clear_range(this.toc, nb);
        }

        if idx == -1 do return nil;

        //mark range as reserved
        if nb == 1 {
            ar.bitarray_set(this.toc, idx);
        } else {
            ar.bitarray_set_range(this.toc, idx, nb);
        }

        //keep number of subsequently allocated blocks
        this.cnt[idx] = u8(nb);
        return cast(rawptr)(uintptr(this.base) + uintptr(idx * this.block_size));
    }

    block_free :: proc(this: ^BlockAllocatorData, old_mem: rawptr) {
        assert((int(uintptr(old_mem)) % this.block_size) == 0);
        idx := int((uintptr(old_mem) - uintptr(this.base))) / this.block_size;
        nb := int(this.cnt[idx]);
        if nb == 1 {
            ar.bitarray_clear(this.toc, idx);
        } else {
            ar.bitarray_clear_range(this.toc, idx, nb);
        }
        this.cnt[idx] = 0;
    }

    block_free_all :: proc(this: ^BlockAllocatorData) {
        ar.bitarray_clear_all(this.toc);
        mem.zero_slice(this.cnt);
        ar.bitarray_set(this.toc, 0);       //keep first block occupied
        if this.overhead > 1 {
            ar.bitarray_set_range(this.toc, 0, this.overhead);
        } else {
            ar.bitarray_clear(this.toc, 0);
        }
    }

    block_resize :: proc(this: ^BlockAllocatorData, size: int,
                        old_mem: rawptr, old_size: int) -> rawptr {
        assert((int(uintptr(old_mem)) % this.block_size) == 0);
        assert((size % this.block_size) == 0);
        assert((old_size % this.block_size) == 0);

        if size == 0 {
            block_free(this, old_mem);
            return nil;
        } else if old_size == size {
            return old_mem;
        }

        idx := int((uintptr(old_mem) - uintptr(this.base))) / this.block_size;
        nb := size / this.block_size;
        old_nb := old_size / this.block_size;
        assert(this.cnt[idx] == u8(old_nb));

        if old_size > size {
            //shink size down
            ar.bitarray_clear_range(this.toc, idx + nb, old_nb - nb);
            this.cnt[idx] = u8(nb);
            return old_mem;
        } else {
            if ar.bitarray_is_range_clear(this.toc, idx + old_nb, nb - old_nb) {
                //if required space is available right behind old allocation
                ar.bitarray_set_range(this.toc, idx + old_nb, nb - old_nb);
                this.cnt[idx] = u8(nb);
                return old_mem;
            } else {
                ar.bitarray_clear_range(this.toc, idx, old_nb);
                return block_alloc(this, size);
            }
        }
    }

    this := cast(^BlockAllocatorData)data;
    switch mode {
    case .Alloc:
        return block_alloc(this, size);
    case .Free:
        block_free(this, old_mem);
    case .Free_All:
        block_free_all(this);
    case .Resize:
        return block_resize(this, size, old_mem, old_size);
    }
    return nil;
}

is_block_allocator :: proc(check: mem.Allocator) -> bool {
    this := cast(^BlockAllocatorData)check.data;
    if this.signature == BLOCK_ALLOCATOR_SIGNATURE do return true;
    return false;
}


