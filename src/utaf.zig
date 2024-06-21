const std = @import("std");
const c = @cImport(@cInclude("murmur3.h"));

pub const rem_t = u8;
pub const REM_SIZE = 8;

pub const elt_t = u64;
pub const hash_t = u128;

pub const UTAF_MAX_SEL = 1 << 8;

pub const seed_t = u32;

pub const FullTAFBlock = struct {
    remainders: [64]rem_t,
    occupieds: std.StaticBitSet(64),
    runends: std.StaticBitSet(64),
    offset: usize,
    selectors: [64]u8,
};

pub const Remote_elt = struct {
    elt: elt_t,
    hash: hash_t,
};

pub const FullTAF = struct {
    a: std.mem.Allocator,
    /// fingerprint prefix size = log2(n/E) to get false-pos rate E
    p: usize,
    /// length of quotient
    q: usize,
    /// length of remainder
    r: usize,
    /// number of slots available (2^q)
    nslots: usize,
    /// nslots/64
    nblocks: usize,
    /// number of elements stored
    nelts: usize,
    /// seed for Murmurhash
    seed: seed_t,
    /// blocks of 64 remainders with metadata
    blocks: []FullTAFBlock,
    /// array of inserted elements (up to 64 bits)
    remote: []Remote_elt,

    fn selector(this: *FullTAF, i: usize) *u8 {
        return &this.blocks[(i) / 64].selectors[(i) % 64];
    }

    fn hash(this: FullTAF, elt: elt_t) hash_t {
        var res: hash_t = undefined;
        c.MurmurHash3_x64_128(&elt, @sizeOf(elt_t), this.seed, &res);
        return res;
    }


    /// Returns the quotient for a 64-bit fingerprint hash.
    fn  calc_quot(this: FullTAF,  hash: usize) usize {
        return hash & ((1 << this.q) - 1);
    }

    /// Returns the k-th remainder for h
    fn  calc_rem(this: FullTAF,  hash: u64, int k) rem_t {
        int n_rems = (64 - (int)this->q)/(int)this->r;
        const n_rems =
        if (k >= n_rems) k %= n_rems;
        return (hash >> (this->q + k * this->r)) & ONES(this->r);
    }

    fn get_occupied(this: *FullTAF, n: usize) {
        
    } 

    pub fn load(this: *FullTAF) f64 {
        return @as(f64, this.nelts) / @as(f64, this.nblocks);
    }

    pub fn init(a: std.mem.Allocator, q: usize, seed: seed_t) !FullTAF {
        var this: @This() = undefined;
        this.a = a;
        this.seed = seed;
        this.nelts = 0;
        this.q = q;
        this.nslots = 1 << q;
        this.nblocks = std.math.divCeil(this.nblocks, 64);
        this.r = REM_SIZE;
        this.p = this.q + this.r;
    }
    fn reinit(this: *FullTAF) !void {
        this.blocks = try this.a.alloc(FullTAFBlock, this.nblocks);
        @memset(this.blocks, std.mem.zeroes(FullTAFBlock));
        this.remote = try this.a.alloc(Remote_elt, this.nslots);
        // @memset(this.remote, std.mem.zeroes(Remote_elt));
    }
    pub fn deinit(this: FullTAF) void {
        this.a.free(this.blocks);
        this.a.free(this.remote);
    }
    pub fn clear(this: *FullTAF) !void {
        this.deinit();
        try this.reinit();
        this.nelts = 0;
    }

    pub const RankSelectResult = union(enum) {
        empty,
        overflow,
        ok: usize,
    };

    pub fn lookup(this: *FullTAF, elt: elt_t) bool {
        const hash = this.hash(elt);
        const quot = this.calc_quot(hash);

        if (get_occupied(this, quot)) {
            const loc = rank_select(this, quot);
            if (loc == .empty || loc == .overflow) {
                return false;
            }
            do {
                int sel = selector(this, loc);
                rem_t rem = calc_rem(this, hash, sel);
                if (remainder(this, loc) == rem) {
                    // Check remote
                    if (elt != this->remote[loc].elt) {
                    adapt(this, elt, loc, quot, hash);
                    }
                    return true;
                }
                loc--;
            } while (loc >= (int)quot && !get_runend(this, loc));
        }
        return false;
    }

    pub fn insert(this: *FullTAF, elt: elt_t) void {
        const hash = this.hash(elt);
        const quot = this.calc_quot(hash);
        const rem = this.calc_rem(hash, 0);
    }
};

// // Printing
// void print_utaf( this: *FullTAF);
// void print_utaf_metadata( this: *FullTAF);
// void print_utaf_stats( this: *FullTAF);
// void print_utaf_block( this: *FullTAF, size_t block_index);
