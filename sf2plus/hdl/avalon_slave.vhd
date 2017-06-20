-- avalon_slave.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;
use work.isa_pkg.all;
use work.architecture_pkg.all;

entity avalon_slave is
  generic (
    VECTOR_LANES : integer := 1;

    ADDR_WIDTH : integer := 1
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    slave_request_out : in  std_logic_vector(scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    slave_request_in  : out std_logic_vector(scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

    slave_address       : in  std_logic_vector(ADDR_WIDTH-3 downto 0);
    slave_read          : in  std_logic;
    slave_write         : in  std_logic;
    slave_waitrequest   : out std_logic;
    slave_readdatavalid : out std_logic;

    slave_writedata  : in  std_logic_vector(31 downto 0);
    slave_byteenable : in  std_logic_vector(3 downto 0);
    slave_readdata   : out std_logic_vector(31 downto 0)
    );
end entity avalon_slave;

architecture rtl of avalon_slave is
  signal slave_request_in_rd        : std_logic;
  signal slave_request_in_wr        : std_logic;
  signal slave_request_in_addr      : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal slave_request_in_writedata : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal slave_request_in_byteena   : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
begin
  slave_request_in_rd                    <= slave_read;
  slave_request_in_wr                    <= slave_write;
  slave_request_in_addr                  <= slave_address(ADDR_WIDTH-3 downto 0) & "00";
  slave_request_in_writedata(3 downto 0) <= byte8_to_scratchpad_data(slave_writedata, 1);
  slave_request_in_byteena(3 downto 0)   <= slave_byteenable(3 downto 0);
  slave_request_in <= scratchpad_request_in_flatten(slave_request_in_rd,
                                                    slave_request_in_wr,
                                                    slave_request_in_addr,
                                                    slave_request_in_writedata,
                                                    slave_request_in_byteena);

  slave_waitrequest   <= scratchpad_request_out_get(slave_request_out, REQUEST_OUT_WAITREQUEST, VECTOR_LANES, ADDR_WIDTH)(0);
  slave_readdatavalid <= scratchpad_request_out_get(slave_request_out, REQUEST_OUT_READDATAVALID, VECTOR_LANES, ADDR_WIDTH)(0);
  slave_readdata      <=
    scratchpad_data_to_byte8(byte9_to_scratchpad_data(scratchpad_request_out_get(slave_request_out, REQUEST_OUT_READDATA, VECTOR_LANES, ADDR_WIDTH)))(31 downto 0);

  multi_lane_gen : if VECTOR_LANES > 1 generate
    slave_request_in_byteena(slave_request_in_byteena'left downto 4)     <= (others => '0');
    slave_request_in_writedata(slave_request_in_writedata'left downto 4) <=
      (others => (data => (others => '0'), flag => '0'));
  end generate multi_lane_gen;

end architecture rtl;
