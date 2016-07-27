library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity plic is
  generic (REGISTER_SIZE : integer := 32);
  port (
    mtime_o : out std_logic_vector(63 downto 0);
    mip_mtip_o : out std_logic;
    mip_msip_o : out std_logic;
    mip_meip_o : out std_logic;
  
    -- External interrupts
    global_interrupts : in std_logic_vector(31 downto 0);
    
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
  signal edge_sensitive_vector     : std_logic_vector(31 downto 0);
  -- Holds the one-hot ID of the highest priority pending interrupt 
  -- (arbitrated on priority, then ID).
  signal interrupt_claim           : std_logic_vector(31 downto 0);
  -- Tells the gateway which interrupt was claimed this cycle (if one was).
  signal interrupt_claimed         : std_logic_vector(31 downto 0);
  -- Tells the gateway which interrupt was completed this cycle (if one was).
  signal interrupt_complete        : std_logic_vector(31 downto 0);
  -- Signal from the gateway that an interrupt is pending.
  signal pending_interrupts        : std_logic_vector(31 downto 0);

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

begin
  -- This is the gateway that converts edge or level sensitive external interrupts into
  -- interrupt requests for the PLIC. 
  interrupt_gateway : component gateway
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
      mip_meip_reg <= interrupt_claim(0)  or interrupt_claim(1)  or
                      interrupt_claim(2)  or interrupt_claim(3)  or 
                      interrupt_claim(4)  or interrupt_claim(5)  or 
                      interrupt_claim(6)  or interrupt_claim(7)  or 
                      interrupt_claim(8)  or interrupt_claim(9)  or 
                      interrupt_claim(10) or interrupt_claim(11) or 
                      interrupt_claim(12) or interrupt_claim(13) or 
                      interrupt_claim(14) or interrupt_claim(15) or 
                      interrupt_claim(16) or interrupt_claim(17) or 
                      interrupt_claim(18) or interrupt_claim(19) or 
                      interrupt_claim(20) or interrupt_claim(21) or 
                      interrupt_claim(22) or interrupt_claim(23) or 
                      interrupt_claim(24) or interrupt_claim(25) or 
                      interrupt_claim(26) or interrupt_claim(27) or 
                      interrupt_claim(28) or interrupt_claim(29) or 
                      interrupt_claim(30) or interrupt_claim(31);

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
              edge_sensitive_vector <= writedata;
            when INTRPT_CLAIM =>
              -- Not a writeable register, read only.
            when INTRPT_COMPLETE =>
              -- This write will allow the gateway to forward another interrupt
              -- on the lines specified in writedata.
              case (writedata) is
                when X"00000000" => interrupt_complete <= X"00000001"; 
                when X"00000001" => interrupt_complete <= X"00000002";
                when X"00000002" => interrupt_complete <= X"00000004";
                when X"00000003" => interrupt_complete <= X"00000008";
                when X"00000004" => interrupt_complete <= X"00000010";
                when X"00000005" => interrupt_complete <= X"00000020";
                when X"00000006" => interrupt_complete <= X"00000040";
                when X"00000007" => interrupt_complete <= X"00000080";
                when X"00000008" => interrupt_complete <= X"00000100";
                when X"00000009" => interrupt_complete <= X"00000200";
                when X"0000000A" => interrupt_complete <= X"00000400";
                when X"0000000B" => interrupt_complete <= X"00000800";
                when X"0000000C" => interrupt_complete <= X"00001000";
                when X"0000000D" => interrupt_complete <= X"00002000";
                when X"0000000E" => interrupt_complete <= X"00004000";
                when X"0000000F" => interrupt_complete <= X"00008000";
                when X"00000010" => interrupt_complete <= X"00010000";
                when X"00000011" => interrupt_complete <= X"00020000";
                when X"00000012" => interrupt_complete <= X"00040000";
                when X"00000013" => interrupt_complete <= X"00088000";
                when X"00000014" => interrupt_complete <= X"00100000";
                when X"00000015" => interrupt_complete <= X"00200000";
                when X"00000016" => interrupt_complete <= X"00400000";
                when X"00000017" => interrupt_complete <= X"00800000";
                when X"00000018" => interrupt_complete <= X"01000000";
                when X"00000019" => interrupt_complete <= X"02000000";
                when X"0000001A" => interrupt_complete <= X"04000000";
                when X"0000001B" => interrupt_complete <= X"08000000";
                when X"0000001C" => interrupt_complete <= X"10000000";
                when X"0000001D" => interrupt_complete <= X"20000000";
                when X"0000001E" => interrupt_complete <= X"40000000";
                when X"0000001F" => interrupt_complete <= X"80000000";
                when others      => interrupt_complete <= X"00000000";
              end case;

--              interrupt_complete <= X"00000001" when writedata = X"00000000" else
--                                    X"00000002" when writedata = X"00000001" else
--                                    X"00000004" when writedata = X"00000002" else
--                                    X"00000008" when writedata = X"00000003" else
--                                    X"00000010" when writedata = X"00000004" else
--                                    X"00000020" when writedata = X"00000005" else
--                                    X"00000040" when writedata = X"00000006" else
--                                    X"00000080" when writedata = X"00000007" else
--                                    X"00000100" when writedata = X"00000008" else
--                                    X"00000200" when writedata = X"00000009" else
--                                    X"00000400" when writedata = X"0000000A" else
--                                    X"00000800" when writedata = X"0000000B" else
--                                    X"00001000" when writedata = X"0000000C" else
--                                    X"00002000" when writedata = X"0000000D" else
--                                    X"00004000" when writedata = X"0000000E" else
--                                    X"00008000" when writedata = X"0000000F" else
--                                    X"00010000" when writedata = X"00000010" else
--                                    X"00020000" when writedata = X"00000011" else
--                                    X"00040000" when writedata = X"00000012" else
--                                    X"00088000" when writedata = X"00000013" else
--                                    X"00100000" when writedata = X"00000014" else
--                                    X"00200000" when writedata = X"00000015" else
--                                    X"00400000" when writedata = X"00000016" else
--                                    X"00800000" when writedata = X"00000017" else
--                                    X"01000000" when writedata = X"00000018" else
--                                    X"02000000" when writedata = X"00000019" else
--                                    X"04000000" when writedata = X"0000001A" else
--                                    X"08000000" when writedata = X"0000001B" else
--                                    X"10000000" when writedata = X"0000001C" else
--                                    X"20000000" when writedata = X"0000001D" else
--                                    X"40000000" when writedata = X"0000001E" else
--                                    X"80000000" when writedata = X"0000001F" else
--                                    X"00000000";
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
              plic_readdata <= edge_sensitive_vector;
            when INTRPT_CLAIM =>
              -- Convert one-hot interrupt_claim to binary plic_readdata.
              case (interrupt_claim) is
                when X"00000001" => plic_readdata <= X"00000000"; 
                when X"00000002" => plic_readdata <= X"00000001";
                when X"00000004" => plic_readdata <= X"00000002";
                when X"00000008" => plic_readdata <= X"00000003";
                when X"00000010" => plic_readdata <= X"00000004";
                when X"00000020" => plic_readdata <= X"00000005";
                when X"00000040" => plic_readdata <= X"00000006";
                when X"00000080" => plic_readdata <= X"00000007";
                when X"00000100" => plic_readdata <= X"00000008";
                when X"00000200" => plic_readdata <= X"00000009";
                when X"00000400" => plic_readdata <= X"0000000A";
                when X"00000800" => plic_readdata <= X"0000000B";
                when X"00001000" => plic_readdata <= X"0000000C";
                when X"00002000" => plic_readdata <= X"0000000D";
                when X"00004000" => plic_readdata <= X"0000000E";
                when X"00008000" => plic_readdata <= X"0000000F";
                when X"00010000" => plic_readdata <= X"00000010";
                when X"00020000" => plic_readdata <= X"00000011";
                when X"00040000" => plic_readdata <= X"00000012";
                when X"00088000" => plic_readdata <= X"00000013";
                when X"00100000" => plic_readdata <= X"00000014";
                when X"00200000" => plic_readdata <= X"00000015";
                when X"00400000" => plic_readdata <= X"00000016";
                when X"00800000" => plic_readdata <= X"00000017";
                when X"01000000" => plic_readdata <= X"00000018";
                when X"02000000" => plic_readdata <= X"00000019";
                when X"04000000" => plic_readdata <= X"0000001A";
                when X"08000000" => plic_readdata <= X"0000001B";
                when X"10000000" => plic_readdata <= X"0000001C";
                when X"20000000" => plic_readdata <= X"0000001D";
                when X"40000000" => plic_readdata <= X"0000001E";
                when X"80000000" => plic_readdata <= X"0000001F";
                when others      => plic_readdata <= X"00000000";
              end case;
--              plic_readdata <= X"00000000" when interrupt_claim = X"00000001" else
--                               X"00000001" when interrupt_claim = X"00000002" else
--                               X"00000002" when interrupt_claim = X"00000004" else
--                               X"00000003" when interrupt_claim = X"00000008" else
--                               X"00000004" when interrupt_claim = X"00000010" else
--                               X"00000005" when interrupt_claim = X"00000020" else
--                               X"00000006" when interrupt_claim = X"00000040" else
--                               X"00000007" when interrupt_claim = X"00000080" else
--                               X"00000008" when interrupt_claim = X"00000100" else
--                               X"00000009" when interrupt_claim = X"00000200" else
--                               X"0000000A" when interrupt_claim = X"00000400" else
--                               X"0000000B" when interrupt_claim = X"00000800" else
--                               X"0000000C" when interrupt_claim = X"00001000" else
--                               X"0000000D" when interrupt_claim = X"00002000" else
--                               X"0000000E" when interrupt_claim = X"00004000" else
--                               X"0000000F" when interrupt_claim = X"00008000" else
--                               X"00000010" when interrupt_claim = X"00010000" else
--                               X"00000011" when interrupt_claim = X"00020000" else
--                               X"00000012" when interrupt_claim = X"00040000" else
--                               X"00000013" when interrupt_claim = X"00088000" else
--                               X"00000014" when interrupt_claim = X"00100000" else
--                               X"00000015" when interrupt_claim = X"00200000" else
--                               X"00000016" when interrupt_claim = X"00400000" else
--                               X"00000017" when interrupt_claim = X"00800000" else
--                               X"00000018" when interrupt_claim = X"01000000" else
--                               X"00000019" when interrupt_claim = X"02000000" else
--                               X"0000001A" when interrupt_claim = X"04000000" else
--                               X"0000001B" when interrupt_claim = X"08000000" else
--                               X"0000001C" when interrupt_claim = X"10000000" else
--                               X"0000001D" when interrupt_claim = X"20000000" else
--                               X"0000001E" when interrupt_claim = X"40000000" else
--                               X"0000001F" when interrupt_claim = X"80000000" else
--                               X"00000000";
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
  interrupt_claim <= X"00000001" when (pending_interrupts(0)  = '1') else
                     X"00000002" when (pending_interrupts(1)  = '1') else
                     X"00000004" when (pending_interrupts(2)  = '1') else
                     X"00000008" when (pending_interrupts(3)  = '1') else
                     X"00000010" when (pending_interrupts(4)  = '1') else
                     X"00000020" when (pending_interrupts(5)  = '1') else
                     X"00000040" when (pending_interrupts(6)  = '1') else
                     X"00000080" when (pending_interrupts(7)  = '1') else
                     X"00000100" when (pending_interrupts(8)  = '1') else
                     X"00000200" when (pending_interrupts(9)  = '1') else
                     X"00000400" when (pending_interrupts(10) = '1') else
                     X"00000800" when (pending_interrupts(11) = '1') else
                     X"00001000" when (pending_interrupts(12) = '1') else
                     X"00002000" when (pending_interrupts(13) = '1') else
                     X"00004000" when (pending_interrupts(14) = '1') else
                     X"00008000" when (pending_interrupts(15) = '1') else
                     X"00010000" when (pending_interrupts(16) = '1') else
                     X"00020000" when (pending_interrupts(17) = '1') else
                     X"00040000" when (pending_interrupts(18) = '1') else
                     X"00088000" when (pending_interrupts(19) = '1') else
                     X"00100000" when (pending_interrupts(20) = '1') else
                     X"00200000" when (pending_interrupts(21) = '1') else
                     X"00400000" when (pending_interrupts(22) = '1') else
                     X"00800000" when (pending_interrupts(23) = '1') else
                     X"01000000" when (pending_interrupts(24) = '1') else
                     X"02000000" when (pending_interrupts(25) = '1') else
                     X"04000000" when (pending_interrupts(26) = '1') else
                     X"08000000" when (pending_interrupts(27) = '1') else
                     X"10000000" when (pending_interrupts(28) = '1') else
                     X"20000000" when (pending_interrupts(29) = '1') else
                     X"40000000" when (pending_interrupts(30) = '1') else
                     X"80000000" when (pending_interrupts(31) = '1') else
                     X"00000000";


end architecture rtl;
