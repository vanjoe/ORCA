-- axi4lite_sp_slave.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.
--
-- AXI4-Lite Slave for accessing scratchpad memory.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;
use work.architecture_pkg.all;

entity axi4lite_sp_slave is
  generic (
    VECTOR_LANES       : integer := 1;
    ADDR_WIDTH         : integer := 1;
    -- If set to true, mux/demux of scratchpad-width read/write data is
    -- assumed to be done outside this block (in the scratchpad_arbiter);
    -- read and write data (and byte enables) are assumed to only use the
    -- least significant bits of the busses from/to the arbiter.
    EXT_ALIGN          : boolean := false;
    -- XPS AXI4-Lite slave generics
    -- This block requires
    -- C_S_AXI_DATA_WIDTH = 32
    -- C_S_AXI_ADDR_WIDTH >= ADDR_WIDTH
    C_S_AXI_DATA_WIDTH : integer := 32;
    C_S_AXI_ADDR_WIDTH : integer := 32
    );
  port (
    clk                : in  std_logic;
    reset              : in  std_logic;

    S_AXI_AWADDR       : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWVALID      : in  std_logic;
    S_AXI_AWREADY      : out std_logic;

    S_AXI_WDATA        : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB        : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID       : in  std_logic;
    S_AXI_WREADY       : out std_logic;

    S_AXI_BREADY       : in  std_logic;
    S_AXI_BRESP        : out std_logic_vector(1 downto 0);
    S_AXI_BVALID       : out std_logic;

    S_AXI_ARADDR       : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID      : in  std_logic;
    S_AXI_ARREADY      : out std_logic;

    S_AXI_RREADY       : in  std_logic;
    S_AXI_RDATA        : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP        : out std_logic_vector(1 downto 0);
    S_AXI_RVALID       : out std_logic;

    slave_request_out  : in  std_logic_vector(scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    slave_request_in   : out std_logic_vector(scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0)

    );
end entity axi4lite_sp_slave;

---------------------------------------------------------------------------
-- The scratchpad request interface is essentially an Avalon-MM interface,
-- which differs from AXI in a few important ways.
--
-- Avalon-MM characteristics:
-- * Write data must be valid when write is asserted.
-- * The master cannot insert wait states on reads. It must accept
--   read data from the slave as soon as it is available.
-- * The slave can insert wait states by asserting waitrequest.
--
-- AXI characteristics:
-- * The write address and write data channels are decoupled;
--   write data is not necessarily valid (wvalid=1) when the write
--   transaction begins on the write address channel (awvalid=1).
-- * The master can insert wait states on reads and writes by keeping
--   rready or wvalid deasserted.
--
-- Because of possible master-inserted wait states, support for fully
-- pipelined reads (which the Avalon slave has) would require the
-- addition of buffering to store read data from all reads that have
-- already been issued into the scratchpad "read pipeline" at the time
-- rready is deasserted. The maximum number of reads in-flight
-- is roughly equal to the scratchpad read latency, so we would need
-- to be able to buffer that many words.
--
-- An Avalon-MM master cannot insert wait states, so this buffering is
-- not necessary in an Avalon slave.
--
-- Since the scratchpad interface is not required to provide high
-- performance, this AXI slave does NOT support transaction pipelining.
--
-- It is unlikely that the CPU will pipeline uncached reads and writes
-- anyway. The DMA engine should be used for all high throughput data
-- transfers.
--
-- Each write will take at least two cycles (from AWREADY=1 to BVALID=1),
-- and each read will take at least SCRATCHPAD_READ_DELAY+2 cycles
-- (from ARREADY=1 to RVALID=1).
--
-- Even without support for read transaction pipelining, we still need
-- to be able to buffer one word of data in case the master is not
-- ready to accept the data (RREADY=0) when it is produced by the scratchpad.
--
-- NOTE: In order to achieve latencies comparable to those of the Avalon
-- slave (in the unpipelined case), all AXI and scratchpad outputs are
-- combinational.
---------------------------------------------------------------------------

architecture rtl of axi4lite_sp_slave is

  signal rd                  : std_logic;
  signal wr                  : std_logic;
  signal addr                : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal writedata           : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal byteena             : std_logic_vector((VECTOR_LANES*4)-1 downto 0);

  signal waitrequest         : std_logic;
  signal readdatavalid       : std_logic;
  signal readdata            : std_logic_vector((VECTOR_LANES*4*9)-1 downto 0);
  signal readdata_addr       : std_logic_vector(ADDR_WIDTH-1 downto 0);

  constant VL_WIDTH          : integer := log2(VECTOR_LANES);
  constant AXI_RESP_OKAY     : std_logic_vector(1 downto 0) := "00";

  type state_type is (S_IDLE, S_WAIT_BREADY, S_WAIT_READ1, S_WAIT_READ2);
  signal state, nxt_state    : state_type;

  signal sp_word             : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal sp_word_latched     : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal nxt_sp_word_latched : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

begin

  S_AXI_RRESP <= AXI_RESP_OKAY;
  S_AXI_BRESP <= AXI_RESP_OKAY;

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then
      if reset = '1' then
        state <= S_IDLE;
        sp_word_latched <= (others => '0');
      else
        state <= nxt_state;
        sp_word_latched <= nxt_sp_word_latched;
      end if;
    end if;
  end process;

  process (state, waitrequest, readdatavalid,
           S_AXI_AWVALID, S_AXI_WVALID,
           S_AXI_AWADDR, S_AXI_ARADDR, S_AXI_ARVALID,
           S_AXI_BREADY, S_AXI_RREADY,
           sp_word, sp_word_latched)
  begin  -- process
    wr <= '0';
    rd <= '0';
    -- Lower 2 bits must be zeroed out because AXI address might not be
    -- aligned to 32-bit boundary for byte and halfword accesses.
    -- (Especially important when EXT_ALIGN=true because an unaligned
    -- address would cause the alignment network to do a shift.)
    addr <= S_AXI_ARADDR(ADDR_WIDTH-1 downto 2) & "00";
    S_AXI_AWREADY <= '0';
    S_AXI_WREADY <= '0';
    S_AXI_ARREADY <= '0';
    S_AXI_BVALID <= '0';
    S_AXI_RVALID <= '0';
    S_AXI_RDATA <= sp_word;
    nxt_state <= state;
    nxt_sp_word_latched <= sp_word_latched;

    case state is
      when S_IDLE =>
        if S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' then
          wr   <= '1';
          addr <= S_AXI_AWADDR(ADDR_WIDTH-1 downto 2) & "00";
          if waitrequest = '0' then
            S_AXI_AWREADY <= '1';
            S_AXI_WREADY  <= '1';
            nxt_state <= S_WAIT_BREADY;
          end if;
        elsif S_AXI_ARVALID = '1' then
          rd   <= '1';
          addr <= S_AXI_ARADDR(ADDR_WIDTH-1 downto 2) & "00";
          if waitrequest = '0' then
            S_AXI_ARREADY <= '1';
            nxt_state <= S_WAIT_READ1;
          end if;
        end if;

      when S_WAIT_BREADY =>
        S_AXI_BVALID <= '1';
        if S_AXI_BREADY = '1' then
          nxt_state <= S_IDLE;
        end if;

      when S_WAIT_READ1 =>
        -- wait for readdatavalid to be asserted.
        -- sp_word is passed through combinationally to RDATA.
        S_AXI_RDATA <= sp_word;
        if readdatavalid = '1' then
          S_AXI_RVALID <= '1';
          if S_AXI_RREADY = '1' then
            nxt_state <= S_IDLE;
          else
            -- AXI master isn't ready; have to latch sp_word.
            nxt_state <= S_WAIT_READ2;
            nxt_sp_word_latched <= sp_word;
          end if;
        end if;

      when S_WAIT_READ2 =>
        -- output latched data while waiting
        S_AXI_RVALID <= '1';
        S_AXI_RDATA <= sp_word_latched;
        if S_AXI_RREADY = '1' then
          nxt_state <= S_IDLE;
        end if;

      when others => null;
    end case;
  end process;

  -- put write data in appropriate scratchpad lane
  process (S_AXI_WDATA)
    variable writedata_v : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  begin
    if EXT_ALIGN = true then
      -- put 32-bit write data in byte lanes 3:0, zeroes everywhere else.
      writedata_v := (others => (data => (others => '0'),
                                 flag => '0'));
      writedata_v(3 downto 0) := byte8_to_scratchpad_data(S_AXI_WDATA, 1);
      writedata <= writedata_v;
    else
      -- replicate 32-bit write data across all scratchpad lanes
      writedata <= byte8_to_scratchpad_data(S_AXI_WDATA, VECTOR_LANES);
    end if;
  end process;

  -- steer byte enables to appropriate lane.
  process (S_AXI_WSTRB, S_AXI_AWADDR)
    variable ben : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    variable lane : integer;
  begin
    if VECTOR_LANES = 1 then
      lane := 0;
    else
      lane := to_integer(unsigned(S_AXI_AWADDR(2+VL_WIDTH-1 downto 2)));
    end if;
    ben  := (others => '0');
    if EXT_ALIGN = true then
      ben(3 downto 0) := S_AXI_WSTRB;
    else
      ben(4*lane+3 downto 4*lane) := S_AXI_WSTRB;
    end if;
    byteena <= ben;
  end process;

  -- pack fields into slave_request_in.
  slave_request_in <= scratchpad_request_in_flatten(rd, wr, addr,
                                                    writedata, byteena);

  -- unpack fields from slave_request_out.

  -- waitrequest is a combinational function of rd and wr and other
  -- requests to the scratchpad_arbiter. It is 1 when rd and wr are both 0.
  waitrequest   <= scratchpad_request_out_get(slave_request_out,
                                              REQUEST_OUT_WAITREQUEST,
                                              VECTOR_LANES,
                                              ADDR_WIDTH)(0);
  readdatavalid <= scratchpad_request_out_get(slave_request_out,
                                              REQUEST_OUT_READDATAVALID,
                                              VECTOR_LANES,
                                              ADDR_WIDTH)(0);
  -- 4*9 bits per vector lane.
  readdata      <= scratchpad_request_out_get(slave_request_out,
                                              REQUEST_OUT_READDATA,
                                              VECTOR_LANES,
                                              ADDR_WIDTH);
  readdata_addr <= scratchpad_request_out_get(slave_request_out,
                                              REQUEST_OUT_READDATA_ADDR,
                                              VECTOR_LANES,
                                              ADDR_WIDTH);

  -- mux to select read data from correct scratchpad lane.
  process (readdata, readdata_addr)
    variable lane : integer;
    variable spbyte_array : scratchpad_data(VECTOR_LANES*4-1 downto 0);
    variable word_array : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  begin
    if VECTOR_LANES = 1 then
      lane := 0;
    else
      lane := to_integer(unsigned(readdata_addr(2+VL_WIDTH-1 downto 2)));
    end if;
    -- convert readdata slv to array of byte+flag records,
    -- convert to array of VECTOR_LANES words, then select word lane.
    spbyte_array := byte9_to_scratchpad_data(readdata);
    word_array   := scratchpad_data_to_word32_scratchpad_data(spbyte_array);
    if EXT_ALIGN = true then
      sp_word <= word_array(0);
    else
      sp_word <= word_array(lane);
    end if;
  end process;

  ---------------------------------------------------------------------------
  assert C_S_AXI_ADDR_WIDTH >= ADDR_WIDTH report "C_S_AXI_ADDR_WIDTH (" &
    integer'image(C_S_AXI_ADDR_WIDTH) & ") < ADDR_WIDTH ("
    & integer'image(ADDR_WIDTH) & ")."
    severity failure;

  assert C_S_AXI_DATA_WIDTH = 32 report "C_S_AXI_DATA_WIDTH (" &
    integer'image(C_S_AXI_DATA_WIDTH) & ") != 32."
    severity failure;

end architecture rtl;
