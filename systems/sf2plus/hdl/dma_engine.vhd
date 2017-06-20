-- dma_engine.vhd
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
library altera_mf;
use altera_mf.altera_mf_components.all;

entity dma_engine is
  generic (
    VECTOR_LANES       : integer := 1;
    MEMORY_WIDTH_LANES : integer := 1;
    BURSTLENGTH_BYTES  : integer := 32;

    ADDR_WIDTH : integer := 1
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    current_dma     : in std_logic_vector(dma_info_length(ADDR_WIDTH)-1 downto 0);
    dma_request_out : in std_logic_vector(scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

    master_waitrequest   : in std_logic;
    master_readdatavalid : in std_logic;
    master_readdata      : in std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);

    master_address    : out std_logic_vector(31 downto 0);
    master_read       : out std_logic;
    master_write      : out std_logic;
    master_burstcount : out std_logic_vector(burst_bits(BURSTLENGTH_BYTES, MEMORY_WIDTH_LANES)-1 downto 0);
    master_writedata  : out std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);
    master_byteenable : out std_logic_vector(MEMORY_WIDTH_LANES*4-1 downto 0);

    update_scratchpad_start : out std_logic;
    new_scratchpad_start    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    update_external_start   : out std_logic;
    new_external_start      : out std_logic_vector(31 downto 0);
    decrement_rows          : out std_logic;

    dma_request_in  : out std_logic_vector(scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    dma_queue_read  : out std_logic;
    dma_in_progress : out std_logic
    );
end entity dma_engine;

