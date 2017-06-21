-- axi_instr_slave.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.
--
-- AXI4 Slave for Instruction Port

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

entity axi_instr_slave is
  generic (
    C_S_AXI_DATA_WIDTH : integer := 32;
    C_S_AXI_ADDR_WIDTH : integer := 32;
    C_S_AXI_ID_WIDTH   : integer := 4
    );
  port (
    clk                : in  std_logic;
    reset              : in  std_logic;

    s_axi_awaddr       : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_awvalid      : in  std_logic;
    s_axi_awready      : out std_logic;
    s_axi_awid         : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    s_axi_awlen        : in  std_logic_vector(7 downto 0);
    s_axi_awsize       : in  std_logic_vector(2 downto 0);
    s_axi_awburst      : in  std_logic_vector(1 downto 0);

    s_axi_wdata        : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_wstrb        : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    s_axi_wvalid       : in  std_logic;
    s_axi_wlast        : in  std_logic;
    s_axi_wready       : out std_logic;

    s_axi_bready       : in  std_logic;
    s_axi_bresp        : out std_logic_vector(1 downto 0);
    s_axi_bvalid       : out std_logic;
    s_axi_bid          : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);

    s_axi_araddr       : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_arvalid      : in  std_logic;
    s_axi_arready      : out std_logic;
    s_axi_arid         : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    s_axi_arlen        : in  std_logic_vector(7 downto 0);
    s_axi_arsize       : in  std_logic_vector(2 downto 0);
    s_axi_arburst      : in  std_logic_vector(1 downto 0);

    s_axi_rready       : in  std_logic;
    s_axi_rdata        : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_rresp        : out std_logic_vector(1 downto 0);
    s_axi_rvalid       : out std_logic;
    s_axi_rlast        : out std_logic;
    s_axi_rid          : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);

    -- Interface to FSL handler
    fsl_s_read         : out std_logic;
    fsl_s_data         : in  std_logic_vector(0 to 31);
    fsl_s_exists       : in  std_logic;

    fsl_m_write        : out std_logic;
    fsl_m_data         : out std_logic_vector(0 to 31);
    fsl_m_full         : in  std_logic

    );
end entity axi_instr_slave;

---------------------------------------------------------------------------
-- Converts AXI slave writes to FSL writes and AXI reads to FSL reads.
-- The AXI read and write addresses are ignored; any read/write in the
-- slave's assigned address range will be converted to an FSL read/write.
-- Bursts are supported; AXI wait states are determined by FSL wait states.
--
-- Burst writes are supported, provided the write strobes are either all
-- asserted or all de-asserted in each beat of the burst. (The Cortex-A9's
-- write buffer can do write bursts with the write strobes all deasserted
-- in any beat. The FSL interface expects full word writes, so beats that
-- contain valid data must have all write strobes asserted.)
--
-- Burst reads will only perform a single FSL read and return the same data
-- on all beats. This behaviour is to support the 64-bit-aligned 2-beat
-- 32-bit-wide burst reads that appear on the Zynq PS7 M_AXI_GPx interface
-- when the Cortex-A9 performs a load from a normal non-cacheable address.
--
-- Note that for FSL reads, the reader is conceptually the slave on a
-- unidirectional FSL link, and fsl_s_read is not supposed to be asserted
-- unless fsl_s_exists is asserted.
--
-- The read and write channels are decoupled to allow the store and load
-- instructions in a GET_PARAM/SYNC sequence to work without Data Memory
-- Barriers in the ARM instruction stream.
-- * A GET_PARAM or SYNC operation consists of a store followed by a load.
-- * If the load is issued before the store, the read channel will block
--   (waiting for fsl_s_exists to be asserted), but if the write channel
--   is decoupled from the read channel, it will be able to accept the store
--   containing the first MXP instruction word. The fsl_handler will respond
--   to the GET_PARAM/SYNC by placing a word on fsl_s_data and asserting
--   fsl_s_exists, which will allow the read channel to assert rvalid.
-- * If a subsequent store is issued before the load (but after the store
--   of the GET_PARAM/SYNC instruction word), the fsl_handler will have
--   asserted fsl_s_exists and will be waiting for the read channel to
--   assert fsl_s_read. The fsl_handler will also be asserting fsl_m_full
--   to prevent further instructions from being written until the data is
--   read. The write channel will therefore block until a read occurs on
--   the read channel.
-- * Similarly, a store issued after the load of a SYNC sequence will block
--   until the SYNC completes and a word is read from the read channel.
--
-- Most of this module's outputs are combinational, and most of the inputs
-- are not flopped before use.
--
-- fsl_m_write = func of (wvalid, wstrb, fsl_m_full, w_state, rem_wr_compl)
-- awready = func of (awvalid, w_state, rem_wr_compl)
-- wready = func of (wvalid, fsl_m_full, w_state, awvalid, rem_wr_compl)
-- bvalid = func of (b_state, rem_wr_compl)
-- bresp = func of (b_state, werr_fifo, rem_wr_compl)
-- bid = func of (bid_fifo, rem_wr_compl)
--
-- arready = func of (arvalid, r_state)
-- rvalid = func of (fsl_s_exists, r_state)
-- rlast  = func of (fsl_s_exists, alen, r_state)
-- fsl_s_read = func of (fsl_s_exists, rready, alen, r_state)
-- rid = registered output
--
-- arburst/awburst, arsize/awsize are ignored;
-- axsize is expected to be 3'b010 (4 bytes).
-- wstrb is expected to be either all high or all low; if not, bresp=SLVERR
-- will be returned.
---------------------------------------------------------------------------

