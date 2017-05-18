-- dma_queue.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;
use work.isa_pkg.all;
use work.architecture_pkg.all;

entity dma_queue is
  generic (
    ADDR_WIDTH : integer := 1
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    dma_instruction : in instruction_type;
    dma_queue_write : in std_logic;
    dma_queue_read  : in std_logic;

    update_scratchpad_start : in std_logic;
    new_scratchpad_start    : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    update_external_start   : in std_logic;
    new_external_start      : in std_logic_vector(31 downto 0);
    decrement_rows          : in std_logic;

    dma_2d_rows           : in unsigned(ADDR_WIDTH-1 downto 0);
    dma_2d_scratch_incr   : in unsigned(ADDR_WIDTH-1 downto 0);
    dma_2d_scratch_length : in unsigned(ADDR_WIDTH downto 0);
    dma_2d_ext_incr       : in unsigned(31 downto 0);

    current_dma     : out std_logic_vector(dma_info_length(ADDR_WIDTH)-1 downto 0);
    dma_status      : out std_logic_vector(dma_info_vector_length(ADDR_WIDTH)-1 downto 0);
    dma_queue_empty : out std_logic;
    dma_queue_full  : out std_logic
    );
end entity dma_queue;

architecture rtl of dma_queue is
  type dma_info is record
    valid            : std_logic;
    two_d            : std_logic;
    scratchpad_write : std_logic;
    scratchpad_start : std_logic_vector(ADDR_WIDTH-1 downto 0);
    scratchpad_end   : std_logic_vector(ADDR_WIDTH downto 0);
    length           : std_logic_vector(ADDR_WIDTH downto 0);
    external_start   : std_logic_vector(31 downto 0);
    rows             : unsigned(ADDR_WIDTH-1 downto 0);
    ext_incr         : unsigned(31 downto 0);
    scratch_incr     : unsigned(ADDR_WIDTH-1 downto 0);
  end record;
  type   dma_info_vector is array (DMA_QUEUE_SIZE-1 downto 0) of dma_info;
  signal dma_status_record : dma_info_vector;

  type     dma_queue is array (DMA_QUEUE_SIZE downto 0) of dma_info;
  signal   queue          : dma_queue;
  constant INVALID_VECTOR : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0) := (others => '0');
  signal   valid_vector   : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);
  signal   queue_read     : std_logic_vector(DMA_QUEUE_SIZE-1 downto 0);

  signal scratch_length : unsigned(ADDR_WIDTH downto 0);