architecture rtl of dma_engine is
  constant VECTOR_MEMORY_WIDTHS : integer := VECTOR_LANES/MEMORY_WIDTH_LANES;
  constant MEMORY_WIDTH_BYTES   : integer := MEMORY_WIDTH_LANES*4;
  constant MEMORY_WIDTH_BITS    : integer := MEMORY_WIDTH_LANES*32;
  constant BURSTCOUNT_BITS      : integer := burst_bits(BURSTLENGTH_BYTES, MEMORY_WIDTH_LANES);
  constant BURSTCOUNT_WORDS     : integer := BURSTLENGTH_BYTES/(MEMORY_WIDTH_BYTES);
  constant DMA_DATA_FIFO_DEPTH  : integer := BURSTCOUNT_WORDS*DMA_DATA_FIFO_BURSTS;
  constant DMA_DATA_FIFO_BITS   : integer := log2(DMA_DATA_FIFO_DEPTH);

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
  signal current_dma_record : dma_info;

  type   dma_state_type is (IDLE, TRANSFER, FINISHING, DONE);
  signal dma_state               : dma_state_type;
  signal next_dma_state_transfer : std_logic;

  signal data_fifo_write     : std_logic;
  signal data_fifo_writedata : std_logic_vector(MEMORY_WIDTH_BITS-1 downto 0);
  signal data_fifo_read      : std_logic;
  signal data_fifo_rdusedw   : std_logic_vector(DMA_DATA_FIFO_BITS-1 downto 0);
  signal data_fifo_rdempty   : std_logic;
  signal data_fifo_wrfull    : std_logic;
  signal data_fifo_readdata  : std_logic_vector(MEMORY_WIDTH_BITS-1 downto 0);

  signal next_outstanding_reads : unsigned(DMA_DATA_FIFO_BITS-1 downto 0);
  signal outstanding_reads      : unsigned(DMA_DATA_FIFO_BITS-1 downto 0);
  signal outstanding_reads_case : std_logic_vector(1 downto 0);
  signal lt2_outstanding_reads  : std_logic;
  signal read_waitrequest       : std_logic;
  signal write_waitrequest      : std_logic;
  signal last_read_in_row       : std_logic;
  signal last_read              : std_logic;
  signal first_write_in_row     : std_logic;
  signal last_write_in_row      : std_logic;
  signal all_done               : std_logic;

  signal scratch_rdreq          : std_logic;
  signal scratch_wrreq          : std_logic;
  signal rdreq                  : std_logic;
  signal readdatavalid          : std_logic;
  signal next_room_in_the_queue : std_logic;
  signal room_in_the_queue      : std_logic;

  signal last_ext_in_row      : std_logic;
  signal update_ext_start     : std_logic;
  signal last_scratch_in_row  : std_logic;
  signal update_scratch_start : std_logic;
  signal next_master_burst    : unsigned(BURSTCOUNT_BITS-1 downto 0);
  signal reload_master_burst  : std_logic;
  signal next_max_burstcount  : unsigned(BURSTCOUNT_BITS-1 downto 0);
  signal unaligned_length     : unsigned(BURSTCOUNT_BITS-1 downto 0);

  signal update_write_start           : std_logic;
  signal write_row_left               : unsigned(ADDR_WIDTH downto 0);
  signal next_write_row_left          : unsigned(ADDR_WIDTH downto 0);
  signal next_write_row_left_idle     : unsigned(ADDR_WIDTH downto 0);
  signal next_write_row_left_new_row  : unsigned(ADDR_WIDTH downto 0);
  signal next_write_row_left_reloaded : unsigned(ADDR_WIDTH downto 0);
  signal write_row_left_sub           : unsigned(ADDR_WIDTH downto 0);
  signal write_end_unaligned          : std_logic;
  signal read_row_left                : unsigned(ADDR_WIDTH downto 0);
  signal next_read_row_left           : unsigned(ADDR_WIDTH downto 0);
  signal next_read_row_left_idle      : unsigned(ADDR_WIDTH downto 0);
  signal next_read_row_left_new_row   : unsigned(ADDR_WIDTH downto 0);
  signal next_read_row_left_reloaded  : unsigned(ADDR_WIDTH downto 0);
  signal read_row_left_sub            : unsigned(ADDR_WIDTH downto 0);
  signal scratch_row_left             : unsigned(ADDR_WIDTH downto 0);
  signal ext_row_left                 : unsigned(ADDR_WIDTH downto 0);
  signal next_ext_row_left            : unsigned(ADDR_WIDTH downto 0);

  signal next_row_scratch_start      : unsigned(ADDR_WIDTH-1 downto 0);
  signal row_ext_adx                 : unsigned(31 downto 0);
  signal write_row_int_adx           : unsigned(ADDR_WIDTH-1 downto 0);
  signal write_row_ext_adx           : unsigned(31 downto 0);
  signal write_row_ext_adx_plus_incr : unsigned(31 downto 0);
  signal next_write_row_int_adx      : unsigned(ADDR_WIDTH-1 downto 0);
  signal next_write_row_ext_adx      : unsigned(31 downto 0);
  signal read_row_int_adx            : unsigned(ADDR_WIDTH-1 downto 0);
  signal read_row_ext_adx            : unsigned(31 downto 0);
  signal read_row_ext_adx_plus_incr  : unsigned(31 downto 0);
  signal next_read_row_int_adx       : unsigned(ADDR_WIDTH-1 downto 0);
  signal next_read_row_ext_adx       : unsigned(31 downto 0);

  signal master_wait         : std_logic;
  signal next_master_rdreq   : std_logic;
  signal master_rdreq        : std_logic;
  signal master_wrreq        : std_logic;
  signal master_buffer_empty : std_logic;
  signal master_burst        : unsigned(BURSTCOUNT_BITS-1 downto 0);
  signal master_adx          : std_logic_vector(31 downto 0);

  signal buffered_readdatavalid : std_logic;
  signal buffered_readdata      : std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);

  signal first_byteenable  : std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);
  signal last_byteenable   : std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);
  signal byteenable_case   : std_logic_vector(1 downto 0);
  signal write_byteenable  : std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);
  signal avalon_byteenable : std_logic_vector(MEMORY_WIDTH_BYTES-1 downto 0);

  signal dma_request_in_rd             : std_logic;
  signal dma_request_in_wr             : std_logic;
  signal dma_request_in_addr           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal dma_request_in_writedata      : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal dma_request_in_byteena        : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal dma_request_out_waitrequest   : std_logic;
  signal dma_request_out_readdatavalid : std_logic;
  signal dma_request_out_readdata      : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal dma_request_out_readdata_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