architecture rtl of axi_instr_slave is

  constant AXI_WSTRB_ALL_HIGH :
    std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0) := (others => '1');
  constant AXI_WSTRB_ALL_LOW :
    std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0) := (others => '0');

  constant AXI_RESP_OKAY   : std_logic_vector(1 downto 0) := "00";
  constant AXI_RESP_SLVERR : std_logic_vector(1 downto 0) := "10";

  type r_state_type is (S_R_IDLE, S_WAIT_READ);
  signal r_state, nxt_r_state : r_state_type;

  type w_state_type is (S_W_IDLE, S_WAIT_WLAST);
  signal w_state, nxt_w_state : w_state_type;

  type b_state_type is (S_B_IDLE, S_WAIT_BREADY);
  signal b_state, nxt_b_state : b_state_type;

  signal alen, nxt_alen : std_logic_vector(7 downto 0);

  -- transaction ID storage (awid/arid must be returned in bid/rid).
  signal rid, nxt_rid : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);

  signal saved_werr, nxt_saved_werr : std_logic;
  signal last_werr : std_logic;

  constant MAX_WR_COMPL : integer := 2;
  signal rem_wr_compl : std_logic_vector(log2(MAX_WR_COMPL+1)-1 downto 0);
  signal incr_wr_compl : std_logic;
  signal decr_wr_compl : std_logic;

  signal push_awid : std_logic;

  -- write response channel fifos
  type bid_fifo_type is array (MAX_WR_COMPL-1 downto 0) of
    std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
  signal bid_fifo : bid_fifo_type;

  signal werr_fifo : std_logic_vector(MAX_WR_COMPL-1 downto 0);

  signal bid_fifo_out : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
  signal werr_fifo_out : std_logic;

