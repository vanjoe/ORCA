
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library std;
use std.textio.all;

entity uart_rx_tb is

  generic (
    BAUD_RATE   : integer := 115200;
    OUTPUT_FILE : string  := "uart.out");

  port (
    rxd : in std_logic);

end entity uart_rx_tb;

architecture behavioral of uart_rx_tb is
  constant DELAY_US_1_5_BIT : integer := 8625*3/2;
  constant DELAY_US_1_0_BIT : integer := 8625;
  constant DELAY_US_0_5_BIT : integer := 8625/2;

begin  -- architecture behavioral

  process is
    variable uart_byte :std_logic_vector(7 downto 0);
    file      outfile  : text;
    variable f_status: FILE_OPEN_STATUS;
    variable  outline  : line;
    variable out_chr : character;
    variable out_str : string(1 downto 1);
  begin  -- process
    wait until rxd = '0';
    uart_byte := (others => '-');
    wait for DELAY_US_1_5_BIT* 1 ns;
    uart_byte(0) := rxd;
    wait for DELAY_US_1_0_BIT* 1 ns;
    uart_byte(1) := rxd;
    wait for DELAY_US_1_0_BIT *1 ns;
    uart_byte(2) := rxd;
    wait for DELAY_US_1_0_BIT *1 ns;
    uart_byte(3) := rxd;
    wait for DELAY_US_1_0_BIT *1 ns;
    uart_byte(4) := rxd;
    wait for DELAY_US_1_0_BIT *1 ns;
    uart_byte(5) := rxd;
    wait for DELAY_US_1_0_BIT *1 ns;
    uart_byte(6) := rxd;
    wait for DELAY_US_1_0_BIT *1 ns;
    uart_byte(7) := rxd;
    wait for DELAY_US_1_0_BIT *1 ns;

    --newline
    file_open(f_status,outfile, OUTPUT_FILE,append_mode);
    out_chr := character'val(to_integer(unsigned(uart_byte)));
    out_str(1) := out_chr;

    write(outfile,out_str);
    file_close(outfile);
  end process;

end architecture behavioral;
