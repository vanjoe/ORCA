-- dma_hazard_detect.vhd
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

entity dma_hazard_detect is
  generic (
    VECTOR_LANES : integer := 1;

    ADDR_WIDTH : integer := 1
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    dma_status : in std_logic_vector(dma_info_vector_length(ADDR_WIDTH)-1 downto 0);

    addr_a       : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    instr_uses_a : in std_logic;
    addr_b       : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    instr_uses_b : in std_logic;
    addr_dest    : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    write_dest   : in std_logic;

    prev_addr_a       : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    prev_instr_uses_a : in std_logic;
    prev_addr_b       : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    prev_instr_uses_b : in std_logic;
    prev_addr_dest    : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    prev_write_dest   : in std_logic;

    dma_hazard : out std_logic
    );
end entity dma_hazard_detect;

architecture rtl of dma_hazard_detect is
  type dma_info is record
    valid            : std_logic;
    scratchpad_write : std_logic;
    scratchpad_start : std_logic_vector(ADDR_WIDTH-1 downto 0);
    scratchpad_end   : std_logic_vector(ADDR_WIDTH downto 0);
    length           : std_logic_vector(ADDR_WIDTH downto 0);
    external_start   : std_logic_vector(31 downto 0);
  end record;
  type   dma_info_vector is array (DMA_QUEUE_SIZE-1 downto 0) of dma_info;
  signal dma_status_record : dma_info_vector;

  type   queue_addr_type is array (DMA_QUEUE_SIZE-1 downto 0) of std_logic_vector(ADDR_WIDTH downto 0);
  signal start_minus_width : queue_addr_type;

  signal dma_wraps : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);

  signal read_a_gte    : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal read_a_lte    : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal read_a_hazard : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal read_b_gte    : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal read_b_lte    : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal read_b_hazard : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal write_gte     : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal write_lte     : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal write_hazard  : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal rw_hazard     : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);

  signal prev_read_a_gte    : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal prev_read_a_lte    : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal prev_read_a_hazard : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal prev_read_b_gte    : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal prev_read_b_lte    : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal prev_read_b_hazard : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal prev_write_gte     : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal prev_write_lte     : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal prev_write_hazard  : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal prev_rw_hazard     : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
