-- avalon_buffer.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.util_pkg.all;

entity avalon_buffer is
  generic (
    ADDR_WIDTH       : integer  := 27;
    MEM_WIDTH_BYTES  : integer  := 4;
    BURSTCOUNT_BITS  : positive := 1;
    MULTI_READ_BURST : boolean  := false;
    BUFFER_READDATA  : boolean  := true
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    empty : out std_logic;

    slave_waitrequest   : out std_logic;
    slave_address       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    slave_burstcount    : in  std_logic_vector(BURSTCOUNT_BITS-1 downto 0);
    slave_read          : in  std_logic;
    slave_write         : in  std_logic;
    slave_writedata     : in  std_logic_vector(MEM_WIDTH_BYTES*8-1 downto 0);
    slave_byteenable    : in  std_logic_vector(MEM_WIDTH_BYTES-1 downto 0);
    slave_readdatavalid : out std_logic;
    slave_readdata      : out std_logic_vector(MEM_WIDTH_BYTES*8-1 downto 0);

    master_waitrequest   : in  std_logic;
    master_address       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    master_burstcount    : out std_logic_vector(BURSTCOUNT_BITS-1 downto 0);
    master_read          : out std_logic;
    master_write         : out std_logic;
    master_writedata     : out std_logic_vector(MEM_WIDTH_BYTES*8-1 downto 0);
    master_byteenable    : out std_logic_vector(MEM_WIDTH_BYTES-1 downto 0);
    master_readdatavalid : in  std_logic;
    master_readdata      : in  std_logic_vector(MEM_WIDTH_BYTES*8-1 downto 0)
    );
end avalon_buffer;


architecture syn of avalon_buffer is
  signal head_valid      : std_logic;
  signal head_address    : std_logic_vector(ADDR_WIDTH-1 downto 0)        := (others => '0');
  signal head_burstcount : std_logic_vector(BURSTCOUNT_BITS-1 downto 0)   := (others => '0');
  signal head_read       : std_logic;
  signal head_write      : std_logic;
  signal head_writedata  : std_logic_vector(MEM_WIDTH_BYTES*8-1 downto 0) := (others => '0');
  signal head_byteenable : std_logic_vector(MEM_WIDTH_BYTES-1 downto 0)   := (others => '0');

  signal tail_valid      : std_logic;
  signal tail_address    : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal tail_burstcount : std_logic_vector(BURSTCOUNT_BITS-1 downto 0);
  signal tail_read       : std_logic;
  signal tail_write      : std_logic;
  signal tail_writedata  : std_logic_vector(MEM_WIDTH_BYTES*8-1 downto 0);
  signal tail_byteenable : std_logic_vector(MEM_WIDTH_BYTES-1 downto 0);

  signal wrreq : std_logic;
  signal rdreq : std_logic;

  signal burst_accesses_left : unsigned(BURSTCOUNT_BITS-1 downto 0);
  signal first_of_burst      : std_logic;
begin
  empty <= not head_valid;              --tail is valid only if head is valid

  readdata_buffer_gen : if BUFFER_READDATA = true generate
    process (clk)
    begin  -- process
      if clk'event and clk = '1' then   -- rising clock edge
        slave_readdatavalid <= master_readdatavalid;
        slave_readdata      <= master_readdata;
      end if;
    end process;
  end generate readdata_buffer_gen;
  no_readdata_buffer_gen : if BUFFER_READDATA = false generate
    slave_readdatavalid <= master_readdatavalid;
    slave_readdata      <= master_readdata;
  end generate no_readdata_buffer_gen;

  multi_read_gen : if MULTI_READ_BURST generate
    wrreq <= ((slave_read and first_of_burst) or slave_write) and (not tail_valid);
  end generate multi_read_gen;
  single_read_gen : if (not MULTI_READ_BURST) generate
    wrreq <= (slave_read or slave_write) and (not tail_valid);
  end generate single_read_gen;
  rdreq <= head_valid and (not master_waitrequest);

  master_address    <= head_address;
  master_burstcount <= head_burstcount;
  master_read       <= head_read;
  master_write      <= head_write;
  master_writedata  <= head_writedata;
  master_byteenable <= head_byteenable;
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if tail_valid = '0' then
        slave_waitrequest <= '0';       --For coming out of reset
      end if;

      if wrreq = '1' then
        tail_address    <= slave_address;
        tail_burstcount <= slave_burstcount;
        tail_read       <= slave_read;
        tail_write      <= slave_write;
        tail_writedata  <= slave_writedata;
        tail_byteenable <= slave_byteenable;

        if rdreq = '1' or head_valid = '0' then
          head_valid      <= '1';
          head_address    <= slave_address;
          head_burstcount <= slave_burstcount;
          head_read       <= slave_read;
          head_write      <= slave_write;
          head_writedata  <= slave_writedata;
          head_byteenable <= slave_byteenable;
        else
          tail_valid        <= '1';
          slave_waitrequest <= '1';
        end if;
      elsif rdreq = '1' then
        if tail_valid = '1' then
          tail_valid        <= '0';
          slave_waitrequest <= '0';
          head_read         <= tail_read;
          head_write        <= tail_write;
        else
          head_valid <= '0';
          head_read  <= '0';
          head_write <= '0';
        end if;
        head_address    <= tail_address;
        head_burstcount <= tail_burstcount;
        head_writedata  <= tail_writedata;
        head_byteenable <= tail_byteenable;
      end if;

      if reset = '1' then               -- synchronous reset (active high)
        head_valid        <= '0';
        head_read         <= '0';
        head_write        <= '0';
        tail_valid        <= '0';
        slave_waitrequest <= '1';
      end if;
    end if;
  end process;

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if tail_valid = '0' then
        if (slave_read = '1' or slave_write = '1') then
          if first_of_burst = '1' then
            first_of_burst      <= '0';
            burst_accesses_left <= unsigned(slave_burstcount) - 1;
            if unsigned(slave_burstcount) = to_unsigned(1, slave_burstcount'length) then
              first_of_burst <= '1';
            end if;
          else
            burst_accesses_left <= burst_accesses_left - 1;
            if burst_accesses_left = to_unsigned(1, burst_accesses_left'length) then
              first_of_burst <= '1';
            end if;
          end if;
        end if;
      end if;

      if reset = '1' then               -- synchronous reset (active high)
        burst_accesses_left <= to_unsigned(0, burst_accesses_left'length);
        first_of_burst      <= '1';
      end if;
    end if;
  end process;
end syn;
