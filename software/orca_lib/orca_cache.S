.globl orca_writeback_dcache_range
.type orca_writeback_dcache_range, @function

//Writeback data in D$ to memory.
orca_writeback_dcache_range:
        .word 0x08B5160F //CACHE.WRITEBACK a2, a0, a1
        bleu a2, a0, writeback_done
        mv a0, a2
        addi a2, a2, -1
        bltu a2, a1, orca_writeback_dcache_range
writeback_done:
        ret

.globl orca_flush_dcache_range
.type orca_flush_dcache_range, @function

//Flush (writeback to memory then invalidate) data in D$.
orca_flush_dcache_range:
        .word 0x0AB5160F //CACHE.FLUSH a2, a0, a1
        bleu a2, a0, flush_done
        mv a0, a2
        addi a2, a2, -1
        bltu a2, a1, orca_flush_dcache_range
flush_done:
        ret

.globl orca_invalidate_dcache_range
.type orca_invalidate_dcache_range, @function

//Invalidate data in D$.
orca_invalidate_dcache_range:
        .word 0x0CB5160F //CACHE.INVALIDATE a2, a0, a1
        bleu a2, a0, invalidate_done
        mv a0, a2
        addi a2, a2, -1
        bltu a2, a1, orca_invalidate_dcache_range
invalidate_done:
        ret