begin

  hazard_queue_gen : for gentry in DMA_QUEUE_SIZE-1 downto 0 generate
    dma_status_record(gentry).valid <=
      dma_info_get(dma_status(((gentry+1)*dma_info_length(ADDR_WIDTH))-1 downto gentry*dma_info_length(ADDR_WIDTH)),
                   DMA_INFO_GET_VALID, ADDR_WIDTH)(0);
    dma_status_record(gentry).scratchpad_write <=
      dma_info_get(dma_status(((gentry+1)*dma_info_length(ADDR_WIDTH))-1 downto gentry*dma_info_length(ADDR_WIDTH)),
                   DMA_INFO_GET_SCRATCHPAD_WRITE, ADDR_WIDTH)(0);
    dma_status_record(gentry).scratchpad_start <=
      dma_info_get(dma_status(((gentry+1)*dma_info_length(ADDR_WIDTH))-1 downto gentry*dma_info_length(ADDR_WIDTH)),
                   DMA_INFO_GET_SCRATCHPAD_START, ADDR_WIDTH);
    dma_status_record(gentry).scratchpad_end <=
      dma_info_get(dma_status(((gentry+1)*dma_info_length(ADDR_WIDTH))-1 downto gentry*dma_info_length(ADDR_WIDTH)),
                   DMA_INFO_GET_SCRATCHPAD_END, ADDR_WIDTH);
    dma_status_record(gentry).length <=
      dma_info_get(dma_status(((gentry+1)*dma_info_length(ADDR_WIDTH))-1 downto gentry*dma_info_length(ADDR_WIDTH)),
                   DMA_INFO_GET_LENGTH, ADDR_WIDTH);
    dma_status_record(gentry).external_start <=
      dma_info_get(dma_status(((gentry+1)*dma_info_length(ADDR_WIDTH))-1 downto gentry*dma_info_length(ADDR_WIDTH)),
                   DMA_INFO_GET_EXTERNAL_START, ADDR_WIDTH);

    dma_wraps(gentry) <= '1' when (unsigned(dma_status_record(gentry).scratchpad_end(ADDR_WIDTH-1 downto 0)) <
                                   unsigned(dma_status_record(gentry).scratchpad_start))
                         else dma_status_record(gentry).scratchpad_end(ADDR_WIDTH);
    start_minus_width(gentry) <= std_logic_vector(unsigned('1' & dma_status_record(gentry).scratchpad_start) -
                                                  to_unsigned(3*(VECTOR_LANES*4), ADDR_WIDTH+1));

    read_a_gte(gentry) <=
      '1' when unsigned('1' & addr_a) >= unsigned(start_minus_width(gentry)) else '0';
    read_a_lte(gentry) <=
      '1' when unsigned(dma_status_record(gentry).scratchpad_end(ADDR_WIDTH-1 downto 0)) > unsigned(addr_a) else '0';
    read_a_hazard(gentry) <=
      instr_uses_a and (read_a_gte(gentry) and read_a_lte(gentry)) when
      dma_wraps(gentry) = '0' else
      instr_uses_a and (read_a_gte(gentry) or read_a_lte(gentry));

    read_b_gte(gentry) <=
      '1' when unsigned('1' & addr_b) >= unsigned(start_minus_width(gentry)) else '0';
    read_b_lte(gentry) <=
      '1' when unsigned(dma_status_record(gentry).scratchpad_end(ADDR_WIDTH-1 downto 0)) > unsigned(addr_b) else '0';
    read_b_hazard(gentry) <=
      instr_uses_b and (read_b_gte(gentry) and read_b_lte(gentry))
      when dma_wraps(gentry) = '0' else
      instr_uses_b and (read_b_gte(gentry) or read_b_lte(gentry));

    write_gte(gentry) <=
      '1' when unsigned('1' & addr_dest) >= unsigned(start_minus_width(gentry)) else '0';
    write_lte(gentry) <=
      '1' when unsigned(dma_status_record(gentry).scratchpad_end(ADDR_WIDTH-1 downto 0)) > unsigned(addr_dest) else '0';
    write_hazard(gentry) <=
      write_dest and (write_gte(gentry) and write_lte(gentry)) when
      dma_wraps(gentry) = '0' else
      (write_gte(gentry) or write_lte(gentry));

    rw_hazard(gentry) <= (((read_a_hazard(gentry) or read_b_hazard(gentry)) and dma_status_record(gentry).scratchpad_write) or
                          write_hazard(gentry)) and
                         dma_status_record(gentry).valid;

    prev_read_a_gte(gentry) <=
      '1' when unsigned('1' & prev_addr_a) >= unsigned(start_minus_width(gentry)) else '0';
    prev_read_a_lte(gentry) <=
      '1' when unsigned(dma_status_record(gentry).scratchpad_end(ADDR_WIDTH-1 downto 0)) > unsigned(prev_addr_a) else '0';
    prev_read_a_hazard(gentry) <=
      prev_instr_uses_a and (prev_read_a_gte(gentry) and prev_read_a_lte(gentry)) when
      dma_wraps(gentry) = '0' else
      prev_instr_uses_a and (prev_read_a_gte(gentry) or prev_read_a_lte(gentry));

    prev_read_b_gte(gentry) <=
      '1' when unsigned('1' & prev_addr_b) >= unsigned(start_minus_width(gentry)) else '0';
    prev_read_b_lte(gentry) <=
      '1' when unsigned(dma_status_record(gentry).scratchpad_end(ADDR_WIDTH-1 downto 0)) > unsigned(prev_addr_b) else '0';
    prev_read_b_hazard(gentry) <=
      prev_instr_uses_b and (prev_read_b_gte(gentry) and prev_read_b_lte(gentry))
      when dma_wraps(gentry) = '0' else
      prev_instr_uses_b and (prev_read_b_gte(gentry) or prev_read_b_lte(gentry));

    prev_write_gte(gentry) <=
      '1' when unsigned('1' & prev_addr_dest) >= unsigned(start_minus_width(gentry)) else '0';
    prev_write_lte(gentry) <=
      '1' when unsigned(dma_status_record(gentry).scratchpad_end(ADDR_WIDTH-1 downto 0)) > unsigned(prev_addr_dest) else '0';
    prev_write_hazard(gentry) <=
      prev_write_dest and (prev_write_gte(gentry) and prev_write_lte(gentry))
      when dma_wraps(gentry) = '0' else
      (prev_write_gte(gentry) or prev_write_lte(gentry));

    prev_rw_hazard(gentry) <= (((prev_read_a_hazard(gentry) or prev_read_b_hazard(gentry)) and dma_status_record(gentry).scratchpad_write) or
                               prev_write_hazard(gentry)) and
                              dma_status_record(gentry).valid;
  end generate hazard_queue_gen;

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if (rw_hazard = std_logic_vector(to_unsigned(0, DMA_QUEUE_SIZE)) and
          prev_rw_hazard = std_logic_vector(to_unsigned(0, DMA_QUEUE_SIZE)))  then
        dma_hazard <= '0';
      else
        dma_hazard <= '1';
      end if;
    end if;
  end process;
end architecture rtl;
