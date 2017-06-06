-- dma_engine_axi.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.
--
-- DMA engine with AXI4 master interface and behavioural FIFO.
--
-- Supports 2D DMA, i.e. transfer of multiple rows of data, with different
-- row strides (ext_incr, scratch_incr) allowed for external and scratchpad
-- accesses).
--
-- The external and scratchpad start addresses can have any byte alignment.
-- The scratchpad address presented to the scratchpad arbiter is
-- internally modified so that the alignment network performs the
-- appropriate shifting.
--
-- For example, if the external data bus width is N bytes, and the
-- byte in external byte lane i is to be written to byte lane j of the
-- k-th N-byte-aligned word in scratch, the scratchpad byte address used is
-- k*N + (j-i). This causes each byte in the external N-byte word to be
-- shifted by j-i bytes (shifted up if j - i > 0, else shifted down).
-- Expressed another way, if the target scratchpad address is A (=k*N+j),
-- and the source address modulo N is i, then the address applied to the
-- scratchpad arbiter's alignment network should be A-i.
--
-- For 1D DMA, rows should be set to 1. The two_d flag is not used.
--
-- Note: If the end of a row and the beginning of the next row are in
-- same N-byte aligned word, the word will be accessed twice (once for
-- the end of the first row, and once for the start of the next row).
--
-- Note: No action is taken on a read reponse error (rresp != OKAY)
-- or a write response error (bresp != OKAY).
--
---------------------------------------------------------------------------

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
-- for conv_integer and operations mixing std_logic_vector and unsigned
-- integers.
use IEEE.std_logic_unsigned.all;
library work;
use work.util_pkg.all;
use work.architecture_pkg.all;

entity dma_engine_axi is
  generic (
    VECTOR_LANES       : integer := 1;
    -- Max data bus width supported by AXI is 1024 bits (32*32)
    -- Must also be a power of 2.
    MEMORY_WIDTH_LANES : integer range 1 to 32 := 1;
    -- An AXI burst cannot cross a 4KB boundary.
    -- The maximum burst size must also be a power of 2.
    BURSTLENGTH_BYTES  : integer range 4 to 4096 := 32;

    -- scratchpad address width
    ADDR_WIDTH : integer := 1;
    -- AXI master address width
    C_M_AXI_ADDR_WIDTH   : integer := 32;
    C_M_AXI_ARUSER_WIDTH : integer :=  5;
    C_M_AXI_AWUSER_WIDTH : integer :=  5
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    update_scratchpad_start : out std_logic;
    new_scratchpad_start    : out std_logic_vector(ADDR_WIDTH-1 downto 0);

    update_external_start   : out std_logic;
    new_external_start      : out std_logic_vector(31 downto 0);

    decrement_rows          : out std_logic;

    dma_request_in  : out std_logic_vector(scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    dma_request_out : in std_logic_vector(scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

    dma_queue_read  : out std_logic;
    dma_in_progress : out std_logic;
    current_dma     : in std_logic_vector(dma_info_length(ADDR_WIDTH)-1 downto 0);

    -- AXI4 Master

    m_axi_arready      : in  std_logic;
    m_axi_arvalid      : out std_logic;
    m_axi_araddr       : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    m_axi_arlen        : out std_logic_vector(7 downto 0);
    m_axi_arsize       : out std_logic_vector(2 downto 0);
    m_axi_arburst      : out std_logic_vector(1 downto 0);
    m_axi_arprot       : out std_logic_vector(2 downto 0);
    m_axi_arcache      : out std_logic_vector(3 downto 0);
    m_axi_aruser       : out std_logic_vector(C_M_AXI_ARUSER_WIDTH-1 downto 0);

    m_axi_rready       : out std_logic;
    m_axi_rvalid       : in  std_logic;
    m_axi_rdata        : in  std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);
    m_axi_rresp        : in  std_logic_vector(1 downto 0);
    m_axi_rlast        : in  std_logic;

    m_axi_awready      : in  std_logic;
    m_axi_awvalid      : out std_logic;
    m_axi_awaddr       : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    m_axi_awlen        : out std_logic_vector(7 downto 0);
    m_axi_awsize       : out std_logic_vector(2 downto 0);
    m_axi_awburst      : out std_logic_vector(1 downto 0);
    m_axi_awprot       : out std_logic_vector(2 downto 0);
    m_axi_awcache      : out std_logic_vector(3 downto 0);
    m_axi_awuser       : out std_logic_vector(C_M_AXI_AWUSER_WIDTH-1 downto 0);

    m_axi_wready       : in  std_logic;
    m_axi_wvalid       : out std_logic;
    m_axi_wdata        : out std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);
    m_axi_wstrb        : out std_logic_vector(MEMORY_WIDTH_LANES*4-1 downto 0);
    m_axi_wlast        : out std_logic;

    m_axi_bready       : out std_logic;
    m_axi_bvalid       : in  std_logic;
    m_axi_bresp        : in  std_logic_vector(1 downto 0)
    );
end entity dma_engine_axi;