begin
  dma_status(dma_info_length(ADDR_WIDTH)-1 downto 0) <=
    dma_info_flatten(dma_status_record(0).valid,
                     dma_status_record(0).two_d,
                     dma_status_record(0).scratchpad_write,
                     dma_status_record(0).scratchpad_start,
                     dma_status_record(0).scratchpad_end,
                     dma_status_record(0).length,
                     dma_status_record(0).external_start,
                     dma_status_record(0).rows,
                     dma_status_record(0).ext_incr,
                     dma_status_record(0).scratch_incr);
  current_dma <=
    dma_info_flatten(dma_status_record(0).valid,
                     dma_status_record(0).two_d,
                     dma_status_record(0).scratchpad_write,
                     dma_status_record(0).scratchpad_start,
                     dma_status_record(0).scratchpad_end,
                     dma_status_record(0).length,
                     dma_status_record(0).external_start,
                     dma_status_record(0).rows,
                     dma_status_record(0).ext_incr,
                     dma_status_record(0).scratch_incr);

  dma_queue_empty <= '1' when valid_vector = INVALID_VECTOR else '0';
  dma_queue_full  <= valid_vector(DMA_QUEUE_SIZE-1);

  dma_status_record(0) <= queue(0);
  valid_vector(0)      <= queue(0).valid;
  queue_read(0)        <= ((not queue(0).valid) or dma_queue_read) and queue(1).valid;

  -- purpose: Queue entry 0, which must also update start locations
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if reset = '1' then               -- synchronous reset (active high)
        queue(0).valid            <= '0';
        queue(0).two_d            <= '0';
        queue(0).scratchpad_write <= '0';
        queue(0).scratchpad_start <= (others => '0');
        queue(0).scratchpad_end   <= (others => '0');
        queue(0).length           <= (others => '0');
        queue(0).external_start   <= (others => '0');
        queue(0).rows             <= (others => '0');
        queue(0).ext_incr         <= (others => '0');
        queue(0).scratch_incr     <= (others => '0');
      else
        if update_scratchpad_start = '1' then
          queue(0).scratchpad_start <= new_scratchpad_start;
        end if;
        if update_external_start = '1' then
          queue(0).external_start <= new_external_start;
        end if;
        if decrement_rows = '1' then
          queue(0).rows <= queue(0).rows - 1;
        end if;

        if queue_read(0) = '1' then
          queue(0).valid            <= '1';
          queue(0).two_d            <= queue(1).two_d;
          queue(0).scratchpad_write <= queue(1).scratchpad_write;
          queue(0).scratchpad_start <= queue(1).scratchpad_start;
          queue(0).scratchpad_end   <= queue(1).scratchpad_end;
          queue(0).length           <= queue(1).length;
          queue(0).external_start   <= queue(1).external_start;
          queue(0).rows             <= queue(1).rows;
          queue(0).ext_incr         <= queue(1).ext_incr;
          queue(0).scratch_incr     <= queue(1).scratch_incr;
        elsif dma_queue_read = '1' then
          queue(0).valid <= '0';
        end if;
      end if;
    end if;
  end process;

  dma_queue_gen : for gentry in DMA_QUEUE_SIZE-1 downto 1 generate
    dma_status(((gentry+1)*dma_info_length(ADDR_WIDTH))-1 downto
               (gentry*dma_info_length(ADDR_WIDTH))) <=
      dma_info_flatten(dma_status_record(gentry).valid,
                       dma_status_record(gentry).two_d,
                       dma_status_record(gentry).scratchpad_write,
                       dma_status_record(gentry).scratchpad_start,
                       dma_status_record(gentry).scratchpad_end,
                       dma_status_record(gentry).length,
                       dma_status_record(gentry).external_start,
                       dma_status_record(gentry).rows,
                       dma_status_record(gentry).ext_incr,
                       dma_status_record(gentry).scratch_incr);

    dma_status_record(gentry) <= queue(gentry);
    valid_vector(gentry)      <= queue(gentry).valid;
    queue_read(gentry)        <= ((not queue(gentry).valid) or queue_read(gentry-1)) and queue(gentry+1).valid;

    -- purpose: Middle queue entries
    mid_queue_proc : process (clk)
    begin  -- process mid_queue_proc
      if clk'event and clk = '1' then   -- rising clock edge
        if reset = '1' then             -- synchronous reset (active high)
          queue(gentry).valid            <= '0';
          queue(gentry).two_d            <= '0';
          queue(gentry).scratchpad_write <= '0';
          queue(gentry).scratchpad_start <= (others => '0');
          queue(gentry).scratchpad_end   <= (others => '0');
          queue(gentry).length           <= (others => '0');
          queue(gentry).external_start   <= (others => '0');
          queue(gentry).rows             <= (others => '0');
          queue(gentry).ext_incr         <= (others => '0');
          queue(gentry).scratch_incr     <= (others => '0');
        else
          if queue_read(gentry) = '1' then
            queue(gentry).valid            <= '1';
            queue(gentry).two_d            <= queue(gentry+1).two_d;
            queue(gentry).scratchpad_write <= queue(gentry+1).scratchpad_write;
            queue(gentry).scratchpad_start <= queue(gentry+1).scratchpad_start;
            queue(gentry).scratchpad_end   <= queue(gentry+1).scratchpad_end;
            queue(gentry).length           <= queue(gentry+1).length;
            queue(gentry).external_start   <= queue(gentry+1).external_start;
            queue(gentry).rows             <= queue(gentry+1).rows;
            queue(gentry).ext_incr         <= queue(gentry+1).ext_incr;
            queue(gentry).scratch_incr     <= queue(gentry+1).scratch_incr;
          elsif queue_read(gentry-1) = '1' then
            queue(gentry).valid <= '0';
          end if;
        end if;
      end if;
    end process mid_queue_proc;
  end generate dma_queue_gen;

  queue(DMA_QUEUE_SIZE).valid <=
    '1' when (dma_queue_write = '1' and
              queue(DMA_QUEUE_SIZE).length /= std_logic_vector(to_unsigned(0, queue(DMA_QUEUE_SIZE).length'length)))
    else '0';
  queue(DMA_QUEUE_SIZE).two_d            <= dma_instruction.two_d;
  queue(DMA_QUEUE_SIZE).scratchpad_write <= '1' when dma_instruction.op = OP_DMA_TO_VECTOR else '0';
  queue(DMA_QUEUE_SIZE).scratchpad_start <= dma_instruction.b(ADDR_WIDTH-1 downto 0);

  scratch_length <=
    unsigned(dma_instruction.dest(scratch_length'range)) when dma_instruction.two_d = '0'
    else dma_2d_scratch_length;
  queue(DMA_QUEUE_SIZE).scratchpad_end <=
    std_logic_vector(scratch_length + resize(unsigned(dma_instruction.b), scratch_length'length));

  queue(DMA_QUEUE_SIZE).length         <= dma_instruction.dest(queue(DMA_QUEUE_SIZE).length'range);
  queue(DMA_QUEUE_SIZE).external_start <= dma_instruction.a;
  queue(DMA_QUEUE_SIZE).rows           <=
    to_unsigned(1, queue(DMA_QUEUE_SIZE).rows'length) when dma_instruction.two_d = '0'
    else dma_2d_rows;
  queue(DMA_QUEUE_SIZE).ext_incr <=
    dma_2d_ext_incr when dma_instruction.two_d = '1' else
    resize(unsigned(queue(DMA_QUEUE_SIZE).length), queue(DMA_QUEUE_SIZE).ext_incr'length);
  queue(DMA_QUEUE_SIZE).scratch_incr <=
    dma_2d_scratch_incr when dma_instruction.two_d = '1' else
    resize(unsigned(queue(DMA_QUEUE_SIZE).length), queue(DMA_QUEUE_SIZE).scratch_incr'length);

end architecture rtl;
