library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity plic is
  generic (
    REGISTER_SIZE : integer := 32;
    NUM_EXT_INTERRUPTS : natural range 2 to 32 := 2);
  port (
    mtime_o : out std_logic_vector(63 downto 0);
    mip_mtip_o : out std_logic;
    mip_msip_o : out std_logic;
    mip_meip_o : out std_logic;
  
    -- External interrupts
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
  signal mip_meip_reg   : std_logic;
  
  -- 0 denotes level sensitive external interrupt, 1 denotes edge sensitive external interrupt.
  signal edge_sensitive_vector     : std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0);
  -- Holds the one-hot ID of the highest priority pending interrupt 
  -- (arbitrated on priority, then ID).
  signal interrupt_claim           : std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0);
  -- Tells the gateway which interrupt was claimed this cycle (if one was).
  signal interrupt_claimed         : std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0);
  -- Tells the gateway which interrupt was completed this cycle (if one was).
  signal interrupt_complete        : std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0);
  -- Signal from the gateway that an interrupt is pending.
  signal pending_interrupts        : std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0);

  signal byteen_3  : std_logic_vector(7 downto 0);
  signal byteen_2  : std_logic_vector(7 downto 0);
  signal byteen_1  : std_logic_vector(7 downto 0);
  signal byteen_0  : std_logic_vector(7 downto 0);
  signal writedata : std_logic_vector(31 downto 0);

  -- The interrupt register lables.
  constant MTIMECMP_L       : std_logic_vector(7 downto 0) := X"00";
  constant MTIMECMP_H       : std_logic_vector(7 downto 0) := X"04"; 
  constant MSOFTWARE_I      : std_logic_vector(7 downto 0) := X"08";
  constant EDGE_SENS_VECTOR : std_logic_vector(7 downto 0) := X"0C";
  constant INTRPT_CLAIM     : std_logic_vector(7 downto 0) := X"10";         
  constant INTRPT_COMPLETE  : std_logic_vector(7 downto 0) := X"14";

  -- A constant representing zero interrupts pending.
  constant ZERO : std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0) := (others => '0');

begin
  -- This is the gateway that converts edge or level sensitive external interrupts into
  -- interrupt requests for the PLIC. 
  interrupt_gateway : component gateway
    generic map (
      NUM_EXT_INTERRUPTS => NUM_EXT_INTERRUPTS)
    port map (
      clk => clk,
      reset => reset,
      global_interrupts => global_interrupts,
      edge_sensitive_vector => edge_sensitive_vector,
      interrupt_claimed => interrupt_claimed,
      interrupt_complete => interrupt_complete,
      pending_interrupts => pending_interrupts); 
  
  -- Interrupt pending signals
  mtime_o <= mtime_reg;
  mip_mtip_o <= mip_mtip_reg;
  mip_msip_o <= mip_msip_reg;
  mip_meip_o <= mip_meip_reg;

  -- Data write/read signals
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
      if (unsigned(mtime_reg) + to_unsigned(1, 64) 
        >= unsigned(mtimecmp_h_reg & mtimecmp_l_reg)) then
        mip_mtip_reg <= '1';
      end if;

      -- Handle triggering the external interrupt pending.
      if interrupt_claim /= ZERO then
        mip_meip_reg <= '1';
      else 
        mip_meip_reg <= '0';
      end if;

      -- Default values for the readdata lines.
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
        edge_sensitive_vector <= (others => '0');
        interrupt_complete <= (others => '0');
        interrupt_claimed <= (others => '0');
      else
        -- interrupt_complete should be zero in all cycles except when an interrupt
        -- has just been handled.
        interrupt_complete <= (others => '0');
        -- interrupt_claimed should be zero in all cycles except when an interrupt
        -- has just been claimed.
        interrupt_claimed <= (others => '0');

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
              mtimecmp_h_reg <= writedata;
            -- Writes to the MSOFTWARE_I register induce a pending software interrupt.
            when MSOFTWARE_I =>
              mip_msip_reg <= '1';                           
            when EDGE_SENS_VECTOR =>
              edge_sensitive_vector <= writedata(NUM_EXT_INTERRUPTS-1 downto 0);
            when INTRPT_CLAIM =>
              -- Not a writeable register, read only.
            when INTRPT_COMPLETE =>
              -- This write will allow the gateway to forward another interrupt
              -- on the lines specified in writedata.
              for i in 0 to NUM_EXT_INTERRUPTS-1 loop
                if writedata = std_logic_vector(to_unsigned(i, 32)) then
                  interrupt_complete <= (i => '1', others => '0');
                end if;
              end loop;
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
            when EDGE_SENS_VECTOR =>
              plic_readdata <= (others => '0');
              plic_readdata(edge_sensitive_vector'range) <= edge_sensitive_vector;
            when INTRPT_CLAIM =>
              -- Convert one-hot interrupt_claim to binary plic_readdata.
              for i in 0 to NUM_EXT_INTERRUPTS-1 loop
                if (interrupt_claim(i) = '1') then
                  plic_readdata <= std_logic_vector(to_unsigned(i, REGISTER_SIZE));
                end if; 
              end loop;  
              -- Signal to the gateway that the highest priority pending interrupt has 
              -- been claimed.
              interrupt_claimed <= interrupt_claim;
            when INTRPT_COMPLETE =>
              -- Return nothing, write only register.
              plic_readdata <= (others => '0');
            when others =>
          end case;
        end if;

      end if;
    end if;
  end process;


  -- Interrupt claim arbitration, for now, just on IDs. Lowest ID is the
  -- highest priority interrupt.
  interrupt_claim_process : process (clk)
  begin
    if rising_edge(clk) then
      -- 0 has the highest priority, start at NUM_EXT_INTERRUPTS-1 in the process
      -- to achieve correct arbitration.
      interrupt_claim <= (others => '0');
      for i in NUM_EXT_INTERRUPTS-1 downto 0 loop
        if pending_interrupts(i) = '1' then
          interrupt_claim <= (others => '0');
          interrupt_claim(i) <= '1';
        end if;
      end loop; 
    end if;
  end process;

end architecture rtl;
