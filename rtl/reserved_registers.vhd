library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reserved_registers is
  generic (REGISTER_SIZE : integer := 32);
  port (
    mtime_o : out std_logic_vector(63 downto 0);
    mtimecmp_o : out std_logic_vector(63 downto 0);
    mip_mtip_o : out std_logic;
    
    -- Avalon bus
    clk : in std_logic;
    reset : in std_logic;
    reserved_address : in std_logic_vector(7 downto 0);
    reserved_byteenable : in std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    reserved_read : in std_logic;
    reserved_readdata : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    reserved_response : out std_logic_vector(1 downto 0);
    reserved_write : in std_logic;
    reserved_writedata : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    reserved_lock : in std_logic;
    reserved_waitrequest : out std_logic;
    reserved_readdatavalid : out std_logic);
end entity reserved_registers;

architecture rtl of reserved_registers is
  signal mtime_reg : std_logic_vector(63 downto 0);
  signal mtimecmp_l_reg : std_logic_vector(31 downto 0);
  signal mtimecmp_h_reg : std_logic_vector(31 downto 0);
  signal mip_mtip_reg   : std_logic; 

  signal byteen_3 : std_logic_vector(7 downto 0);
  signal byteen_2 : std_logic_vector(7 downto 0);
  signal byteen_1 : std_logic_vector(7 downto 0);
  signal byteen_0 : std_logic_vector(7 downto 0);


  constant MTIMECMP_L : std_logic_vector(7 downto 0) := X"00";
  constant MTIMECMP_H : std_logic_vector(7 downto 0) := X"01"; 

begin
  
  mtime_o <= mtime_reg;
  mtimecmp_o <= mtimecmp_h_reg & mtimecmp_l_reg;
  mip_mtip_o <= mip_mtip_reg;

  mtimecmp_waitrequest <= '0';
  mtimecmp_response <= "00";

  byteen_3 <= (others => mtimecmp_byteenable(3)); 
  byteen_2 <= (others => mtimecmp_byteenable(2)); 
  byteen_1 <= (others => mtimecmp_byteenable(1)); 
  byteen_0 <= (others => mtimecmp_byteenable(0)); 

  process (clk)
  begin
    if rising_edge(clk) then
      mtime_reg <= std_logic_vector(unsigned(mtime_reg) + to_unsigned(1, 64));
      if (std_logic_vector(unsigned(mtime_reg) + to_unsigned(1, 64)) 
          = mtimecmp_h_reg & mtimecmp_l_reg) then
        mip_mtip_reg <= '1';
      end if;

      mtimecmp_readdatavalid <= '0';
      mtimecmp_readdata <= (others => '0');

      if (reset = '1') then
        mtime_reg <= (others => '0');
        mtimecmp_h_reg <= (others => '0');
        mtimecmp_l_reg <= (others => '0');
        mip_mtip_reg <= '0';
      else

        if (mtimecmp_write = '1') then
          if (mtimecmp_address = MTIMECMP_L) then
            if (mip_mtip_reg = '1') then
              mip_mtip_reg <= '0';
            end if;
            mtimecmp_l_reg <= 
              mtimecmp_writedata(31 downto 24) and byteen_3 &
              mtimecmp_writedata(23 downto 16) and byteen_2 &
              mtimecmp_writedata(15 downto  8) and byteen_1 &
              mtimecmp_writedata( 7 downto  0) and byteen_0; 
          elsif (mtimecmp_address = MTIMECMP_H) then
            if (mip_mtip_reg = '1') then
              mip_mtip_reg <= '0';
            end if;
            mtimecmp_h_reg <= 
              mtimecmp_writedata(31 downto 24) and byteen_3 &
              mtimecmp_writedata(23 downto 16) and byteen_2 &
              mtimecmp_writedata(15 downto  8) and byteen_1 &
              mtimecmp_writedata( 7 downto  0) and byteen_0; 
          end if;

        elsif (mtimecmp_read = '1') then
          mtimecmp_readdatavalid <= '1';
          if (mtimecmp_address = MTIMECMP_L) then
            mtimecmp_readdata <= mtimecmp_l_reg; 
          elsif (mtimecmp_address = MTIMECMP_H) then
           mtimecmp_readdata <= mtimecmp_h_reg;
          end if;
        end if;

      end if;
    end if;
  end process;
end architecture rtl;



