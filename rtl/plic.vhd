library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity plic is
  generic (REGISTER_SIZE : integer := 32;
           NUM_EXT_INTERRUPTS : integer range 2 to 32 := 2);
  port (
    mtime_o : out std_logic_vector(63 downto 0);
    mip_mtip_o : out std_logic;
    mip_msip_o : out std_logic;

    global_interrupts : in std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0);
    
    -- Avalon bus
    clk : in std_logic;
    reset : in std_logic;
    plic_address : in std_logic_vector(7 downto 0);
    plic_byteenable : in std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    plic_read : in std_logic;
    plic_readdata : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    plic_response : out std_logic_vector(1 downto 0);
    plic_write : in std_logic;
    plic_writedata : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    plic_lock : in std_logic;
    plic_waitrequest : out std_logic;
    plic_readdatavalid : out std_logic);
end entity plic;

architecture rtl of plic is
  signal mtime_reg : std_logic_vector(63 downto 0);
  signal mtimecmp_l_reg : std_logic_vector(31 downto 0);
  signal mtimecmp_h_reg : std_logic_vector(31 downto 0);
  signal mip_mtip_reg   : std_logic; 

  signal mip_msip_reg   : std_logic;

  signal byteen_3  : std_logic_vector(7 downto 0);
  signal byteen_2  : std_logic_vector(7 downto 0);
  signal byteen_1  : std_logic_vector(7 downto 0);
  signal byteen_0  : std_logic_vector(7 downto 0);
  signal writedata : std_logic_vector(31 downto 0);


  constant MTIMECMP_L  : std_logic_vector(7 downto 0) := X"00";
  constant MTIMECMP_H  : std_logic_vector(7 downto 0) := X"04"; 
  constant MSOFTWARE_I : std_logic_vector(7 downto 0) := X"08";

begin
  
  mtime_o <= mtime_reg;
  mip_mtip_o <= mip_mtip_reg;
  mip_msip_o <= mip_msip_reg;

  plic_waitrequest <= '0';
  plic_response <= "00";

  byteen_3 <= (others => plic_byteenable(3)); 
  byteen_2 <= (others => plic_byteenable(2)); 
  byteen_1 <= (others => plic_byteenable(1)); 
  byteen_0 <= (others => plic_byteenable(0)); 

  writedata <= (plic_writedata(31 downto 24) and byteen_3) &
               (plic_writedata(23 downto 16) and byteen_2) &
               (plic_writedata(15 downto  8) and byteen_1) &
               (plic_writedata( 7 downto  0) and byteen_0); 


  process (clk)
  begin
    if rising_edge(clk) then
      -- Handle triggering the timer interrupt pending.
      mtime_reg <= std_logic_vector(unsigned(mtime_reg) + to_unsigned(1, 64));
      if (unsigned(mtime_reg) + to_unsigned(1, 64) >= unsigned(mtimecmp_h_reg & mtimecmp_l_reg)) then
        mip_mtip_reg <= '1';
      end if;

      plic_readdatavalid <= '0';
      plic_readdata <= (others => '0');

      if (reset = '1') then
        mtime_reg <= (others => '0');
        -- mtimecmp_reg gets all '1's to prevent timer interrupts from happening right when 
        -- they get enabled.
        mtimecmp_h_reg <= (others => '1');
        mtimecmp_l_reg <= (others => '1');
        mip_mtip_reg <= '0';
        mip_msip_reg <= '0';
      else
        if (plic_write = '1') then
          case (plic_address) is
            -- Writes to the MTIMECMP registers clear the pending interrupt.
            when MTIMECMP_L =>
              if (mip_mtip_reg = '1') then
                mip_mtip_reg <= '0';
              end if;
              mtimecmp_l_reg <= writedata;
            when MTIMECMP_H =>
              if (mip_mtip_reg = '1') then
                mip_mtip_reg <= '0';
              end if;
              mtimecmp_h_reg <=  writedata;
            -- Writes to the MSOFTWARE_I register induce a pending software interrupt.
            when MSOFTWARE_I =>
              mip_msip_reg <= '1';                           
            when others =>
          end case;

        elsif (plic_read = '1') then
          plic_readdatavalid <= '1';
          case (plic_address) is
            when MTIMECMP_L =>
              plic_readdata <= mtimecmp_l_reg;
            when MTIMECMP_H =>
              plic_readdata <= mtimecmp_h_reg;
            -- Reads from the MSOFTWARE_I register clear a pending software interrupt. 
            when MSOFTWARE_I =>
              mip_msip_reg <= '0';
              plic_readdata <= (others => '0');
            when others =>
          end case;
        end if;

      end if;
    end if;
  end process;
end architecture rtl;