begin
  dma_request_in <= scratchpad_request_in_flatten(dma_request_in_rd,
                                                  dma_request_in_wr,
                                                  dma_request_in_addr,
                                                  dma_request_in_writedata,
                                                  dma_request_in_byteena);
  dma_request_out_waitrequest   <= scratchpad_request_out_get(dma_request_out, REQUEST_OUT_WAITREQUEST, VECTOR_LANES, ADDR_WIDTH)(0);
  dma_request_out_readdatavalid <= scratchpad_request_out_get(dma_request_out, REQUEST_OUT_READDATAVALID, VECTOR_LANES, ADDR_WIDTH)(0);
  dma_request_out_readdata      <= byte9_to_scratchpad_data(scratchpad_request_out_get(dma_request_out, REQUEST_OUT_READDATA, VECTOR_LANES, ADDR_WIDTH));
  dma_request_out_readdata_addr <= scratchpad_request_out_get(dma_request_out, REQUEST_OUT_READDATA_ADDR, VECTOR_LANES, ADDR_WIDTH);

  current_dma_record.valid            <= dma_info_get(current_dma, DMA_INFO_GET_VALID, ADDR_WIDTH)(0);
  current_dma_record.two_d            <= dma_info_get(current_dma, DMA_INFO_GET_TWO_D, ADDR_WIDTH)(0);
  current_dma_record.scratchpad_write <= dma_info_get(current_dma, DMA_INFO_GET_SCRATCHPAD_WRITE, ADDR_WIDTH)(0);
  current_dma_record.scratchpad_start <= dma_info_get(current_dma, DMA_INFO_GET_SCRATCHPAD_START, ADDR_WIDTH);
  current_dma_record.scratchpad_end   <= dma_info_get(current_dma, DMA_INFO_GET_SCRATCHPAD_END, ADDR_WIDTH);
  current_dma_record.length           <= dma_info_get(current_dma, DMA_INFO_GET_LENGTH, ADDR_WIDTH);
  current_dma_record.external_start   <= dma_info_get(current_dma, DMA_INFO_GET_EXTERNAL_START, ADDR_WIDTH);
  current_dma_record.rows             <= unsigned(dma_info_get(current_dma, DMA_INFO_GET_ROWS, ADDR_WIDTH));
  current_dma_record.ext_incr         <= unsigned(dma_info_get(current_dma, DMA_INFO_GET_EXT_INCR, ADDR_WIDTH));
  current_dma_record.scratch_incr     <= unsigned(dma_info_get(current_dma, DMA_INFO_GET_SCRATCH_INCR, ADDR_WIDTH));

  dma_in_progress <= '0' when dma_state = IDLE else '1';

  update_scratch_start <= (scratch_rdreq or scratch_wrreq) and (not dma_request_out_waitrequest);

  --For unaligned accesses, need to move scratchpad start back on new request
  update_scratchpad_start <= update_scratch_start when dma_state /= IDLE else current_dma_record.valid;
  update_ext_start        <= (master_rdreq or master_wrreq) and (not master_wait);
  update_external_start   <= update_ext_start;

  update_write_start <= update_scratch_start when current_dma_record.scratchpad_write = '1' else
                        update_ext_start;

  new_scratchpad_start <=
    std_logic_vector(unsigned(current_dma_record.scratchpad_start) +
                     to_unsigned(MEMORY_WIDTH_BYTES, current_dma_record.scratchpad_start'length))
    when last_scratch_in_row = '0' and dma_state /= IDLE
    else std_logic_vector(next_row_scratch_start);
  next_row_scratch_start <= next_write_row_int_adx when current_dma_record.scratchpad_write = '1' else
                            next_read_row_int_adx;
  new_external_start <=
    std_logic_vector(unsigned(current_dma_record.external_start) +
                     to_unsigned(MEMORY_WIDTH_BYTES, current_dma_record.external_start'length))
    when last_ext_in_row = '0'
    else std_logic_vector(row_ext_adx + current_dma_record.ext_incr);
  row_ext_adx <= read_row_ext_adx when current_dma_record.scratchpad_write = '1' else
                 write_row_ext_adx;

  next_ext_row_left <= next_read_row_left when current_dma_record.scratchpad_write = '1' else
                       next_write_row_left;
  scratch_row_left <= write_row_left when current_dma_record.scratchpad_write = '1' else
                      read_row_left;

  last_ext_in_row     <= update_ext_start     when ext_row_left <= MEMORY_WIDTH_BYTES     else '0';
  last_scratch_in_row <= update_scratch_start when scratch_row_left <= MEMORY_WIDTH_BYTES else '0';

  read_row_ext_adx_plus_incr <= read_row_ext_adx + unsigned(current_dma_record.ext_incr);
  next_read_row_int_adx      <=
    (unsigned(current_dma_record.scratchpad_start) -
     resize(unsigned(current_dma_record.external_start(log2(MEMORY_WIDTH_BYTES)-1 downto 0)), next_read_row_int_adx'length))
    when dma_state = IDLE
    else (read_row_int_adx +
          unsigned(current_dma_record.scratch_incr) +
          resize(read_row_ext_adx(log2(MEMORY_WIDTH_BYTES)-1 downto 0), next_read_row_int_adx'length) -
          resize(read_row_ext_adx_plus_incr(log2(MEMORY_WIDTH_BYTES)-1 downto 0), next_read_row_int_adx'length));
  next_read_row_ext_adx <= unsigned(current_dma_record.external_start) when dma_state = IDLE else
                           read_row_ext_adx_plus_incr;
  read_row_left_sub <= to_unsigned(MEMORY_WIDTH_BYTES, read_row_left_sub'length) when
                       ((update_ext_start = '1' and current_dma_record.scratchpad_write = '1') or
                        (update_scratch_start = '1' and current_dma_record.scratchpad_write = '0'))
                       else (others => '0');

  --Critical path; do separately so you get a 3 input adder followed by mux
  --instead of 2 input adder, mux, 2 input adder
  next_read_row_left_idle <=
    unsigned(current_dma_record.length) +
    resize(unsigned(current_dma_record.external_start(log2(MEMORY_WIDTH_BYTES)-1 downto 0)),
           next_read_row_left_idle'length);
  next_read_row_left_new_row <= unsigned(current_dma_record.length) +
                                resize(read_row_ext_adx(log2(MEMORY_WIDTH_BYTES)-1 downto 0) +
                                       unsigned(current_dma_record.ext_incr(log2(MEMORY_WIDTH_BYTES)-1 downto 0)),
                                       next_read_row_left_new_row'length);
  next_read_row_left_reloaded <= next_read_row_left_idle when dma_state = IDLE else next_read_row_left_new_row;

  next_read_row_left <= next_read_row_left_reloaded when dma_state = IDLE or last_read_in_row = '1' else
                        read_row_left - read_row_left_sub;

  write_row_ext_adx_plus_incr <= write_row_ext_adx + unsigned(current_dma_record.ext_incr);
  next_write_row_int_adx      <=
    (unsigned(current_dma_record.scratchpad_start) -
     resize(unsigned(current_dma_record.external_start(log2(MEMORY_WIDTH_BYTES)-1 downto 0)), next_write_row_int_adx'length))
    when dma_state = IDLE
    else (write_row_int_adx +
          unsigned(current_dma_record.scratch_incr) +
          resize(write_row_ext_adx(log2(MEMORY_WIDTH_BYTES)-1 downto 0), next_write_row_int_adx'length) -
          resize(write_row_ext_adx_plus_incr(log2(MEMORY_WIDTH_BYTES)-1 downto 0), next_write_row_int_adx'length));
  next_write_row_ext_adx <= unsigned(current_dma_record.external_start) when dma_state = IDLE else
                            write_row_ext_adx_plus_incr;
  write_row_left_sub <= to_unsigned(MEMORY_WIDTH_BYTES, write_row_left_sub'length) when
                        ((update_scratch_start = '1' and current_dma_record.scratchpad_write = '1') or
                         (update_ext_start = '1' and current_dma_record.scratchpad_write = '0'))
                        else (others => '0');

  --Critical path; do separately so you get a 3 input adder followed by mux
  --instead of 2 input adder, mux, 2 input adder
  next_write_row_left_idle <=
    unsigned(current_dma_record.length) +
    resize(unsigned(current_dma_record.external_start(log2(MEMORY_WIDTH_BYTES)-1 downto 0)),
           next_write_row_left_idle'length);
  next_write_row_left_new_row <= unsigned(current_dma_record.length) +
                                 resize(write_row_ext_adx(log2(MEMORY_WIDTH_BYTES)-1 downto 0) +
                                        unsigned(current_dma_record.ext_incr(log2(MEMORY_WIDTH_BYTES)-1 downto 0)),
                                        next_write_row_left_new_row'length);
  next_write_row_left_reloaded <= next_write_row_left_idle when dma_state = IDLE else next_write_row_left_new_row;

  next_write_row_left <= next_write_row_left_reloaded when dma_state = IDLE or last_write_in_row = '1' else
                         write_row_left - write_row_left_sub;

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if update_write_start = '1' then
        first_write_in_row <= '0';
      end if;

      if dma_state = IDLE or last_write_in_row = '1' then
        first_write_in_row <= '1';
        write_row_int_adx  <= next_write_row_int_adx;
        write_row_ext_adx  <= next_write_row_ext_adx;
      end if;
      if dma_state = IDLE or last_read_in_row = '1' then
        read_row_int_adx <= next_read_row_int_adx;
        read_row_ext_adx <= next_read_row_ext_adx;
      end if;
      read_row_left  <= next_read_row_left;
      write_row_left <= next_write_row_left;
      ext_row_left   <= next_ext_row_left;

      if reset = '1' then
        first_write_in_row <= '1';
      end if;
    end if;
  end process;

  unaligned_length <=
    to_unsigned(1, BURSTCOUNT_BITS) when (next_ext_row_left(log2(MEMORY_WIDTH_BYTES)-1 downto 0) /=
                                          to_unsigned(0, log2(MEMORY_WIDTH_BYTES)))
    else to_unsigned(0, BURSTCOUNT_BITS);
  next_max_burstcount <=
    to_unsigned(BURSTCOUNT_WORDS, next_max_burstcount'length)
    when (next_ext_row_left(next_ext_row_left'left downto log2(BURSTLENGTH_BYTES)) /=
          to_unsigned(0, next_ext_row_left'length-log2(BURSTLENGTH_BYTES)))
    else next_ext_row_left(log2(BURSTLENGTH_BYTES) downto log2(MEMORY_WIDTH_BYTES)) + unaligned_length;

  reload_master_burst <= '1' when ((dma_state = IDLE and current_dma_record.valid = '1') or
                                   (update_ext_start = '1' and master_burst = to_unsigned(1, master_burst'length)))
                         else '0';
  next_master_burst <=
    next_max_burstcount when reload_master_burst = '1' else
    master_burst - to_unsigned(1, master_burst'length);
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if reload_master_burst = '1' or ((master_wrreq = '1' or master_rdreq = '1') and master_wait = '0') then
        master_burst <= next_master_burst;
      end if;

      master_rdreq <= next_master_rdreq;

      if reset = '1' then
        master_burst <= (others => '0');
        master_rdreq <= '0';
      end if;
    end if;
  end process;

  dma_request_in_addr <= current_dma_record.scratchpad_start;

  dma_request_in_rd <= scratch_rdreq;
  scratch_rdreq <= '1' when (current_dma_record.scratchpad_write = '0' and
                             (dma_state = TRANSFER) and
                             room_in_the_queue = '1') else
                   '0';
  next_master_rdreq <= '1' when (current_dma_record.scratchpad_write = '1' and
                                 next_dma_state_transfer = '1' and
                                 next_room_in_the_queue = '1') else
                       '0';

  dma_request_in_wr <= scratch_wrreq;
  scratch_wrreq <= '1' when (current_dma_record.scratchpad_write = '1' and
                             (dma_state /= IDLE) and
                             data_fifo_rdempty = '0') else
                   '0';
  master_wrreq <= '1' when (current_dma_record.scratchpad_write = '0' and
                            (dma_state /= IDLE) and
                            data_fifo_rdempty = '0') else
                  '0';

  write_end_unaligned <=
    '1' when write_row_left(log2(MEMORY_WIDTH_BYTES)-1 downto 0) /= to_unsigned(0, log2(MEMORY_WIDTH_BYTES))
    else '0';
  edge_byteenable_gen : for gbyte in MEMORY_WIDTH_BYTES-1 downto 0 generate
    last_byteenable(gbyte) <= '1' when (to_unsigned(gbyte, log2(MEMORY_WIDTH_BYTES)) <
                                        write_row_left(log2(MEMORY_WIDTH_BYTES)-1 downto 0))
                              else (not write_end_unaligned);
    first_byteenable(gbyte) <= '1' when (to_unsigned(gbyte, log2(MEMORY_WIDTH_BYTES)) >=
                                         write_row_ext_adx(log2(MEMORY_WIDTH_BYTES)-1 downto 0))
                               else '0';
  end generate edge_byteenable_gen;

  byteenable_case <= last_write_in_row & first_write_in_row;
  with byteenable_case select
    write_byteenable <=
    first_byteenable                     when "01",
    last_byteenable                      when "10",
    first_byteenable and last_byteenable when "11",
    (others => '1')                      when others;

  avalon_byteenable <= write_byteenable when current_dma_record.scratchpad_write = '0' else
                       (others => '1');

  master_buffer : avalon_buffer
    generic map (
      ADDR_WIDTH       => 32,
      MEM_WIDTH_BYTES  => MEMORY_WIDTH_BYTES,
      BURSTCOUNT_BITS  => BURSTCOUNT_BITS,
      MULTI_READ_BURST => true,
      BUFFER_READDATA  => false
      )
    port map (
      clk   => clk,
      reset => reset,

      empty => master_buffer_empty,

      slave_waitrequest   => master_wait,
      slave_address       => master_adx,
      slave_burstcount    => std_logic_vector(master_burst),
      slave_read          => master_rdreq,
      slave_write         => master_wrreq,
      slave_writedata     => data_fifo_readdata,
      slave_byteenable    => avalon_byteenable,
      slave_readdatavalid => buffered_readdatavalid,
      slave_readdata      => buffered_readdata,

      master_waitrequest   => master_waitrequest,
      master_address       => master_address,
      master_burstcount    => master_burstcount,
      master_read          => master_read,
      master_write         => master_write,
      master_writedata     => master_writedata,
      master_byteenable    => master_byteenable,
      master_readdatavalid => master_readdatavalid,
      master_readdata      => master_readdata
      );
  master_adx <= current_dma_record.external_start(31 downto log2(MEMORY_WIDTH_BYTES)) &
                replicate_bit('0', log2(MEMORY_WIDTH_BYTES));
  
  read_waitrequest <= master_wait when current_dma_record.scratchpad_write = '1' else
                      dma_request_out_waitrequest;
  write_waitrequest <= dma_request_out_waitrequest when current_dma_record.scratchpad_write = '1' else
                       master_wait;

  decrement_rows   <= last_read_in_row;
  last_read_in_row <= last_ext_in_row when current_dma_record.scratchpad_write = '1'
                      else last_scratch_in_row;
  last_read <= last_read_in_row when current_dma_record.rows = to_unsigned(1, current_dma_record.rows'length)
               else '0';
  last_write_in_row <= last_scratch_in_row when current_dma_record.scratchpad_write = '1'
                       else last_ext_in_row;

  data_fifo_write <= readdatavalid;
  data_fifo_read  <= (master_wrreq or scratch_wrreq) and (not write_waitrequest);

  rdreq         <= master_rdreq           when current_dma_record.scratchpad_write = '1' else scratch_rdreq;
  readdatavalid <= buffered_readdatavalid when current_dma_record.scratchpad_write = '1' else
                   dma_request_out_readdatavalid;

  data_fifo_writedata <= buffered_readdata when current_dma_record.scratchpad_write = '1' else
                         scratchpad_data_to_byte8(dma_request_out_readdata)(data_fifo_writedata'range);

  dma_request_in_writedata((MEMORY_WIDTH_LANES*4)-1 downto 0) <=
    byte8_to_scratchpad_data(data_fifo_readdata, MEMORY_WIDTH_LANES);
  dma_request_in_byteena((MEMORY_WIDTH_LANES*4)-1 downto 0) <= write_byteenable;

  --FIXME: Can set data, flag to '-', check if causes simulation warnings
  multi_mem_widths : if VECTOR_MEMORY_WIDTHS > 1 generate
    dma_request_in_writedata(dma_request_in_writedata'left downto (MEMORY_WIDTH_LANES*4)) <=
      (others => (data => (others => '-'), flag => '-'));
    dma_request_in_byteena(dma_request_in_byteena'left downto (MEMORY_WIDTH_LANES*4)) <= (others => '0');
  end generate multi_mem_widths;

-- Main DMA State Machine
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if reset = '1' then               -- synchronous reset (active high)
        dma_state      <= IDLE;
        dma_queue_read <= '0';
      else
        case dma_state is
          when IDLE =>
            if current_dma_record.valid = '1' then
              dma_state <= TRANSFER;
            end if;
          when TRANSFER =>
            if last_read = '1' then
              dma_state <= FINISHING;
            end if;
          when FINISHING =>
            if all_done = '1' then
              dma_state      <= DONE;
              dma_queue_read <= '1';
            end if;
          when others =>
            dma_queue_read <= '0';
            dma_state      <= IDLE;
        end case;
      end if;
    end if;
  end process;
  next_dma_state_transfer <= '1' when ((dma_state = IDLE and current_dma_record.valid = '1') or
                                       (dma_state = TRANSFER and last_read = '0'))
                             else '0';

  lt2_outstanding_reads <= '1' when (outstanding_reads(outstanding_reads'left downto 1) =
                                     to_unsigned(0, outstanding_reads'length-1))
                           else '0';
  all_done <= '1' when (lt2_outstanding_reads = '1' and outstanding_reads(0) = '0' and
                        (data_fifo_rdempty = '1') and
                        (data_fifo_rdusedw(0) = '0') and
                        (master_buffer_empty = '1')) else
              '0';

  outstanding_reads_case <= (rdreq and (not read_waitrequest)) & data_fifo_read;
  with outstanding_reads_case select
    next_outstanding_reads <=
    outstanding_reads + 1 when "10",
    outstanding_reads - 1 when "01",
    outstanding_reads     when others;
  next_room_in_the_queue <=
    '1' when next_outstanding_reads < to_unsigned(DMA_DATA_FIFO_DEPTH-BURSTCOUNT_WORDS, DMA_DATA_FIFO_BITS) else '0';

  --Count outstanding reads
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      outstanding_reads <= next_outstanding_reads;
      room_in_the_queue <= next_room_in_the_queue;

      if reset = '1' then               -- synchronous reset (active high)
        outstanding_reads <= to_unsigned(0, DMA_DATA_FIFO_BITS);
        room_in_the_queue <= '0';
      end if;
    end if;
  end process;

  data_fifo : scfifo
    generic map (
      add_ram_output_register => "OFF",
      intended_device_family  => "Cyclone II",
      lpm_numwords            => DMA_DATA_FIFO_DEPTH,
      lpm_showahead           => "ON",
      lpm_type                => "scfifo",
      lpm_width               => MEMORY_WIDTH_BITS,
      lpm_widthu              => DMA_DATA_FIFO_BITS,
      overflow_checking       => "OFF",
      underflow_checking      => "OFF",
      use_eab                 => "ON"
      )
    port map (
      clock => clk,
      sclr  => reset,
      wrreq => data_fifo_write,
      data  => data_fifo_writedata,
      rdreq => data_fifo_read,
      usedw => data_fifo_rdusedw,
      empty => data_fifo_rdempty,
      full  => data_fifo_wrfull,
      q     => data_fifo_readdata
      );
end architecture rtl;