begin

  s_axi_rresp <= AXI_RESP_OKAY;

  fsl_m_data  <= s_axi_wdata;
  s_axi_rdata <= fsl_s_data;

  s_axi_rid <= rid;

  ---------------------------------------------------------------------------
  -- Write channel FSM
  --
  -- Write Address and Write Data channels are not decoupled.
  -- Only one write transaction is handled at time.
  -- However, back-to-back write transactions are supported without wait states
  -- by decoupling the write response channel FSM from the write address/data
  -- channel. (There will be no wait states as long as the master does not
  -- insert wait states of its own by deasserting awvalid/wvalid/bready.)
  --
  -- On Zynq, when the instruction port is connected to an M_AXI_GPx port and
  -- assigned to shareable device memory, instruction word writes appear as
  -- single-beat writes with awvalid and wvalid typically asserted in the same
  -- cycle. When NEON vector store intructions (vst) are used, the instruction
  -- word writes appear as two-beat writes.
  -- In order to support back-to-back transfers without wait states, the write
  -- completions (in write response channel) are pipelined and handled by a
  -- different FSM.
  ---------------------------------------------------------------------------
  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        w_state <= S_W_IDLE;
        saved_werr <= '0';
      else
        w_state <= nxt_w_state;
        saved_werr <= nxt_saved_werr;
      end if;
    end if;
  end process;

  process (w_state, s_axi_awvalid, s_axi_wvalid, s_axi_wlast,
           s_axi_wstrb, fsl_m_full, saved_werr, rem_wr_compl)
  begin
    s_axi_awready <= '0';
    s_axi_wready  <= '0';

    fsl_m_write <= '0';

    nxt_w_state <= w_state;
    nxt_saved_werr <= saved_werr;
    last_werr <= '0';

    incr_wr_compl <= '0';
    push_awid <= '0';

    case w_state is
      when S_W_IDLE =>
        if s_axi_awvalid = '1' then
          if rem_wr_compl < MAX_WR_COMPL then
            -- Only accept the address if there is room in the write response
            -- fifo.
            s_axi_awready <= '1';
            push_awid <= '1';
            if s_axi_wvalid = '1' then
              if s_axi_wstrb = AXI_WSTRB_ALL_HIGH then
                if fsl_m_full = '0' then
                  fsl_m_write <= '1';
                  s_axi_wready <= '1';
                  if s_axi_wlast = '1' then
                    nxt_w_state <= S_W_IDLE;
                    incr_wr_compl <= '1';
                    nxt_saved_werr <= '0';
                  else
                    nxt_w_state <= S_WAIT_WLAST;
                  end if;
                else
                  -- fsl_m_full
                  nxt_w_state <= S_WAIT_WLAST;
                end if;
              else
                -- wstrb /= ALL_HIGH; assert wready but don't write data to FSL.
                s_axi_wready <= '1';
                if s_axi_wlast = '1' then
                  nxt_w_state <= S_W_IDLE;
                  incr_wr_compl <= '1';
                  nxt_saved_werr <= '0';
                  -- If write strobes are neither all high or all low,
                  -- report an error.
                  if (s_axi_wstrb /= AXI_WSTRB_ALL_LOW) or (saved_werr = '1') then
                    last_werr <= '1';
                  end if;
                else
                  nxt_w_state <= S_WAIT_WLAST;
                  if s_axi_wstrb /= AXI_WSTRB_ALL_LOW then
                    nxt_saved_werr <= '1';
                  end if;
                end if;
              end if; -- wstrb /= ALL_HIGH
            else
              -- !wvalid
              nxt_w_state <= S_WAIT_WLAST;
            end if;
          end if; -- rem_wr_compl < MAX_WR_COMPL
        end if; -- awvalid=1

      when S_WAIT_WLAST =>
        if s_axi_wvalid = '1' then
          if s_axi_wstrb = AXI_WSTRB_ALL_HIGH then
            if fsl_m_full = '0' then
              fsl_m_write <= '1';
              s_axi_wready <= '1';
              if s_axi_wlast = '1' then
                nxt_w_state <= S_W_IDLE;
                incr_wr_compl <= '1';
                nxt_saved_werr <= '0';
              end if;
            end if;
          else -- wstrb /= ALL_HIGH
            s_axi_wready <= '1';
            if s_axi_wlast = '1' then
              nxt_w_state <= S_W_IDLE;
              incr_wr_compl <= '1';
              nxt_saved_werr <= '0';
              if (s_axi_wstrb /= AXI_WSTRB_ALL_LOW) or (saved_werr = '1') then
                last_werr <= '1';
              end if;
            else
              -- !wlast
              if s_axi_wstrb /= AXI_WSTRB_ALL_LOW then
                nxt_saved_werr <= '1';
              end if;
            end if;
          end if; -- wstrb /= ALL_HIGH
        end if;

      when others => null;
    end case;
  end process;

  ---------------------------------------------------------------------------
  -- Write Response channel
  ---------------------------------------------------------------------------

  -- Output from BID fifo.
  s_axi_bid <= bid_fifo_out;

  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        b_state <= S_B_IDLE;
      else
        b_state <= nxt_b_state;
      end if;
    end if;
  end process;

  process (b_state, s_axi_bready, werr_fifo_out, rem_wr_compl)
  begin
    s_axi_bvalid  <= '0';
    s_axi_bresp   <= AXI_RESP_OKAY;

    nxt_b_state <= b_state;

    decr_wr_compl <= '0';

    case b_state is

      when S_B_IDLE =>
        if rem_wr_compl > 0 then
          s_axi_bvalid <= '1';
          if werr_fifo_out = '1' then
            s_axi_bresp <= AXI_RESP_SLVERR;
          end if;
          if s_axi_bready = '1' then
            decr_wr_compl <= '1';
          else
            nxt_b_state <= S_WAIT_BREADY;
          end if;
        end if;

      when S_WAIT_BREADY =>
        s_axi_bvalid <= '1';
        if werr_fifo_out = '1' then
          s_axi_bresp <= AXI_RESP_SLVERR;
        end if;
        if s_axi_bready = '1' then
          decr_wr_compl <= '1';
          nxt_b_state <= S_B_IDLE;
        end if;

      when others => null;
    end case;
  end process;

  ---------------------------------------------------------------------------
  -- Track outstanding write completions.

  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        rem_wr_compl <= (others => '0');
      else
        if incr_wr_compl = '1' and decr_wr_compl = '0' then
          assert rem_wr_compl < MAX_WR_COMPL
            report "increment when rem_wr_compl = MAX_WR_COMPL"
            severity failure;
          if rem_wr_compl < MAX_WR_COMPL then
            rem_wr_compl <= rem_wr_compl + 1;
          end if;
        elsif incr_wr_compl = '0' and decr_wr_compl = '1' then
          assert rem_wr_compl > 0 report "decrement when rem_wr_compl = 0"
            severity failure;
          if rem_wr_compl > 0 then
            rem_wr_compl <= rem_wr_compl - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- push into write response fifos
  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        bid_fifo <= (others => (others => '0'));
        werr_fifo <= (others => '0');
      else
        if incr_wr_compl = '1' then
          werr_fifo <= werr_fifo(MAX_WR_COMPL-2 downto 0) & last_werr;
        end if;
        if push_awid = '1' then
          bid_fifo <= bid_fifo(MAX_WR_COMPL-2 downto 0) & s_axi_awid;
        end if;
      end if;
    end if;
  end process;

  -- combinationally mux out fifo head based on fifo level
  process (rem_wr_compl, bid_fifo, werr_fifo)
    variable i : integer;
  begin
    if rem_wr_compl > 0 then
      i := conv_integer(rem_wr_compl) - 1;
      bid_fifo_out <= bid_fifo(i);
      werr_fifo_out <= werr_fifo(i);
    else
      bid_fifo_out <= bid_fifo(0);
      werr_fifo_out <= werr_fifo(0);
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Read channel FSM
  --
  -- Each AXI read transaction, even if it is a burst (arlen > 0), causes one
  -- FSL read to be performed. In the case of a burst, the same data is
  -- returned on every beat. There is no support for read pipelining.
  ---------------------------------------------------------------------------
  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        r_state <= S_R_IDLE;
        alen <= (others => '0');
        rid <= (others => '0');
      else
        r_state <= nxt_r_state;
        alen <= nxt_alen;
        rid <= nxt_rid;
      end if;
    end if;
  end process;

  process (r_state, alen, s_axi_arvalid, s_axi_arlen, s_axi_arid, s_axi_rready,
           fsl_s_exists, rid)
  begin
    s_axi_arready <= '0';
    s_axi_rvalid  <= '0';
    s_axi_rlast   <= '0';

    fsl_s_read <= '0';

    nxt_r_state <= r_state;
    nxt_alen <= alen;
    nxt_rid <= rid;

    case r_state is
      when S_R_IDLE =>
        if s_axi_arvalid = '1' then
          s_axi_arready <= '1';
          -- must latch read burst length because rlast has to be asserted
          -- on the last beat of the burst.
          nxt_alen <= s_axi_arlen;
          nxt_rid <= s_axi_arid;
          nxt_r_state <= S_WAIT_READ;
        end if;

      when S_WAIT_READ =>
        -- From AXI spec, "Read transaction dependencies":
        -- "the slave must not wait for the master to assert RREADY before
        -- asserting RVALID."
        if fsl_s_exists = '1' then
          s_axi_rvalid <= '1';
          if alen = 0 then
            s_axi_rlast <= '1';
          end if;
          if s_axi_rready = '1' then
            if alen = 0 then
              -- Only assert fsl_s_read in last beat, so the same data is
              -- returned in all beats.
              fsl_s_read <= '1';
              nxt_r_state <= S_R_IDLE;
            else
              nxt_alen <= alen - 1;
            end if;
          end if;
        end if;

      when others => null;
    end case;
  end process;

---------------------------------------------------------------------------
  assert C_S_AXI_DATA_WIDTH = 32 report "C_S_AXI_DATA_WIDTH (" &
    integer'image(C_S_AXI_DATA_WIDTH) & ") != 32."
    severity failure;

end architecture rtl;
