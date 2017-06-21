-- dma_controller_axi.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.
--
-- Wrapper for dma_queue and AXI version of dma_engine.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;
use work.isa_pkg.all;
use work.architecture_pkg.all;
use work.component_pkg.all;

entity dma_controller_axi is
  generic (
    VECTOR_LANES       : integer := 1;
    MEMORY_WIDTH_LANES : integer range 1 to 32   := 1;
    BURSTLENGTH_BYTES  : integer range 4 to 4096 := 32;

    ADDR_WIDTH : integer := 1;

    C_M_AXI_ADDR_WIDTH   : integer := 32;
    C_M_AXI_ARUSER_WIDTH : integer :=  5;
    C_M_AXI_AWUSER_WIDTH : integer :=  5
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    dma_instr_valid    : in  std_logic;
    dma_instruction    : in  instruction_type;
    dma_instr_read     : out std_logic;
    dma_status         : out std_logic_vector(dma_info_vector_length(ADDR_WIDTH)-1 downto 0);
    dma_pipeline_empty : out std_logic;

    dma_request_out : in  std_logic_vector(scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    dma_request_in  : out std_logic_vector(scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

    -- AXI4 master
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
end entity dma_controller_axi;

architecture rtl of dma_controller_axi is
  signal dma_queue_write         : std_logic;
  signal dma_queue_read          : std_logic;
  signal update_scratchpad_start : std_logic;
  signal new_scratchpad_start    : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal update_external_start   : std_logic;
  signal new_external_start      : std_logic_vector(31 downto 0);
  signal decrement_rows          : std_logic;
  signal dma_queue_empty         : std_logic;
  signal dma_queue_full          : std_logic;
  signal current_dma             : std_logic_vector(dma_info_length(ADDR_WIDTH)-1 downto 0);

  signal dma_in_progress   : std_logic;
  signal dma_instr_execute : std_logic;
  signal dma_instr_setup   : std_logic;

  signal dma_2d_rows           : unsigned(ADDR_WIDTH-1 downto 0);
  signal dma_2d_scratch_incr   : unsigned(ADDR_WIDTH-1 downto 0);
  signal dma_2d_scratch_length : unsigned(ADDR_WIDTH downto 0);
  signal dma_2d_ext_incr       : unsigned(31 downto 0);
begin
  dma_instr_execute  <= dma_instr_valid and (not dma_instruction.sv);
  dma_instr_setup    <= dma_instr_valid and dma_instruction.sv;
  dma_queue_write    <= dma_instr_execute and (not dma_queue_full);
  dma_instr_read     <= dma_queue_write or dma_instr_setup;
  dma_pipeline_empty <= dma_queue_empty and (not dma_in_progress);

  process (clk)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        dma_2d_rows           <= to_unsigned(1, dma_2d_rows'length);
        dma_2d_scratch_incr   <= to_unsigned(0, dma_2d_scratch_incr'length);
        dma_2d_scratch_length <= to_unsigned(0, dma_2d_scratch_length'length);
        dma_2d_ext_incr       <= to_unsigned(0, dma_2d_ext_incr'length);
      else
        if dma_instr_setup = '1' then
          if dma_instruction.two_d = '1' then
            dma_2d_scratch_length <= unsigned(dma_instruction.dest(dma_2d_scratch_length'range));
            dma_2d_scratch_incr   <= unsigned(dma_instruction.a(dma_2d_scratch_incr'range));
            dma_2d_rows           <= unsigned(dma_instruction.b(dma_2d_rows'range));
          else
            dma_2d_ext_incr <= unsigned(dma_instruction.a(dma_2d_ext_incr'range));
          end if;
        end if;
      end if;
    end if;
  end process;

  engine : dma_engine_axi
    generic map (
      VECTOR_LANES       => VECTOR_LANES,
      MEMORY_WIDTH_LANES => MEMORY_WIDTH_LANES,
      BURSTLENGTH_BYTES  => BURSTLENGTH_BYTES,

      ADDR_WIDTH => ADDR_WIDTH,

      C_M_AXI_ADDR_WIDTH   => C_M_AXI_ADDR_WIDTH,
      C_M_AXI_ARUSER_WIDTH => C_M_AXI_ARUSER_WIDTH,
      C_M_AXI_AWUSER_WIDTH => C_M_AXI_AWUSER_WIDTH
      )
    port map (
      clk   => clk,
      reset => reset,

      current_dma     => current_dma,
      dma_request_out => dma_request_out,

      update_external_start   => update_external_start,
      new_external_start      => new_external_start,
      update_scratchpad_start => update_scratchpad_start,
      new_scratchpad_start    => new_scratchpad_start,
      decrement_rows          => decrement_rows,

      dma_request_in  => dma_request_in,
      dma_queue_read  => dma_queue_read,
      dma_in_progress => dma_in_progress,

      m_axi_arready   => m_axi_arready,
      m_axi_arvalid   => m_axi_arvalid,
      m_axi_araddr    => m_axi_araddr,
      m_axi_arlen     => m_axi_arlen,
      m_axi_arsize    => m_axi_arsize,
      m_axi_arburst   => m_axi_arburst,
      m_axi_arprot    => m_axi_arprot,
      m_axi_arcache   => m_axi_arcache,
      m_axi_aruser    => m_axi_aruser,

      m_axi_rready    => m_axi_rready,
      m_axi_rvalid    => m_axi_rvalid,
      m_axi_rdata     => m_axi_rdata,
      m_axi_rresp     => m_axi_rresp,
      m_axi_rlast     => m_axi_rlast,

      m_axi_awready   => m_axi_awready,
      m_axi_awvalid   => m_axi_awvalid,
      m_axi_awaddr    => m_axi_awaddr,
      m_axi_awlen     => m_axi_awlen,
      m_axi_awsize    => m_axi_awsize,
      m_axi_awburst   => m_axi_awburst,
      m_axi_awprot    => m_axi_awprot,
      m_axi_awcache   => m_axi_awcache,
      m_axi_awuser    => m_axi_awuser,

      m_axi_wready    => m_axi_wready,
      m_axi_wvalid    => m_axi_wvalid,
      m_axi_wdata     => m_axi_wdata,
      m_axi_wstrb     => m_axi_wstrb,
      m_axi_wlast     => m_axi_wlast,

      m_axi_bready    => m_axi_bready,
      m_axi_bvalid    => m_axi_bvalid,
      m_axi_bresp     => m_axi_bresp
      );

  queue : dma_queue
    generic map (
      ADDR_WIDTH => ADDR_WIDTH
      )
    port map (
      clk   => clk,
      reset => reset,

      dma_instruction => dma_instruction,
      dma_queue_write => dma_queue_write,
      dma_queue_read  => dma_queue_read,

      update_scratchpad_start => update_scratchpad_start,
      new_scratchpad_start    => new_scratchpad_start,
      update_external_start   => update_external_start,
      new_external_start      => new_external_start,
      decrement_rows          => decrement_rows,

      dma_2d_rows           => dma_2d_rows,
      dma_2d_scratch_incr   => dma_2d_scratch_incr,
      dma_2d_scratch_length => dma_2d_scratch_length,
      dma_2d_ext_incr       => dma_2d_ext_incr,

      current_dma     => current_dma,
      dma_status      => dma_status,
      dma_queue_empty => dma_queue_empty,
      dma_queue_full  => dma_queue_full
      );

end architecture rtl;