architecture rtl of dma_engine_axi is
  -- Additional cycles of latency for scratchpad reads due to alignment network
  -- in scratchpad arbiter.
  constant EXTRA_ALIGN_STAGES : natural := arbiter_extra_align_stages(VECTOR_LANES);

  -- ratio of the scratchpad width to the memory bus width.
  -- Always >= 1 since memory_width_lanes <= vector_lanes.
  constant VECTOR_MEMORY_WIDTHS : integer := VECTOR_LANES/MEMORY_WIDTH_LANES;

  constant MEMORY_WIDTH_BYTES   : integer := MEMORY_WIDTH_LANES*4;
  constant MEMORY_WIDTH_BITS    : integer := MEMORY_WIDTH_LANES*32;

  -- Number of bits needed to represent number of memory-width beats
  -- to transfer a row of data. A row can span the entire size of the
  -- scratchpad, so this is the number of bits needed to represent
  -- the number of memory-width words in scratchpad.
  constant BEATS_W : integer := log2((2**ADDR_WIDTH)/MEMORY_WIDTH_BYTES);
  -- equivalent to (ADDR_WIDTH - log2(MEMORY_WIDTH_BYTES)).

  -- Number of bits needed to select one of MEMORY_WIDTH_BYTES byte lanes.
  constant BYTE_SEL_W : integer := log2(MEMORY_WIDTH_BYTES);

   -- number of bits needed to represent max burst size in bytes.
  -- (burstlength_bytes is expected to be a power of 2)
  -- constant BURSTLENGTH_BYTES_W      : integer := log2(BURSTLENGTH_BYTES+1);

  -- beats per burst
  constant BEATS_PER_BURST   : integer := BURSTLENGTH_BYTES/MEMORY_WIDTH_BYTES;
  constant BEATS_PER_BURST_W : integer := log2(BEATS_PER_BURST);

  -- constant FIFO_DEPTH  : integer := BEATS_PER_BURST*DMA_DATA_FIFO_BURSTS;
  -- DMA engine has a dedicated port to scratchpad, so why do we need a FIFO?
  -- On DMA reads, the scratchpad can sink data as quickly as it arrives;
  -- On DMA writes, the FIFO can help a bit to hide scratchpad read latency
  -- if the AXI slave inserts wait states which would otherwise cause scratchpad
  -- reads to be paused and restarted.
  -- 256x32 is the largest x32 configuration that will fit in a single
  -- 9Kb RAMB8WER BRAM in Spartan-6.
  constant FIFO_DEPTH  : integer := 256;
  -- fifo address bits
  constant FIFO_AW     : integer := log2(FIFO_DEPTH);

  ---------------------------------------------------------------------------
  constant AXI_BURST_INCR : std_logic_vector(1 downto 0) := "01";
  -- Xilinx UG761 AXI Reference Guide recommended values:
  -- bit 2: data access = 0
  -- bit 1: secure access = 0
  -- bit 0: unprivileged access = 0
  constant AXI_PROT_DEFAULT : std_logic_vector(2 downto 0) := "000";
  -- Xilinx UG761 AXI Reference Guide recommended values for AxCACHE:
  -- 0011 = "normal, non-cacheable, modifiable, bufferable"
  -- In AXI4, the AxCACHE[3:2] bits indicate if "an allocation occurs for the
  -- transaction" and "if an allocation could have been made due to another
  -- transaction". "A transaction does not need to be looked up in a cache if
  -- the value of AxCACHE[3:2] is 0b00."
  -- AxCACHE[1] = modifiable, AxCACHE[0] = bufferable.
  constant AXI_CACHE_DEFAULT : std_logic_vector(3 downto 0) := "0011";
  -- NOTE: AxCACHE bits are interpreted differenty in AXI4 and AXI3!
  -- UG761 says "Infrastructure IP will pass Cache bits across a system."
  -- In AXI3, 0011 means, from bit 3 downto 0, means no write-allocate,
  -- no read-allocate, cacheable, bufferable.

  -- Cortex-A9 MPCore TRM uses following encoding for AxUSERM (AXI master
  -- AxUSER port):
  --   AxUSERMx[4:1]: Inner attributes
  --     b0000 Strongly-ordered.
  --     b0001 Device.
  --     b0011 Normal Memory Non-Cacheable.
  --     b0110 Write-Through.
  --     b0111 Write-Back no Write Allocate.
  --     b1111 Write-Back Write Allocate.
  --   AxUSERMx[0]: shared bit (0 = coherent request, 1 = non-coherent request)
  -- On ACP interface, only care about bit 0.
  constant AXI_ARUSER_DEFAULT : std_logic_vector(C_M_AXI_ARUSER_WIDTH-1 downto 0)
    := (0 => '1', others => '0');
  constant AXI_AWUSER_DEFAULT : std_logic_vector(C_M_AXI_AWUSER_WIDTH-1 downto 0)
    := (0 => '1', others => '0');

  -- transfer size (per beat) in bytes
  constant AXI_SIZE_1   : std_logic_vector(2 downto 0) := "000";
  constant AXI_SIZE_2   : std_logic_vector(2 downto 0) := "001";
  constant AXI_SIZE_4   : std_logic_vector(2 downto 0) := "010";
  constant AXI_SIZE_8   : std_logic_vector(2 downto 0) := "011";
  constant AXI_SIZE_16  : std_logic_vector(2 downto 0) := "100";
  constant AXI_SIZE_32  : std_logic_vector(2 downto 0) := "101";
  constant AXI_SIZE_64  : std_logic_vector(2 downto 0) := "110";
  constant AXI_SIZE_128 : std_logic_vector(2 downto 0) := "111";

  -- maximum number of AXI read address or write data transactions that can
  -- be issued before a completion is required.
  -- On Zynq S_AXI_HP0 port, wvalid+wlast to bvalid latency is around 12
  -- cycles, so to support back-to-back single-beat bursts (2D DMA with one
  -- beat per row), will need to be able to support at least 12 oustanding
  -- write completions.
  constant MAX_AXI_ISSUE : integer := 15;

  ---------------------------------------------------------------------------
  type dma_info is record
    valid            : std_logic;
    two_d            : std_logic;
    scratchpad_write : std_logic;
    scratchpad_start : std_logic_vector(ADDR_WIDTH-1 downto 0);
    scratchpad_end   : std_logic_vector(ADDR_WIDTH downto 0);
    length           : std_logic_vector(ADDR_WIDTH downto 0);
    external_start   : std_logic_vector(31 downto 0);
    rows             : std_logic_vector(ADDR_WIDTH-1 downto 0);
    ext_incr         : std_logic_vector(31 downto 0);
    scratch_incr     : std_logic_vector(ADDR_WIDTH-1 downto 0);
  end record;

  signal dma_record : dma_info;

  ---------------------------------------------------------------------------
  signal sp_rd, nxt_sp_rd  : std_logic;
  signal sp_wr, nxt_sp_wr  : std_logic;
  signal sp_addr           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal sp_writedata      : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal sp_byteena        : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal nxt_sp_byteena    : std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);

  signal waitrequest   : std_logic;
  signal readdatavalid : std_logic;
  signal readdata      : std_logic_vector((VECTOR_LANES*4*9)-1 downto 0);
  signal readdata_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);

  ---------------------------------------------------------------------------
  type ram_type is array (FIFO_DEPTH-1 downto 0) of
    std_logic_vector(MEMORY_WIDTH_BITS-1 downto 0);
  -- To infer a true DP RAM with Vivado Synthesis, must use separate processes
  -- for each port, and thus a shared variable.
  -- signal fifo : ram_type;
  shared variable fifo : ram_type;

  signal fifo_wr       : std_logic;
  signal fifo_rd       : std_logic;
  signal wr_ptr        : std_logic_vector(FIFO_AW-1 downto 0);
  signal rd_ptr        : std_logic_vector(FIFO_AW-1 downto 0);
  signal rd_ptr_reg    : std_logic_vector(FIFO_AW-1 downto 0);
  signal fifo_data_in  : std_logic_vector(MEMORY_WIDTH_BITS-1 downto 0);
  signal fifo_data_out : std_logic_vector(MEMORY_WIDTH_BITS-1 downto 0);

  -- +1 bit, to make large enough to fit 2**FIFO_AW.
  signal fifo_level    : std_logic_vector(FIFO_AW downto 0);
  signal fifo_empty    : std_logic;
  signal fifo_full     : std_logic;

  signal sp_reads_outs : std_logic_vector(FIFO_AW downto 0);

  ---------------------------------------------------------------------------
  signal dma_read, dma_write      : std_logic;
  signal sp_fifo_wr, sp_fifo_rd   : std_logic;
  signal axi_fifo_wr, axi_fifo_rd : std_logic;

  signal sp_decr_rows : std_logic;
  signal ax_decr_rows : std_logic;

  ---------------------------------------------------------------------------
  type sp_state_type is (S_SP_IDLE,
                         S_SP_ROW0_START,
                         S_SP_XFER,
                         S_SP_XFER_WAIT,
                         S_SP_WAIT_DONE);
  signal sp_state, nxt_sp_state : sp_state_type;

  signal sp_rows, nxt_sp_rows : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal sp_next_row_start, nxt_sp_next_row_start :
    std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal sp_next_ext_row_start, nxt_sp_next_ext_row_start :
    std_logic_vector(31 downto 0);
  signal sp_next_ext_row_end, nxt_sp_next_ext_row_end :
    std_logic_vector(31 downto 0);
  signal sp_next_row_beats_rem, nxt_sp_next_row_beats_rem :
    std_logic_vector(BEATS_W-1 downto 0);
  signal sp_row_beats_rem, nxt_sp_row_beats_rem :
    std_logic_vector(BEATS_W-1 downto 0);
  signal sp_last_be, nxt_sp_last_be :
    std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);
  signal sp_saved_start, nxt_sp_saved_start :
    std_logic_vector(ADDR_WIDTH-1 downto 0);

  ---------------------------------------------------------------------------
  type ax_state_type is (S_AX_IDLE,
                         S_AX_ROW0_START,
                         S_AX_ADDR,
                         S_AX_ADDR_WAIT,
                         S_AX_WAIT_COMPL);
  signal ax_state, nxt_ax_state : ax_state_type;
  signal arvalid, nxt_arvalid : std_logic;
  signal awvalid, nxt_awvalid : std_logic;
  signal axlen, nxt_axlen : std_logic_vector(BEATS_PER_BURST_W-1 downto 0);

  -- 0..2**BEATS_W (not 2**BEATS_W-1)
  signal ax_row_beats_rem, nxt_ax_row_beats_rem :
    std_logic_vector(BEATS_W downto 0);
  signal ax_next_row_beats_rem, nxt_ax_next_row_beats_rem :
    std_logic_vector(BEATS_W downto 0);
  -- 0..BEATS_PER_BURST (not BEATS_PER_BURST-1)
  signal ax_burst_beats, nxt_ax_burst_beats :
    std_logic_vector(BEATS_PER_BURST_W downto 0);
  signal ax_rows, nxt_ax_rows : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal ax_next_row_start, nxt_ax_next_row_start :
    std_logic_vector(31 downto 0);
  signal ax_saved_ext_start, nxt_ax_saved_ext_start :
    std_logic_vector(31 downto 0);

  signal axsize : std_logic_vector(2 downto 0);

  signal axi_done : std_logic;

  ---------------------------------------------------------------------------
  signal rem_compl : std_logic_vector(log2(MAX_AXI_ISSUE+1)-1 downto 0);
  signal incr_rem_compl_wr : std_logic;
  signal incr_rem_compl_rd : std_logic;
  signal decr_rem_compl_wr : std_logic;
  signal decr_rem_compl_rd : std_logic;

  ---------------------------------------------------------------------------
  type w_state_type is (S_W_IDLE,
                        S_W_ROW0_START,
                        S_W_WAIT,
                        S_W_XFER,
                        S_W_WAIT_COMPL);
  signal w_state, nxt_w_state : w_state_type;
  signal wvalid, nxt_wvalid : std_logic;
  signal wlast, nxt_wlast   : std_logic;
  signal wstrb, nxt_wstrb   : std_logic_vector(MEMORY_WIDTH_LANES*4-1 downto 0);

  signal w_row_beats_rem, nxt_w_row_beats_rem :
    std_logic_vector(BEATS_W downto 0);
  signal w_next_row_beats_rem, nxt_w_next_row_beats_rem :
    std_logic_vector(BEATS_W downto 0);
  signal w_burst_beats_rem, nxt_w_burst_beats_rem :
    std_logic_vector(BEATS_PER_BURST_W-1 downto 0);
  signal w_next_row_start, nxt_w_next_row_start : std_logic_vector(31 downto 0);
  signal w_next_row_end, nxt_w_next_row_end     : std_logic_vector(31 downto 0);
  signal w_addr, nxt_w_addr : std_logic_vector(31 downto 0);
  signal w_rows, nxt_w_rows : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal w_last_be, nxt_w_last_be : std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);

  ---------------------------------------------------------------------------
  type b_state_type is (S_B_IDLE, S_B_WAIT);
  signal b_state, nxt_b_state : b_state_type;
  signal bready, nxt_bready : std_logic;

  ---------------------------------------------------------------------------
  type r_state_type is (S_R_IDLE, S_R_WAIT, S_R_XFER);
  signal r_state, nxt_r_state : r_state_type;
  signal rready, nxt_rready : std_logic;

  ---------------------------------------------------------------------------
  signal sp_data_out : std_logic_vector(MEMORY_WIDTH_BITS-1 downto 0);

  ---------------------------------------------------------------------------
  -- return external address aligned to MEMORY_WIDTH_BYTES boundary.
  function ext_aligned (
    ext_addr : std_logic_vector(31 downto 0))
    return std_logic_vector is

    variable aligned_addr : std_logic_vector(31 downto 0);
  begin
    aligned_addr := ext_addr;
    aligned_addr(BYTE_SEL_W-1 downto 0) := (others => '0');
    return aligned_addr;
  end;

  ---------------------------------------------------------------------------
  -- Compute address of last byte in row given row start address and row
  -- length in bytes.
  function row_end (
    ext_row_start : std_logic_vector(31 downto 0);
    row_length    : std_logic_vector(ADDR_WIDTH downto 0))
    return std_logic_vector is

    variable ext_row_end : std_logic_vector(31 downto 0);
  begin
    ext_row_end := ext_row_start + (row_length - 1);
    return ext_row_end;
  end;

  ---------------------------------------------------------------------------
  -- Compute the total number of external memory-width beats (minus 1)
  -- (beat = single-cycle xfer) that will be required to transfer row_length
  -- bytes of data starting at address ext_row_start.
  function row_beats_m1 (
    ext_row_start : std_logic_vector(31 downto 0);
    ext_row_end   : std_logic_vector(31 downto 0))
    return std_logic_vector is

    variable beats_m1 : std_logic_vector(31-BYTE_SEL_W downto 0);
  begin
    beats_m1 := ext_row_end(31 downto BYTE_SEL_W) -
                ext_row_start(31 downto BYTE_SEL_W);
    -- Truncate upper bits (should be 0).
    -- Max value is number of MEMORY_WIDTH_BYTES-sized words in scratchpad,
    -- minus 1.
    return beats_m1(BEATS_W-1 downto 0);
  end;

  ---------------------------------------------------------------------------
  -- Compute the total number of external memory-width beats that will be
  -- required to transfer row_length bytes of data starting at address
  -- ext_row_start.
  function row_beats (
    ext_row_start : std_logic_vector(31 downto 0);
    ext_row_end   : std_logic_vector(31 downto 0))
    return std_logic_vector is

    -- Note: one bit wider to accomodate pathological case where row spans
    -- entire external memory space (which would mean that scratchpad is 4GB).
    variable beats : std_logic_vector(31-BYTE_SEL_W+1 downto 0);
  begin
    beats := ("0" & ext_row_end(31 downto BYTE_SEL_W)) -
             ("0" & ext_row_start(31 downto BYTE_SEL_W)) + 1;
    -- Truncate upper bits (should be 0).
    -- Max value is number of MEMORY_WIDTH_BYTES-sized words in scratchpad.
    return beats(BEATS_W downto 0);
  end;

  ---------------------------------------------------------------------------
  -- Given scratchpad row_start address and external row_start address,
  -- with possibly different byte offsets,
  -- return adjusted scratchpad address to apply to alignment network
  -- in scratchpad_arbiter so that data is appropriately shifted when it is
  -- written to or read from scratchpad.
  function adjust_sp_addr (
    sp_row_start : std_logic_vector(ADDR_WIDTH-1 downto 0);
    ext_row_start : std_logic_vector(31 downto 0))
    return std_logic_vector is

    variable adj_sp_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
    variable ext_start_lane : std_logic_vector(BYTE_SEL_W-1 downto 0);
  begin
    ext_start_lane := ext_row_start(BYTE_SEL_W-1 downto 0);
    adj_sp_addr := sp_row_start - ext_start_lane;
    return adj_sp_addr;
  end;

  ---------------------------------------------------------------------------
  -- Given external row start address, return byte enables for first beat.
  function first_be (ext_row_start : std_logic_vector)
    return std_logic_vector is

    variable i : integer;
    variable start_lane : integer;
    variable enable : std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);
  begin
    start_lane := to_integer(unsigned(ext_row_start(BYTE_SEL_W-1 downto 0)));
    for i in 0 to MEMORY_WIDTH_BYTES-1 loop
      if i >= start_lane then
        enable(i) := '1';
      else
        enable(i) := '0';
      end if;
    end loop;
    return enable;
  end;

  ---------------------------------------------------------------------------
  -- Given external row end address, return byte enables for last beat.
  function last_be (ext_row_end : std_logic_vector)
    return std_logic_vector is

    variable i : integer;
    variable end_lane : integer;
    variable enable : std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);
  begin
    end_lane := to_integer(unsigned(ext_row_end(BYTE_SEL_W-1 downto 0)));
    for i in 0 to MEMORY_WIDTH_BYTES-1 loop
      if i <= end_lane then
        enable(i) := '1';
      else
        enable(i) := '0';
      end if;
    end loop;
    return enable;
  end;

  ---------------------------------------------------------------------------
  -- Compute number of beats to issue in an AXI burst, given the next
  -- external address (about to be clocked out) and the number of beats
  -- remaining for the row.
  --
  -- External address is supposed to be aligned to a MEMORY_WIDTH_BYTES
  -- boundary, but the lower BYTE_SEL_W bits of the address are ignored
  -- anyway.
  --
  -- Burst up to next BURSTLENGTH_BYTES boundary, so that subsequent
  -- bursts start at BURSTLENGTH_BYTES aligned address. This may
  -- improve memory performance e.g. if there is a performance penalty
  -- when only partially modifying a row.
  -- BURSTLENGTH_BYTES is assumed to evenly divide in 4KB, so this also
  -- breaks transfers that would cross a 4KB boundary.
  --
  -- NOTE: this version won't split a burst at a BURSTLENGTH_BYTES
  -- boundary if row_beats_rem <= beats_per_burst and there won't be a 4KB
  -- boundary crossing.
  function burst_beats_orig (
    ext_addr : std_logic_vector(31 downto 0);
    row_beats_rem : std_logic_vector(BEATS_W downto 0))
    return std_logic_vector is

    variable beats_til_4kb :
      std_logic_vector(log2(4096/MEMORY_WIDTH_BYTES) downto 0);
    variable beats : std_logic_vector(BEATS_PER_BURST_W downto 0);
  begin

    beats_til_4kb := (4096/MEMORY_WIDTH_BYTES) -
                     ("0" & ext_addr(11 downto BYTE_SEL_W));

    if (row_beats_rem > BEATS_PER_BURST) or (row_beats_rem > beats_til_4kb) then
      -- BURSTLENGTH_BYTES = BEATS_PER_BURST*MEMORY_WIDTH_BYTES
      -- log2(BURSTLENGTH_BYTES)
      -- = log2(BEATS_PER_BURST) + log2(MEMORY_WIDTH_BYTES)
      -- = BEATS_PER_BURST_W + BYTE_SEL_W
      beats := BEATS_PER_BURST -
               ("0" & ext_addr(BYTE_SEL_W+BEATS_PER_BURST_W-1 downto BYTE_SEL_W));
    else
      beats := row_beats_rem(beats'range);
    end if;

    return beats;
  end burst_beats_orig;

  ---------------------------------------------------------------------------
  -- This version always breaks bursts at BURSTLENGTH_BYTES boundaries
  -- (even if row_beats_rem <= BEATS_PER_BURST).
  function burst_beats (
    ext_addr : std_logic_vector(31 downto 0);
    row_beats_rem : std_logic_vector(BEATS_W downto 0))
    return std_logic_vector is

    variable beats_to_bdry : std_logic_vector(BEATS_PER_BURST_W downto 0);
    variable beats : std_logic_vector(BEATS_PER_BURST_W downto 0);
  begin

    beats_to_bdry := BEATS_PER_BURST -
               ("0" & ext_addr(BYTE_SEL_W+BEATS_PER_BURST_W-1 downto BYTE_SEL_W));
    if row_beats_rem < beats_to_bdry then
      beats := row_beats_rem(beats'range);
    else
      beats := beats_to_bdry;
    end if;

    return beats;
  end burst_beats;

  ---------------------------------------------------------------------------
  -- increment the given address by beats*MEMORY_WIDTH_BYTES.
  function incr_ext_addr (
    ext_addr : std_logic_vector(31 downto 0);
    beats    : std_logic_vector(BEATS_PER_BURST_W downto 0))
    return std_logic_vector is

    variable beat_shift : std_logic_vector(BYTE_SEL_W-1 downto 0) := (others => '0');
    variable new_addr : std_logic_vector(31 downto 0);
  begin
    -- new_addr := ext_addr + beats * MEMORY_WIDTH_BYTES.
    new_addr := ext_addr + (beats & beat_shift);
    return new_addr;
  end;

  ---------------------------------------------------------------------------
  -- valid values of beats are 1..BEATS_PER_BURST.
  function beats_minus1 (
    beats : std_logic_vector(BEATS_PER_BURST_W downto 0))
    return std_logic_vector is

    variable beats_m1 : std_logic_vector(BEATS_PER_BURST_W downto 0);
  begin
    beats_m1 := beats - 1;
    return beats_m1(BEATS_PER_BURST_W-1 downto 0);
  end;
  ---------------------------------------------------------------------------
begin

  m_axi_arburst <= AXI_BURST_INCR;
  m_axi_arprot  <= AXI_PROT_DEFAULT;
  m_axi_arcache <= AXI_CACHE_DEFAULT;
  m_axi_aruser  <= AXI_ARUSER_DEFAULT;

  m_axi_awburst <= AXI_BURST_INCR;
  m_axi_awprot  <= AXI_PROT_DEFAULT;
  m_axi_awcache <= AXI_CACHE_DEFAULT;
  m_axi_awuser  <= AXI_AWUSER_DEFAULT;

  ---------------------------------------------------------------------------
  -- to scratchpad arbiter
  dma_request_in <= scratchpad_request_in_flatten(sp_rd,
                                                  sp_wr,
                                                  sp_addr,
                                                  sp_writedata,
                                                  sp_byteena);

  ---------------------------------------------------------------------------
  -- from scratchpad arbiter
  waitrequest   <= scratchpad_request_out_get(dma_request_out,
                                              REQUEST_OUT_WAITREQUEST,
                                              VECTOR_LANES, ADDR_WIDTH)(0);

  readdatavalid <= scratchpad_request_out_get(dma_request_out,
                                              REQUEST_OUT_READDATAVALID,
                                              VECTOR_LANES, ADDR_WIDTH)(0);
  -- slv of 4*9 bits per vector lane
  readdata      <= scratchpad_request_out_get(dma_request_out,
                                              REQUEST_OUT_READDATA,
                                              VECTOR_LANES,
                                              ADDR_WIDTH);

  -- only the lower bits are used to determine which lanes contain
  -- valid data.
  readdata_addr <= scratchpad_request_out_get(dma_request_out,
                                              REQUEST_OUT_READDATA_ADDR,
                                              VECTOR_LANES,
                                              ADDR_WIDTH);

  ---------------------------------------------------------------------------
  dma_record.valid            <= dma_info_get(current_dma,
                                              DMA_INFO_GET_VALID,
                                              ADDR_WIDTH)(0);
  dma_record.two_d            <= dma_info_get(current_dma,
                                              DMA_INFO_GET_TWO_D,
                                              ADDR_WIDTH)(0);
  dma_record.scratchpad_write <= dma_info_get(current_dma,
                                              DMA_INFO_GET_SCRATCHPAD_WRITE,
                                              ADDR_WIDTH)(0);
  dma_record.scratchpad_start <= dma_info_get(current_dma,
                                              DMA_INFO_GET_SCRATCHPAD_START,
                                              ADDR_WIDTH);
  -- not used
  dma_record.scratchpad_end   <= dma_info_get(current_dma,
                                              DMA_INFO_GET_SCRATCHPAD_END,
                                              ADDR_WIDTH);
  dma_record.length           <= dma_info_get(current_dma,
                                              DMA_INFO_GET_LENGTH,
                                              ADDR_WIDTH);
  dma_record.external_start   <= dma_info_get(current_dma,
                                              DMA_INFO_GET_EXTERNAL_START,
                                              ADDR_WIDTH);
  dma_record.rows             <= dma_info_get(current_dma,
                                              DMA_INFO_GET_ROWS,
                                              ADDR_WIDTH);
  dma_record.ext_incr         <= dma_info_get(current_dma,
                                              DMA_INFO_GET_EXT_INCR,
                                              ADDR_WIDTH);
  dma_record.scratch_incr     <= dma_info_get(current_dma,
                                              DMA_INFO_GET_SCRATCH_INCR,
                                              ADDR_WIDTH);

  ---------------------------------------------------------------------------
  -- FSM for Scratchpad Interface

  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        sp_state <= S_SP_IDLE;
        sp_rd <= '0';
        sp_wr <= '0';
        sp_byteena(MEMORY_WIDTH_BYTES-1 downto 0) <= (others => '0');

        sp_rows <= (others => '0');
        sp_next_row_start <= (others => '0');
        sp_next_ext_row_start <= (others => '0');
        sp_next_ext_row_end <= (others => '0');
        sp_next_row_beats_rem <= (others => '0');
        sp_row_beats_rem <= (others => '0');
        sp_last_be <= (others => '0');
        sp_saved_start <= (others => '0');
      else
        sp_state <= nxt_sp_state;
        sp_rd <= nxt_sp_rd;
        sp_wr <= nxt_sp_wr;
        sp_byteena(MEMORY_WIDTH_BYTES-1 downto 0) <= nxt_sp_byteena;

        sp_rows <= nxt_sp_rows;
        sp_next_row_start <= nxt_sp_next_row_start;
        sp_next_ext_row_start <= nxt_sp_next_ext_row_start;
        sp_next_ext_row_end <= nxt_sp_next_ext_row_end;
        sp_next_row_beats_rem <= nxt_sp_next_row_beats_rem;
        sp_row_beats_rem <= nxt_sp_row_beats_rem;
        sp_last_be <= nxt_sp_last_be;
        sp_saved_start <= nxt_sp_saved_start;
      end if;
    end if;
  end process;

  process (sp_state, dma_record, waitrequest, axi_done,
           fifo_level, fifo_empty, sp_reads_outs,
           sp_rd, sp_wr,
           sp_byteena,
           sp_rows,
           sp_next_row_start,
           sp_next_ext_row_start,
           sp_next_ext_row_end,
           sp_next_row_beats_rem,
           sp_row_beats_rem,
           sp_last_be,
           sp_saved_start)
    variable sp_next_ext_row_start_v : std_logic_vector(31 downto 0);
    variable sp_next_ext_row_end_v   : std_logic_vector(31 downto 0);
    variable sp_first_be_v : std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);
    variable sp_last_be_v : std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);
    variable sp_adjusted_addr_v : std_logic_vector(ADDR_WIDTH-1 downto 0);
    variable incr_sp_start_v : std_logic_vector(ADDR_WIDTH-1 downto 0);
  begin

    nxt_sp_state <= sp_state;
    nxt_sp_rd <= sp_rd;
    nxt_sp_wr <= sp_wr;
    nxt_sp_byteena <= sp_byteena(MEMORY_WIDTH_BYTES-1 downto 0);

    nxt_sp_rows <= sp_rows;
    nxt_sp_next_row_start <= sp_next_row_start;
    nxt_sp_next_ext_row_start <= sp_next_ext_row_start;
    nxt_sp_next_ext_row_end <= sp_next_ext_row_end;
    nxt_sp_next_row_beats_rem <= sp_next_row_beats_rem;
    nxt_sp_row_beats_rem <= sp_row_beats_rem;
    nxt_sp_last_be <= sp_last_be;
    nxt_sp_saved_start <= sp_saved_start;

    -- combinational primary outputs to dma_queue.
    update_scratchpad_start <= '0';
    -- default value (note: only sampled by dma_queue when
    -- update_scratchpad_start=1)
    incr_sp_start_v := dma_record.scratchpad_start + MEMORY_WIDTH_BYTES;
    new_scratchpad_start <= incr_sp_start_v;

    dma_queue_read <= '0';

    sp_fifo_rd <= '0';
    sp_decr_rows <= '0';

    case sp_state is
      when S_SP_IDLE =>
        if dma_record.valid = '1' then
          -- prime the next address / beats remaining pipeline.
          nxt_sp_state <= S_SP_ROW0_START;

          nxt_sp_next_row_start <= dma_record.scratchpad_start;

          sp_next_ext_row_start_v := dma_record.external_start;
          sp_next_ext_row_end_v   := row_end(sp_next_ext_row_start_v, dma_record.length);
          nxt_sp_next_ext_row_start <= sp_next_ext_row_start_v;
          nxt_sp_next_ext_row_end   <= sp_next_ext_row_end_v;
          nxt_sp_next_row_beats_rem <= row_beats_m1(sp_next_ext_row_start_v,
                                                    sp_next_ext_row_end_v);

          -- Maintain own row count because dma_record.rows is decremented by
          -- AXI side on scratchpad writes.
          nxt_sp_rows <= dma_record.rows;
        end if;

      when S_SP_ROW0_START =>
        nxt_sp_next_row_start <= sp_next_row_start + dma_record.scratch_incr;

        sp_next_ext_row_start_v := sp_next_ext_row_start + dma_record.ext_incr;
        sp_next_ext_row_end_v   := row_end(sp_next_ext_row_start_v, dma_record.length);
        nxt_sp_next_ext_row_start <= sp_next_ext_row_start_v;
        nxt_sp_next_ext_row_end   <= sp_next_ext_row_end_v;
        nxt_sp_next_row_beats_rem <= row_beats_m1(sp_next_ext_row_start_v,
                                                  sp_next_ext_row_end_v);
        nxt_sp_row_beats_rem <= sp_next_row_beats_rem;

        sp_first_be_v := first_be(sp_next_ext_row_start);
        sp_last_be_v  := last_be(sp_next_ext_row_end);
        nxt_sp_last_be <= sp_last_be_v;

        sp_adjusted_addr_v := adjust_sp_addr(sp_next_row_start,
                                             sp_next_ext_row_start);
        new_scratchpad_start <= sp_adjusted_addr_v;
        nxt_sp_saved_start <= sp_adjusted_addr_v;

        if dma_record.scratchpad_write = '1' then
          -- AXI read, wait for fifo to fill.
          if sp_next_row_beats_rem = 0 then
            -- only one beat for this row
            nxt_sp_byteena <= sp_first_be_v and sp_last_be_v;
          else
            nxt_sp_byteena <= sp_first_be_v;
          end if;
          -- fifo will still be empty at this point, so go straight to
          -- waiting state.
          nxt_sp_state <= S_SP_XFER_WAIT;
        else
          -- AXI write, start reading from scratchpad.
          -- The fifo is expected to be empty at this point.
          nxt_sp_state <= S_SP_XFER;
          nxt_sp_rd <= '1';
          update_scratchpad_start <= '1';
          nxt_sp_byteena <= (others => '1');
        end if;

      when S_SP_XFER =>
        if waitrequest = '0' then
          if sp_row_beats_rem > 0 then

            nxt_sp_row_beats_rem <= sp_row_beats_rem - 1;

            new_scratchpad_start <= incr_sp_start_v;
            -- used in case of wait state (only need to save value in this
            -- register so that S_SP_XFER_WAIT state can be used as both as
            -- wait state in middle of row and wait state at start of new
            -- row).
            nxt_sp_saved_start <= incr_sp_start_v;

            if dma_record.scratchpad_write = '1' then
              if sp_row_beats_rem = 1 then
                nxt_sp_byteena <= sp_last_be;
              else
                nxt_sp_byteena <= (others => '1');
              end if;
              if fifo_empty = '0' then
                nxt_sp_wr <= '1';
                sp_fifo_rd <= '1';
                update_scratchpad_start <= '1';
              else
                -- fifo is empty; wait for data
                nxt_sp_wr <= '0';
                nxt_sp_state <= S_SP_XFER_WAIT;
              end if;
            else
              -- Scratchpad read.
              -- Make sure there is enough space in the FIFO for another word.
              -- There could be a number of words already in flight from
              -- earlier address phases (up to ~ SCRATCHPAD_READ_DELAY +
              -- EXTRA_ALIGN_STAGES+1) and fifo_level doesn't yet reflect any
              -- write done in this cycle.
              if fifo_level + sp_reads_outs < FIFO_DEPTH-1 then
                nxt_sp_rd <= '1';
                update_scratchpad_start <= '1';
              else
                nxt_sp_rd <= '0';
                nxt_sp_state <= S_SP_XFER_WAIT;
              end if;
            end if;
          else
            -- sp_row_beats_rem == 0: last beat in row.
            -- Must decrement dma_record.rows on scratchpad-side for reads.
            if dma_record.scratchpad_write = '0' then
              sp_decr_rows <= '1';
            end if;
            nxt_sp_rows <= sp_rows - 1;

            nxt_sp_next_row_start <= sp_next_row_start + dma_record.scratch_incr;

            sp_next_ext_row_start_v := sp_next_ext_row_start + dma_record.ext_incr;
            sp_next_ext_row_end_v   := row_end(sp_next_ext_row_start_v, dma_record.length);
            nxt_sp_next_ext_row_start <= sp_next_ext_row_start_v;
            nxt_sp_next_ext_row_end   <= sp_next_ext_row_end_v;
            nxt_sp_next_row_beats_rem <= row_beats_m1(sp_next_ext_row_start_v,
                                                      sp_next_ext_row_end_v);
            nxt_sp_row_beats_rem <= sp_next_row_beats_rem;

            sp_first_be_v := first_be(sp_next_ext_row_start);
            sp_last_be_v  := last_be(sp_next_ext_row_end);
            nxt_sp_last_be <= sp_last_be_v;

            sp_adjusted_addr_v :=  adjust_sp_addr(sp_next_row_start,
                                                  sp_next_ext_row_start);
            new_scratchpad_start <= sp_adjusted_addr_v;
            -- needed in case of wait state.
            nxt_sp_saved_start <= sp_adjusted_addr_v;

            if sp_rows > 1 then
              -- more rows remain; start new row.
              if dma_record.scratchpad_write = '1' then
                if sp_next_row_beats_rem = 0 then
                  -- only one beat for row about to start
                  nxt_sp_byteena <= sp_first_be_v and sp_last_be_v;
                else
                  nxt_sp_byteena <= sp_first_be_v;
                end if;
                if fifo_empty = '0' then
                  nxt_sp_wr <= '1';
                  sp_fifo_rd <= '1';
                  update_scratchpad_start <= '1';
                else
                  -- Don't update scratchpad_start yet because sp_wr
                  -- isn't asserted yet, and we don't know what effect this
                  -- might have on dma hazard detection.
                  nxt_sp_wr <= '0';
                  nxt_sp_state <= S_SP_XFER_WAIT;
                end if;
              else
                -- scratchpad read.
                if fifo_level + sp_reads_outs < FIFO_DEPTH-1 then
                  nxt_sp_rd <= '1';
                  update_scratchpad_start <= '1';
                else
                  -- Updating scratchpad_start here might help share logic,
                  -- but given that sp_rd isn't asserted yet, it might not be
                  -- safe for dma hazard detection.
                  nxt_sp_rd <= '0';
                  nxt_sp_state <= S_SP_XFER_WAIT;
                end if;
              end if;
            else
              -- sp_rows == 1 and sp_row_beats_rem == 0. All rows done.
              nxt_sp_rd <= '0';
              nxt_sp_wr <= '0';
              nxt_sp_state <= S_SP_WAIT_DONE;
              -- Avalon dma engine updates sp addr on last beat.
              update_scratchpad_start <= '1';
            end if;
          end if; -- sp_row_beats_rem = 0
        end if; -- waitrequest = '0'

      when S_SP_XFER_WAIT =>
        new_scratchpad_start <= sp_saved_start;

        if dma_record.scratchpad_write = '1' then
          -- wait for data in FIFO before issuing another write.
          -- sp_wr is 0 in this cycle.
          if fifo_empty = '0' then
            nxt_sp_state <= S_SP_XFER;
            nxt_sp_wr <= '1';
            sp_fifo_rd <= '1';
            update_scratchpad_start <= '1';
          end if;
        else
          -- scratchpad read.
          -- wait for room in FIFO before issuing another read.
          -- sp_rd isn't asserted in this cycle, so don't really need the -1,
          -- but keep it allow sharing of logic.
          -- Don't need to check that waitrequest=0 because sp_rd=0 in this
          -- state.
          if fifo_level + sp_reads_outs < FIFO_DEPTH-1 then
            nxt_sp_state <= S_SP_XFER;
            nxt_sp_rd <= '1';
            update_scratchpad_start <= '1';
          end if;
        end if;

      when S_SP_WAIT_DONE =>
        if dma_record.scratchpad_write = '1' then
          -- To match Avalon DMA engine, don't assert queue_read until
          -- cycle after last scratchpad write.
          nxt_sp_state <= S_SP_IDLE;
          dma_queue_read <= '1';
        else
          -- Scratchpad read; wait for AXI writes to complete.
          if axi_done = '1' then
            nxt_sp_state <= S_SP_IDLE;
            dma_queue_read <= '1';
          end if;
        end if;

      when others => null;
    end case;
  end process;

  ---------------------------------------------------------------------------
  dma_read  <= dma_record.valid and dma_record.scratchpad_write;
  dma_write <= dma_record.valid and (not dma_record.scratchpad_write);
  dma_in_progress <= dma_write or dma_read;

  -- scratchpad_start is a register in the dma_queue module that gets set to
  -- new_scratchpad_start when this module asserts update_scratchpad_start.
  -- new_scratchpad_start will be an adjusted address that takes into
  -- account the desired data re-alignment.
  sp_addr <= dma_record.scratchpad_start;

  sp_fifo_wr <= readdatavalid;

  decrement_rows <= sp_decr_rows or ax_decr_rows;

  ---------------------------------------------------------------------------
  -- Count number of outstanding scratchpad reads.
  -- i.e. reads issued to scratchpad for which data has not yet been written
  -- to fifo.

  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        sp_reads_outs <= (others => '0');
      else
        if sp_rd = '1' and sp_fifo_wr = '0' then
          sp_reads_outs <= sp_reads_outs + 1;
        elsif sp_rd = '0' and sp_fifo_wr = '1' then
          sp_reads_outs <= sp_reads_outs - 1;
        end if;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Only the lower MEMORY_WIDTH_BYTES byte lanes of the data bus to the
  -- scratchpad arbiter are used. Set byte enables for unused byte lanes
  -- to 0.

  gen_upper_be : if VECTOR_MEMORY_WIDTHS > 1 generate
    sp_byteena(VECTOR_LANES*4-1 downto MEMORY_WIDTH_BYTES) <= (others => '0');
  end generate gen_upper_be;

  ---------------------------------------------------------------------------
  -- FSM for AXI Read and Write Address Channels.
  --
  -- One notable difference from the scratchpad and AXI write data channel
  -- FSMs is that the latter only need to decrement the number of row beats
  -- remaining by one each cycle, whereas this FSM must decrement the number of
  -- row beats remaning by a variable number of burst beats each cycle.

  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        ax_state <= S_AX_IDLE;
        ax_row_beats_rem <= (others => '0');
        arvalid <= '0';
        awvalid <= '0';
        axlen <= (others => '0');
        ax_burst_beats <= (others => '0');
        ax_rows <= (others => '0');
        ax_next_row_start <= (others => '0');
        ax_next_row_beats_rem <= (others => '0');
        ax_saved_ext_start <= (others => '0');
      else
        ax_state <= nxt_ax_state;
        ax_row_beats_rem <= nxt_ax_row_beats_rem;
        arvalid <= nxt_arvalid;
        awvalid <= nxt_awvalid;
        axlen <= nxt_axlen;
        ax_burst_beats <= nxt_ax_burst_beats;
        ax_rows <= nxt_ax_rows;
        ax_next_row_start <= nxt_ax_next_row_start;
        ax_next_row_beats_rem <= nxt_ax_next_row_beats_rem;
        ax_saved_ext_start <= nxt_ax_saved_ext_start;
      end if;
    end if;
  end process;

  process (ax_state, sp_state, w_state, dma_record, ax_row_beats_rem,
           arvalid, awvalid, axlen, m_axi_arready, m_axi_awready,
           rem_compl, ax_burst_beats, ax_rows,
           ax_next_row_start, ax_next_row_beats_rem,
           ax_saved_ext_start)
    variable ax_next_row_start_v : std_logic_vector(31 downto 0);
    variable ax_next_row_end_v   : std_logic_vector(31 downto 0);
    variable ax_burst_beats_v : std_logic_vector(BEATS_PER_BURST_W downto 0);
    variable incr_external_start_v : std_logic_vector(31 downto 0);
  begin

    nxt_ax_state <= ax_state;
    nxt_ax_row_beats_rem <= ax_row_beats_rem;
    nxt_arvalid <= arvalid;
    nxt_awvalid <= awvalid;
    nxt_axlen <= axlen;
    nxt_ax_burst_beats <= ax_burst_beats;
    nxt_ax_rows <= ax_rows;
    nxt_ax_next_row_start <= ax_next_row_start;
    nxt_ax_next_row_beats_rem <= ax_next_row_beats_rem;
    nxt_ax_saved_ext_start <= ax_saved_ext_start;

    ax_decr_rows <= '0';
    incr_rem_compl_rd <= '0';
    axi_done <= '0';

    -- Combinational primary outputs to dma_queue.
    update_external_start <= '0';
    -- Only valid when update_external_start asserted.
    -- Can be aligned to any byte boundary.
    incr_external_start_v := incr_ext_addr(dma_record.external_start,
                                           ax_burst_beats);
    new_external_start <= incr_external_start_v;

    case ax_state is
      when S_AX_IDLE =>
        if (sp_state = S_SP_IDLE) and dma_record.valid = '1' then
          nxt_ax_state <= S_AX_ROW0_START;

          ax_next_row_start_v := dma_record.external_start;
          ax_next_row_end_v   := row_end(ax_next_row_start_v, dma_record.length);
          nxt_ax_next_row_start <= ax_next_row_start_v;
          nxt_ax_next_row_beats_rem <= row_beats(ax_next_row_start_v,
                                                 ax_next_row_end_v);
          nxt_ax_rows <= dma_record.rows;
        end if;

      when S_AX_ROW0_START =>
        nxt_ax_state <= S_AX_ADDR;
        if dma_record.scratchpad_write = '1' then
          nxt_arvalid <= '1';
        else
          nxt_awvalid <= '1';
        end if;

        -- Don't need to update external start for first beat of first row.
        -- update_external_start <= '1';
        -- new_external_start <= ax_next_row_start;
        ax_next_row_start_v := ax_next_row_start + dma_record.ext_incr;
        ax_next_row_end_v   := row_end(ax_next_row_start_v, dma_record.length);
        nxt_ax_next_row_start <= ax_next_row_start_v;
        nxt_ax_next_row_beats_rem <= row_beats(ax_next_row_start_v,
                                               ax_next_row_end_v);

        ax_burst_beats_v := burst_beats(ax_next_row_start, ax_next_row_beats_rem);
        nxt_axlen <= beats_minus1(ax_burst_beats_v);
        nxt_ax_burst_beats <= ax_burst_beats_v;

        nxt_ax_row_beats_rem <= ax_next_row_beats_rem - ax_burst_beats_v;

      when S_AX_ADDR =>
        if ((dma_record.scratchpad_write = '0') and (m_axi_awready = '1')) or
           ((dma_record.scratchpad_write = '1') and (m_axi_arready = '1')) then
          if dma_record.scratchpad_write = '1' then
            incr_rem_compl_rd <= '1';
          end if;
          if ax_row_beats_rem > 0 then
            -- There is still data to transfer in this row.

            ax_burst_beats_v := burst_beats(incr_external_start_v, ax_row_beats_rem);
            nxt_ax_row_beats_rem <= ax_row_beats_rem - ax_burst_beats_v;
            nxt_axlen <= beats_minus1(ax_burst_beats_v);
            nxt_ax_burst_beats <= ax_burst_beats_v;

            new_external_start <= incr_external_start_v;
            -- saved in case of wait state (because ax_burst_beats will change
            -- in next cycle)
            nxt_ax_saved_ext_start <= incr_external_start_v;

            if dma_record.scratchpad_write = '1' then
              if (rem_compl < MAX_AXI_ISSUE-1) then
                -- Use MAX_AXI_ISSUE-1 because rem_compl is being incremented
                -- in this cycle.
                nxt_arvalid <= '1';
                update_external_start <= '1';
              else
                nxt_awvalid <= '0';
                nxt_arvalid <= '0';
                nxt_ax_state <= S_AX_ADDR_WAIT;
              end if;
            else
              -- Write completions are coupled with write data channel instead
              -- of write address channel (AXI3 only; in AXI4, write completion
              -- cannot precede write address).
              nxt_awvalid <= '1';
              update_external_start <= '1';
            end if;
          else
            -- ax_row_beats_rem == 0: last burst in row
            if dma_record.scratchpad_write = '1' then
              ax_decr_rows <= '1';
            end if;
            nxt_ax_rows <= ax_rows - 1;

            ax_next_row_start_v := ax_next_row_start + dma_record.ext_incr;
            ax_next_row_end_v   := row_end(ax_next_row_start_v, dma_record.length);
            nxt_ax_next_row_start <= ax_next_row_start_v;
            nxt_ax_next_row_beats_rem <= row_beats(ax_next_row_start_v,
                                                   ax_next_row_end_v);

            ax_burst_beats_v := burst_beats(ax_next_row_start, ax_next_row_beats_rem);
            nxt_axlen <= beats_minus1(ax_burst_beats_v);
            nxt_ax_burst_beats <= ax_burst_beats_v;

            nxt_ax_row_beats_rem <= ax_next_row_beats_rem - ax_burst_beats_v;

            new_external_start <= ax_next_row_start;
            -- saved in case of wait state.
            nxt_ax_saved_ext_start <= ax_next_row_start;

            if ax_rows > 1 then
              -- more rows remain; start new row
              if dma_record.scratchpad_write = '1' then
                if (rem_compl < MAX_AXI_ISSUE-1) then
                  nxt_arvalid <= '1';
                  update_external_start <= '1';
                else
                  nxt_awvalid <= '0';
                  nxt_arvalid <= '0';
                  nxt_ax_state <= S_AX_ADDR_WAIT;
                end if;
              else
                nxt_awvalid <= '1';
                update_external_start <= '1';
              end if;
            else
              -- ax_rows == 1 and ax_row_beats_rem == 0;
              -- no more rows; no more address phases to issue.
              nxt_awvalid <= '0';
              nxt_arvalid <= '0';
              nxt_ax_state <= S_AX_WAIT_COMPL;
            end if;
          end if;
        end if;

      when S_AX_ADDR_WAIT =>
        -- This state only used on AXI reads.
        new_external_start <= ax_saved_ext_start;
        -- wait for rem_compl < MAX_AXI_ISSUE
        if (rem_compl < MAX_AXI_ISSUE) then
          nxt_ax_state <= S_AX_ADDR;
          nxt_arvalid <= '1';
          update_external_start <= '1';
        end if;

      when S_AX_WAIT_COMPL =>
        -- On AXI reads, wait for all read completions.
        -- On AXI writes, wait for write data channel FSM to indicate it has
        -- received all write completions.
        if ((dma_record.scratchpad_write = '1') and (rem_compl = 0)) or
           ((dma_record.scratchpad_write = '0') and (w_state = S_W_IDLE)) then
          nxt_ax_state <= S_AX_IDLE;
          axi_done <= '1';
        end if;

      when others => null;
    end case;
  end process;

  ---------------------------------------------------------------------------
  m_axi_arvalid <= arvalid;
  m_axi_arsize  <= axsize;

  m_axi_awvalid <= awvalid;
  m_axi_awsize  <= axsize;

  -- external AXI address is always aligned to MEMORY_WIDTH_BYTES boundary.
  m_axi_araddr(31 downto BYTE_SEL_W) <=
    dma_record.external_start(31 downto BYTE_SEL_W);
  m_axi_araddr(BYTE_SEL_W-1 downto 0) <= (others => '0');

  m_axi_awaddr(31 downto BYTE_SEL_W) <=
    dma_record.external_start(31 downto BYTE_SEL_W);
  m_axi_awaddr(BYTE_SEL_W-1 downto 0) <= (others => '0');

  -- zero-extend axlen to arlen/awlen
  process (axlen)
    variable padded_axlen : std_logic_vector(7 downto 0);
  begin
    padded_axlen := (others => '0');
    padded_axlen(axlen'range) := axlen;
    m_axi_arlen <= padded_axlen;
    m_axi_awlen <= padded_axlen;
  end process;

  with MEMORY_WIDTH_BYTES select
    axsize <=
    AXI_SIZE_4   when 4,
    AXI_SIZE_8   when 8,
    AXI_SIZE_16  when 16,
    AXI_SIZE_32  when 32,
    AXI_SIZE_64  when 64,
    AXI_SIZE_128 when 128,
    AXI_SIZE_4   when others;

  ---------------------------------------------------------------------------
  -- Track outstanding read and write completions.

  process (clk)
    variable decr_rem_compl : std_logic;
    variable incr_rem_compl : std_logic;
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        rem_compl <= (others => '0');
      else
        decr_rem_compl := decr_rem_compl_wr or decr_rem_compl_rd;
        incr_rem_compl := incr_rem_compl_wr or incr_rem_compl_rd;
        if incr_rem_compl = '1' and decr_rem_compl = '0' then
          assert rem_compl < MAX_AXI_ISSUE
            report "increment when rem_compl = MAX_AXI_ISSUE"
            severity failure;
          if rem_compl < MAX_AXI_ISSUE then
            rem_compl <= rem_compl + 1;
          end if;
        elsif incr_rem_compl = '0' and decr_rem_compl = '1' then
          assert rem_compl > 0 report "decrement when rem_compl = 0"
            severity failure;
          if rem_compl > 0 then
            rem_compl <= rem_compl - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- AXI Write Data Channel: manages FIFO reads.
  --
  -- Reads up to BEATS_PER_BURST words from FIFO and outputs them on wdata.
  --
  -- The Write Data channel is decoupled from the Write Address channel, so
  -- it needs to recompute the number of beats remaining as it performs
  -- burst transactions. It also needs to compute the write strobes for the
  -- first beat of the first burst and the last beat of the last burst
  -- for each row. (A row might also fit in a single beat.)
  --
  -- NOTE: The AXI4 spec says "the write data can appear at an interface
  -- before the write address for the transaction" (A3.3 Relationships
  -- between the channels), so the data phase of a write burst can begin
  -- even if the corresponding address phase hasn't been clocked out yet.
  --
  -- However, AXI4 also explicitly prohibits a slave from providing a
  -- write response before the appropriate write address has been accepted.
  -- AXI3 technically allows a slave to provide a write response before
  -- accepting the write address but the AXI4 spec says this is not the
  -- expected use ("it is not expected that any components would accept
  -- all write data and provide a write response before the address is
  -- accepted").
  --
  -- XXX Could make this FSM control update_external_start on sp reads,
  -- instead of ax_state FSM.

  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        w_state <= S_W_IDLE;
        wvalid <= '0';
        wlast  <= '0';
        wstrb <= (others => '0');
        w_row_beats_rem <= (others => '0');
        w_burst_beats_rem <= (others => '0');
        w_next_row_start <= (others => '0');
        w_next_row_end   <= (others => '0');
        w_next_row_beats_rem <= (others => '0');
        w_addr <= (others => '0');
        w_rows <= (others => '0');
        w_last_be <= (others => '0');
      else
        w_state <= nxt_w_state;
        wvalid <= nxt_wvalid;
        wlast <= nxt_wlast;
        wstrb <= nxt_wstrb;
        w_row_beats_rem <= nxt_w_row_beats_rem;
        w_burst_beats_rem <= nxt_w_burst_beats_rem;
        w_next_row_start <= nxt_w_next_row_start;
        w_next_row_end   <= nxt_w_next_row_end;
        w_next_row_beats_rem <= nxt_w_next_row_beats_rem;
        w_addr <= nxt_w_addr;
        w_rows <= nxt_w_rows;
        w_last_be <= nxt_w_last_be;
      end if;
    end if;
  end process;

  m_axi_wvalid <= wvalid;
  m_axi_wlast <= wlast;
  m_axi_wstrb <= wstrb;

  -- m_axi_wdata is directly driven by the output of the FIFO, fifo_data_out.

  process (w_state, dma_record, fifo_empty,
           m_axi_wready, wvalid, wlast, wstrb,
           dma_write, sp_state, rem_compl,
           w_row_beats_rem, w_burst_beats_rem,
           w_next_row_start, w_next_row_end,
           w_next_row_beats_rem,
           w_addr, w_rows, w_last_be)
    variable w_next_row_start_v : std_logic_vector(31 downto 0);
    variable w_next_row_end_v   : std_logic_vector(31 downto 0);
    variable w_first_be_v : std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);
    variable w_last_be_v : std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);
    variable incr_w_addr_v : std_logic_vector(31 downto 0);
    variable w_burst_beats_rem_v : std_logic_vector(BEATS_PER_BURST_W-1 downto 0);
  begin

    nxt_w_state <= w_state;
    axi_fifo_rd <= '0';

    nxt_wvalid <= wvalid;
    nxt_wlast <= wlast;
    nxt_wstrb <= wstrb;

    nxt_w_row_beats_rem <= w_row_beats_rem;
    nxt_w_burst_beats_rem <= w_burst_beats_rem;
    nxt_w_next_row_start <= w_next_row_start;
    nxt_w_next_row_end   <= w_next_row_end;
    nxt_w_next_row_beats_rem <= w_next_row_beats_rem;
    -- destination address (aligned) of word being written.
    nxt_w_addr <= w_addr;
    nxt_w_rows <= w_rows;
    nxt_w_last_be <= w_last_be;

    incr_w_addr_v := w_addr + MEMORY_WIDTH_BYTES;

    incr_rem_compl_wr <= '0';

    case w_state is
      when S_W_IDLE =>
        if (sp_state = S_SP_IDLE) and (dma_write = '1') then
          nxt_w_state <= S_W_ROW0_START;

          w_next_row_start_v := dma_record.external_start;
          w_next_row_end_v   := row_end(w_next_row_start_v, dma_record.length);
          nxt_w_next_row_start <= w_next_row_start_v;
          nxt_w_next_row_end   <= w_next_row_end_v;
          nxt_w_next_row_beats_rem <= row_beats(w_next_row_start_v,
                                                w_next_row_end_v);

          nxt_w_rows <= dma_record.rows;
        end if;

      when S_W_ROW0_START =>

        nxt_w_addr <= ext_aligned(w_next_row_start);

        w_next_row_start_v := w_next_row_start + dma_record.ext_incr;
        w_next_row_end_v   := row_end(w_next_row_start_v, dma_record.length);
        nxt_w_next_row_start <= w_next_row_start_v;
        nxt_w_next_row_end   <= w_next_row_end_v;
        nxt_w_next_row_beats_rem <= row_beats(w_next_row_start_v,
                                              w_next_row_end_v);

        w_burst_beats_rem_v := beats_minus1(burst_beats(w_next_row_start,
                                                        w_next_row_beats_rem));
        nxt_w_burst_beats_rem <= w_burst_beats_rem_v;
        nxt_w_row_beats_rem <= w_next_row_beats_rem - 1;

        w_first_be_v := first_be(w_next_row_start);
        w_last_be_v  := last_be(w_next_row_end);
        nxt_w_last_be <= w_last_be_v;

        if w_next_row_beats_rem = 1 then
          -- only one beat for row
          nxt_wstrb <= w_first_be_v and w_last_be_v;
        else
          nxt_wstrb <= w_first_be_v;
        end if;

        if w_burst_beats_rem_v = 0 then
          -- only one beat in burst
          nxt_wlast <= '1';
        else
          nxt_wlast <= '0';
        end if;

        if fifo_empty = '0' then
          nxt_w_state <= S_W_XFER;
          axi_fifo_rd <= '1';
          nxt_wvalid <= '1';
        else
          nxt_w_state <= S_W_WAIT;
          nxt_wvalid <= '0';
        end if;

      when S_W_WAIT =>
        -- wait for fifo to become non-empty.
        -- rem_compl check is only needed for start of new burst, but it
        -- does no harm to perform the check within a burst.
        if (fifo_empty = '0') and (rem_compl < MAX_AXI_ISSUE) then
          nxt_w_state <= S_W_XFER;
          axi_fifo_rd <= '1';
          nxt_wvalid <= '1';
        end if;

      when S_W_XFER =>
        if m_axi_wready = '1' then
          if wlast = '1' then
            -- Increment number of outstanding write completions.
            incr_rem_compl_wr <= '1';
            if w_row_beats_rem > 0 then
              -- Last beat of burst (wlast=1), but still more data to
              -- transfer in this row. Immediately start new burst.
              nxt_w_addr <= incr_w_addr_v;
              nxt_w_row_beats_rem <= w_row_beats_rem - 1;
              w_burst_beats_rem_v := beats_minus1(burst_beats(incr_w_addr_v,
                                                              w_row_beats_rem));
              nxt_w_burst_beats_rem <= w_burst_beats_rem_v;

              if w_row_beats_rem = 1 then
                -- only one beat remaining in row;
                -- next burst consists of a single beat.
                nxt_wstrb <= w_last_be;
              else
                nxt_wstrb <= (others => '1');
              end if;

              if w_burst_beats_rem_v = 0 then
                -- only one beat in next burst.
                -- This can only happen at the end of a row (we know that
                -- this is not the first burst in a row), so we could use
                -- the condition (w_row_beats_rem = 1) instead.
                nxt_wlast <= '1';
              else
                nxt_wlast <= '0';
              end if;

              if (fifo_empty = '0') and (rem_compl < MAX_AXI_ISSUE-1) then
                -- MAX_AXI_ISSUE-1 because rem_compl is being incremented
                -- in this cycle.
                nxt_w_state <= S_W_XFER;
                axi_fifo_rd <= '1';
                nxt_wvalid <= '1';
              else
                nxt_w_state <= S_W_WAIT;
                nxt_wvalid <= '0';
              end if;
            else
              -- w_row_beats_rem == 0: last beat in row
              nxt_w_rows <= w_rows - 1;
              if w_rows > 1 then
                -- more rows remain, start new row
                nxt_w_addr <= ext_aligned(w_next_row_start);

                w_next_row_start_v := w_next_row_start + dma_record.ext_incr;
                w_next_row_end_v   := row_end(w_next_row_start_v, dma_record.length);
                nxt_w_next_row_start <= w_next_row_start_v;
                nxt_w_next_row_end   <= w_next_row_end_v;
                nxt_w_next_row_beats_rem <= row_beats(w_next_row_start_v,
                                                      w_next_row_end_v);

                w_burst_beats_rem_v := beats_minus1(burst_beats(w_next_row_start,
                                                                w_next_row_beats_rem));
                nxt_w_burst_beats_rem <= w_burst_beats_rem_v;
                nxt_w_row_beats_rem <= w_next_row_beats_rem - 1;

                w_first_be_v := first_be(w_next_row_start);
                w_last_be_v  := last_be(w_next_row_end);
                nxt_w_last_be <= w_last_be_v;

                if w_next_row_beats_rem = 1 then
                  -- only one beat in next row.
                  nxt_wstrb <= w_first_be_v and w_last_be_v;
                else
                  nxt_wstrb <= w_first_be_v;
                end if;

                if w_burst_beats_rem_v = 0 then
                  -- only one beat in next burst.
                  nxt_wlast <= '1';
                else
                  nxt_wlast <= '0';
                end if;

                if (fifo_empty = '0') and (rem_compl < MAX_AXI_ISSUE-1) then
                  nxt_w_state <= S_W_XFER;
                  axi_fifo_rd <= '1';
                  nxt_wvalid <= '1';
                else
                  nxt_w_state <= S_W_WAIT;
                  nxt_wvalid <= '0';
                end if;
              else
                -- w_rows == 1: end of last row
                nxt_w_state <= S_W_WAIT_COMPL;
                nxt_wvalid <= '0';
                nxt_wlast <= '0';
              end if;
            end if;
          else
            -- !wlast: not the last beat in burst.
            if w_row_beats_rem = 1 then
              -- next beat is last in row (and last in burst).
              nxt_wstrb <= w_last_be;
            else
              nxt_wstrb <= (others => '1');
            end if;
            if w_burst_beats_rem = 1 then
              -- next beat is last in burst
              nxt_wlast <= '1';
            else
              nxt_wlast <= '0';
            end if;
            nxt_w_addr <= incr_w_addr_v;
            nxt_w_row_beats_rem <= w_row_beats_rem - 1;
            nxt_w_burst_beats_rem <= w_burst_beats_rem - 1;

            if fifo_empty = '0' then
              nxt_w_state <= S_W_XFER;
              nxt_wvalid <= '1';
              axi_fifo_rd <= '1';
            else
              nxt_w_state <= S_W_WAIT;
              nxt_wvalid <= '0';
            end if; -- fifo_empty
          end if; -- wlast
        end if; -- wready

      when S_W_WAIT_COMPL =>
        if rem_compl = 0 then
          nxt_w_state <= S_W_IDLE;
        end if;

      when others => null;
    end case;
  end process;


  ---------------------------------------------------------------------------
  -- Write Response Channel

  m_axi_bready  <= bready;

  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        b_state <= S_B_IDLE;
        bready <= '0';
      else
        b_state <= nxt_b_state;
        bready <= nxt_bready;
      end if;
    end if;
  end process;

  process (b_state, bready, m_axi_bvalid, dma_write, rem_compl,
           incr_rem_compl_wr)
  begin

    nxt_b_state <= b_state;
    nxt_bready <= bready;

    decr_rem_compl_wr <= '0';

    case b_state is
      when S_B_IDLE =>
        if (dma_write = '1') and (incr_rem_compl_wr = '1') then
          nxt_b_state <= S_B_WAIT;
          nxt_bready <= '1';
        end if;
      when S_B_WAIT =>
        if m_axi_bvalid = '1' then
          decr_rem_compl_wr <= '1';
          if (rem_compl = 1) and (incr_rem_compl_wr = '0') then
            nxt_b_state <= S_B_IDLE;
            nxt_bready <= '0';
          end if;
        end if;
      when others => null;
    end case;
  end process;

  ---------------------------------------------------------------------------
  -- AXI Read Data Channel: writes to the FIFO on DMA reads.

  m_axi_rready  <= rready;

  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        r_state <= S_R_IDLE;
        rready <= '0';
      else
        r_state <= nxt_r_state;
        rready <= nxt_rready;
      end if;
    end if;
  end process;

  process (r_state, rready, m_axi_rvalid, m_axi_rlast,
           dma_read, rem_compl, fifo_full, fifo_level)
  begin

    nxt_r_state <= r_state;
    nxt_rready <= rready;

    axi_fifo_wr <= '0';
    decr_rem_compl_rd <= '0';

    case r_state is
      when S_R_IDLE =>
        if (dma_read = '1') and (rem_compl > 0) then
          if fifo_full = '1' then
            nxt_r_state <= S_R_WAIT;
            nxt_rready <= '0';
          else
            nxt_r_state <= S_R_XFER;
            nxt_rready <= '1';
          end if;
        end if;

      when S_R_WAIT =>
        if fifo_full = '0' then
          nxt_r_state <= S_R_XFER;
          nxt_rready <= '1';
        end if;

      when S_R_XFER =>
        if m_axi_rvalid = '1' then
          axi_fifo_wr <= '1';
          if m_axi_rlast = '1' then
            decr_rem_compl_rd <= '1';
            if rem_compl > 1 then
              -- accept data from back-to-back bursts without wait states
              if fifo_full = '1' then
                nxt_r_state <= S_R_WAIT;
                nxt_rready <= '0';
              else
                nxt_rready <= '1';
              end if;
            else
              nxt_r_state <= S_R_IDLE;
              nxt_rready <= '0';
            end if;
          else
            -- !rlast
            if fifo_level < FIFO_DEPTH-1 then
              nxt_rready <= '1';
            else
              nxt_r_state <= S_R_WAIT;
              nxt_rready <= '0';
            end if;
          end if;
        end if;

      when others => null;
    end case;
  end process;

  ---------------------------------------------------------------------------
  -- Extract lowest MEMORY_WIDTH_LANES*32 bits of read data out of the
  -- VECTOR_LANES*(32+4)-bit-wide readdata slv.
  process (readdata)
    variable i : integer;
    variable spbyte_array : scratchpad_data(VECTOR_LANES*4-1 downto 0);
    variable word32_array : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  begin
    -- convert readdata slv to array of byte+flag records,
    -- convert to array of VECTOR_LANES 32-bit words,
    -- then select MEMORY_WIDTH_LANES 32-bit words.
    spbyte_array := byte9_to_scratchpad_data(readdata);
    word32_array := scratchpad_data_to_word32_scratchpad_data(spbyte_array);
    for i in 0 to MEMORY_WIDTH_LANES-1 loop
      sp_data_out(32*(i+1)-1 downto 32*i) <= word32_array(i);
    end loop;
  end process;

  ---------------------------------------------------------------------------
  process (axi_fifo_rd, axi_fifo_wr, m_axi_rdata,
           sp_fifo_rd, sp_fifo_wr, sp_data_out, dma_read)
  begin

    if dma_read = '1' then
      fifo_rd <= sp_fifo_rd;
      fifo_wr <= axi_fifo_wr;
      fifo_data_in <= m_axi_rdata;
    else
      fifo_rd <= axi_fifo_rd;
      fifo_wr <= sp_fifo_wr;
      fifo_data_in <= sp_data_out;
    end if;
  end process;

  m_axi_wdata <= fifo_data_out;

  -- Only lower MEMORY_WIDTH_BYTES of sp_writedata need to contain valid data.
  -- Byte enables determine which lanes contain valid data.
  sp_writedata(MEMORY_WIDTH_BYTES-1 downto 0) <=
    byte8_to_scratchpad_data(fifo_data_out, MEMORY_WIDTH_LANES);

  gen_upper_sp_writedata : if VECTOR_MEMORY_WIDTHS > 1 generate
    sp_writedata(VECTOR_LANES*4-1 downto MEMORY_WIDTH_BYTES) <=
      (others => (data => (others => '0'), flag => '0'));
  end generate gen_upper_sp_writedata;

  ---------------------------------------------------------------------------
  -- Behavioural dual-port RAM model for FIFO.
  -- One write port, one read port.

  -- Single process for both ports (works with XST, but not Vivado Synthesis):
  --
  --process (clk)
  --begin
  --  if clk'event and clk = '1' then
  --    if fifo_wr = '1' then
  --      fifo(conv_integer(wr_ptr)) <= fifo_data_in;
  --    end if;
  --    if fifo_rd = '1' and fifo_empty = '0' then
  --      fifo_data_out <= fifo(conv_integer(rd_ptr));
  --    end if;
  --  end if;
  --end process;

  -- Separate processes for each port.

  -- Write port
  process (clk)
  begin
    if clk'event and clk = '1' then
      if fifo_wr = '1' then
        fifo(conv_integer(wr_ptr)) := fifo_data_in;
      end if;
      if fifo_rd = '1' and fifo_empty = '0' then
        rd_ptr_reg <= rd_ptr;
      end if;
    end if;
  end process;
  fifo_data_out <= fifo(conv_integer(rd_ptr_reg));  

  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        wr_ptr <= (others => '0');
        rd_ptr <= (others => '0');
        fifo_level <= (others => '0');
      else
        -- can write to a full fifo if there is a read at the same time
        if (fifo_wr = '1' and fifo_full = '0') or
           (fifo_wr = '1' and fifo_rd = '1' and fifo_full = '1') then
          wr_ptr <= wr_ptr + 1;
        end if;

        if fifo_rd = '1' and fifo_empty = '0' then
          rd_ptr <= rd_ptr + 1;
        end if;

        if fifo_wr = '1' and not (fifo_rd = '1' and fifo_empty = '0')
          and fifo_full = '0' then
          fifo_level <= fifo_level + 1;
        elsif fifo_rd = '1' and fifo_wr = '0' and fifo_empty = '0' then
          fifo_level <= fifo_level - 1;
        end if;

        assert not (fifo_wr = '1' and fifo_full = '1') report
          "FIFO write while FIFO full!" severity failure;
        assert not (fifo_rd = '1' and fifo_empty = '1') report
          "FIFO read while FIFO empty!" severity failure;
      end if;
    end if;
  end process;

  process (fifo_level)
  begin

    if fifo_level = std_logic_vector(to_unsigned(0, FIFO_AW+1)) then
      fifo_empty <= '1';
    else
      fifo_empty <= '0';
    end if;

    if fifo_level = std_logic_vector(to_unsigned(FIFO_DEPTH, FIFO_AW+1)) then
      fifo_full <= '1';
    else
      fifo_full <= '0';
    end if;

  end process;

  ---------------------------------------------------------------------------
  -- Burst cannot cross 4KB boundary.
  assert BEATS_PER_BURST <= 256 report "BEATS_PER_BURST (" &
    integer'image(BEATS_PER_BURST) & ") is greater than 256."
    severity failure;

  -- std_logic_vector(log2(BEATS_PER_BURST)-1 downto 0) is used to represent
  -- burst lengths in beats, so it is assumed that log2(BEATS_PER_BURST) >= 1.
  -- Similarly, the burst_beats_m1 function assumes BURSTLENGTH_BYTES is greater
  -- (and not equal to) MEMORY_WIDTH_BYTES.
  -- Could probably work around this if necessary by adding special case for
  -- BEATS_PER_BURST=1 (BURSTLENGTH_BYTES=MEMORY_WIDTH_BYTES).
  assert BEATS_PER_BURST > 1 report "BEATS_PER_BURST (" &
    integer'image(BEATS_PER_BURST) & ") is less than 2."
    severity failure;

  -- Memory-width should not exceed 2KB.
  -- (AXI burst_beats_m1 function assumes there are at least 2 beats per
  -- 4KB page.)
  assert MEMORY_WIDTH_BYTES <= 2048 report "MEMORY_WIDTH_BYTES (" &
    integer'image(MEMORY_WIDTH_BYTES) & ") is greater than 2048."
    severity failure;

end architecture rtl;
