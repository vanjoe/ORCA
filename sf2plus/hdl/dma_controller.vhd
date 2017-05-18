-- dma_controller.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;
use work.isa_pkg.all;
use work.architecture_pkg.all;
use work.component_pkg.all;

entity dma_controller is
  generic (
    VECTOR_LANES       : integer := 1;
    MEMORY_WIDTH_LANES : integer := 1;
    BURSTLENGTH_BYTES  : integer := 32;

    ADDR_WIDTH : integer := 1
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

    master_address       : out std_logic_vector(31 downto 0);
    master_read          : out std_logic;
    master_write         : out std_logic;
    master_waitrequest   : in  std_logic;
    master_readdatavalid : in  std_logic;

    master_burstcount : out std_logic_vector(burst_bits(BURSTLENGTH_BYTES, MEMORY_WIDTH_LANES)-1 downto 0);

    master_writedata  : out std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);
    master_byteenable : out std_logic_vector(MEMORY_WIDTH_LANES*4-1 downto 0);
    master_readdata   : in  std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0)
    );
end entity dma_controller;

architecture rtl of dma_controller is
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
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if dma_instr_setup = '1' then
        if dma_instruction.two_d = '1' then
          dma_2d_scratch_length <= unsigned(dma_instruction.dest(dma_2d_scratch_length'range));
          dma_2d_scratch_incr   <= unsigned(dma_instruction.a(dma_2d_scratch_incr'range));
          dma_2d_rows           <= unsigned(dma_instruction.b(dma_2d_rows'range));
        else
          dma_2d_ext_incr <= unsigned(dma_instruction.a(dma_2d_ext_incr'range));
        end if;
      end if;

      if reset = '1' then               -- synchronous reset (active high)
        dma_2d_rows           <= to_unsigned(1, dma_2d_rows'length);
        dma_2d_scratch_incr   <= to_unsigned(0, dma_2d_scratch_incr'length);
        dma_2d_scratch_length <= to_unsigned(0, dma_2d_scratch_length'length);
        dma_2d_ext_incr       <= to_unsigned(0, dma_2d_ext_incr'length);
      end if;
    end if;
  end process;

  engine : component dma_engine
    generic map (
      VECTOR_LANES       => VECTOR_LANES,
      MEMORY_WIDTH_LANES => MEMORY_WIDTH_LANES,
      BURSTLENGTH_BYTES  => BURSTLENGTH_BYTES,

      ADDR_WIDTH => ADDR_WIDTH
      )
    port map (
      clk   => clk,
      reset => reset,

      current_dma     => current_dma,
      dma_request_out => dma_request_out,

      master_waitrequest   => master_waitrequest,
      master_readdatavalid => master_readdatavalid,
      master_readdata      => master_readdata,

      master_address    => master_address,
      master_read       => master_read,
      master_write      => master_write,
      master_burstcount => master_burstcount,
      master_writedata  => master_writedata,
      master_byteenable => master_byteenable,

      update_scratchpad_start => update_scratchpad_start,
      new_scratchpad_start    => new_scratchpad_start,
      update_external_start   => update_external_start,
      new_external_start      => new_external_start,
      decrement_rows          => decrement_rows,

      dma_request_in  => dma_request_in,
      dma_queue_read  => dma_queue_read,
      dma_in_progress => dma_in_progress
      );

  queue : component dma_queue
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
