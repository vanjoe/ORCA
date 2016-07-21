library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity long_load_store is

  generic (REGISTER_SIZE : integer := 32);

  port (clk : in std_logic;
        reset : in std_logic;
        avm_address : in std_logic_vector(7 downto 0);
        avm_byteenable : in std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
        avm_read : in std_logic;
        avm_readdata : out std_logic_vector(REGISTER_SIZE-1 downto 0);
        avm_response : out std_logic_vector(1 downto 0);
        avm_write : in std_logic;
        avm_writedata : in std_logic_vector(REGISTER_SIZE-1 downto 0);
        avm_lock : in std_logic;
        avm_waitrequest : out std_logic;
        avm_readdatavalid : out std_logic);


end entity long_load_store;

architecture rtl of long_load_store is
  type state_t is (START,
                   READ_0,
                   READ_1,
                   READ_2,
                   WRITE_0,
                   WRITE_1,
                   WRITE_2);

  type ram_t is array (255 downto 0) of std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal state : state_t;
  signal read_done : std_logic;
  signal write_done : std_logic;
  signal ram : ram_t;
  signal address_reg : std_logic_vector(7 downto 0);

begin

  avm_waitrequest <= (avm_read and (not read_done)) or (avm_write and (not write_done));

  process (clk)
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        state <= START;
        avm_readdata <= (others => '0');
        avm_response <= (others => '0');
        avm_readdatavalid <= '0';
        read_done <= '0';
        write_done <= '0';
      else
        avm_readdata <= (others => '0');
        avm_response <= (others => '0');
        avm_readdatavalid <= '0';
        read_done <= '0';
        write_done <= '0';
        case (state) is
          
          when START =>
            if (avm_read = '1') then
              state <= READ_0;
              address_reg <= avm_address;
            elsif (avm_write = '1') then
              state <= WRITE_0;
              address_reg <= avm_address;
            end if;

          when READ_0 => -- stall state
            state <= READ_1;

          when READ_1 =>
            read_done <= '1';
            state <= READ_2;

          when READ_2 =>
            avm_readdata <= ram(to_integer(unsigned(address_reg)));
            avm_readdatavalid <= '1';
            avm_response <= "00";
            state <= START;

          when WRITE_0 => -- stall state
            state <= WRITE_1;
            
          when WRITE_1 =>
            ram(to_integer(unsigned(address_reg))) <= avm_writedata;
            write_done <= '1';
            state <= WRITE_2;
            
          when WRITE_2 =>
            state <= START; 

          when others =>
            state <= START;
                        
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
