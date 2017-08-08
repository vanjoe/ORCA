library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity orca is
  generic (
    REGISTER_SIZE   : integer              := 32;
    BYTE_SIZE       : integer              := 8;
    --BUS Select
    AVALON_ENABLE   : integer range 0 to 1 := 0;
    WISHBONE_ENABLE : integer range 0 to 1 := 0;
    AXI_ENABLE      : integer range 0 to 1 := 0;

    RESET_VECTOR          : integer                 := 16#00000000#;
    INTERRUPT_VECTOR      : integer                 := 16#00000200#;
    MULTIPLY_ENABLE       : natural range 0 to 1    := 0;
    DIVIDE_ENABLE         : natural range 0 to 1    := 0;
    SHIFTER_MAX_CYCLES    : natural                 := 1;
    COUNTER_LENGTH        : natural                 := 0;
    ENABLE_EXCEPTIONS     : natural                 := 1;
    BRANCH_PREDICTORS     : natural                 := 0;
    PIPELINE_STAGES       : natural range 4 to 5    := 5;
    LVE_ENABLE            : natural range 0 to 1    := 0;
    ENABLE_EXT_INTERRUPTS : natural range 0 to 1    := 0;
    NUM_EXT_INTERRUPTS    : integer range 1 to 32   := 1;
    SCRATCHPAD_ADDR_BITS  : integer                 := 10;
    IUC_ADDR_BASE         : natural                 := 0;
    IUC_ADDR_LAST         : natural                 := 0;
    ICACHE_SIZE           : natural                 := 8192;
    ICACHE_LINE_SIZE      : integer range 16 to 256 := 32;
    DRAM_WIDTH            : integer                 := 32;
    BURST_EN              : integer range 0 to 1    := 0;
    POWER_OPTIMIZED       : integer range 0 to 1    := 0;
    FAMILY                : string                  := "ALTERA");
  port(
    clk            : in std_logic;
    scratchpad_clk : in std_logic;
    reset          : in std_logic;

    -------------------------------------------------------------------------------
    --AVALON
    -------------------------------------------------------------------------------
    --Avalon data master
    avm_data_address              : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    avm_data_byteenable           : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    avm_data_read                 : out std_logic;
    avm_data_readdata             : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
    avm_data_write                : out std_logic;
    avm_data_writedata            : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    avm_data_waitrequest          : in  std_logic                                  := '0';
    avm_data_readdatavalid        : in  std_logic                                  := '0';

    --Avalon instruction master
    avm_instruction_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    avm_instruction_read          : out std_logic;
    avm_instruction_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
    avm_instruction_waitrequest   : in  std_logic                                  := '0';
    avm_instruction_readdatavalid : in  std_logic                                  := '0';

    -------------------------------------------------------------------------------
    --WISHBONE
    -------------------------------------------------------------------------------
    --WISHBONE data master
    data_ADR_O                    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_DAT_I                    : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
    data_DAT_O                    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_WE_O                     : out std_logic;
    data_SEL_O                    : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    data_STB_O                    : out std_logic;
    data_ACK_I                    : in  std_logic                                  := '0';
    data_CYC_O                    : out std_logic;
    data_CTI_O                    : out std_logic_vector(2 downto 0);
    data_STALL_I                  : in  std_logic                                  := '0';

    --WISHBONE instruction master
    instr_ADR_O                   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_DAT_I                   : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
    instr_STB_O                   : out std_logic;
    instr_ACK_I                   : in  std_logic                                  := '0';
    instr_CYC_O                   : out std_logic;
    instr_CTI_O                   : out std_logic_vector(2 downto 0);
    instr_STALL_I                 : in  std_logic                                  := '0';

    -------------------------------------------------------------------------------
    --AXI
    -------------------------------------------------------------------------------
    --AXI4-Lite uncached data master
    --A full AXI3 interface is exposed for systems that require it, but
    --only the A4L signals are needed
    DUC_AWID    : out std_logic_vector(3 downto 0);
    DUC_AWADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    DUC_AWLEN   : out std_logic_vector(3 downto 0);
    DUC_AWSIZE  : out std_logic_vector(2 downto 0);
    DUC_AWBURST : out std_logic_vector(1 downto 0);
    DUC_AWLOCK  : out std_logic_vector(1 downto 0);
    DUC_AWCACHE : out std_logic_vector(3 downto 0);
    DUC_AWPROT  : out std_logic_vector(2 downto 0);
    DUC_AWVALID : out std_logic;
    DUC_AWREADY : in  std_logic := '0';

    DUC_WID    : out std_logic_vector(3 downto 0);
    DUC_WDATA  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    DUC_WSTRB  : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    DUC_WLAST  : out std_logic;
    DUC_WVALID : out std_logic;
    DUC_WREADY : in  std_logic := '0';

    DUC_BID    : in  std_logic_vector(3 downto 0) := (others => '0');
    DUC_BRESP  : in  std_logic_vector(1 downto 0) := (others => '0');
    DUC_BVALID : in  std_logic                    := '0';
    DUC_BREADY : out std_logic;

    DUC_ARID    : out std_logic_vector(3 downto 0);
    DUC_ARADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    DUC_ARLEN   : out std_logic_vector(3 downto 0);
    DUC_ARSIZE  : out std_logic_vector(2 downto 0);
    DUC_ARBURST : out std_logic_vector(1 downto 0);
    DUC_ARLOCK  : out std_logic_vector(1 downto 0);
    DUC_ARCACHE : out std_logic_vector(3 downto 0);
    DUC_ARPROT  : out std_logic_vector(2 downto 0);
    DUC_ARVALID : out std_logic;
    DUC_ARREADY : in  std_logic := '0';

    DUC_RID    : in  std_logic_vector(3 downto 0)                := (others => '0');
    DUC_RDATA  : in  std_logic_vector(REGISTER_SIZE -1 downto 0) := (others => '0');
    DUC_RRESP  : in  std_logic_vector(1 downto 0)                := (others => '0');
    DUC_RLAST  : in  std_logic                                   := '0';
    DUC_RVALID : in  std_logic                                   := '0';
    DUC_RREADY : out std_logic;

    --AXI4-Lite uncached instruction master
    --A full AXI3 interface is exposed for systems that require it, but
    --only the A4L signals are needed
    IUC_ARID    : out std_logic_vector(3 downto 0);
    IUC_ARADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    IUC_ARLEN   : out std_logic_vector(3 downto 0);
    IUC_ARSIZE  : out std_logic_vector(2 downto 0);
    IUC_ARBURST : out std_logic_vector(1 downto 0);
    IUC_ARLOCK  : out std_logic_vector(1 downto 0);
    IUC_ARCACHE : out std_logic_vector(3 downto 0);
    IUC_ARPROT  : out std_logic_vector(2 downto 0);
    IUC_ARVALID : out std_logic;
    IUC_ARREADY : in  std_logic := '0';

    IUC_RID    : in  std_logic_vector(3 downto 0)                := (others => '0');
    IUC_RDATA  : in  std_logic_vector(REGISTER_SIZE -1 downto 0) := (others => '0');
    IUC_RRESP  : in  std_logic_vector(1 downto 0)                := (others => '0');
    IUC_RLAST  : in  std_logic                                   := '0';
    IUC_RVALID : in  std_logic                                   := '0';
    IUC_RREADY : out std_logic;

    IUC_AWID    : out std_logic_vector(3 downto 0);
    IUC_AWADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    IUC_AWLEN   : out std_logic_vector(3 downto 0);
    IUC_AWSIZE  : out std_logic_vector(2 downto 0);
    IUC_AWBURST : out std_logic_vector(1 downto 0);
    IUC_AWLOCK  : out std_logic_vector(1 downto 0);
    IUC_AWCACHE : out std_logic_vector(3 downto 0);
    IUC_AWPROT  : out std_logic_vector(2 downto 0);
    IUC_AWVALID : out std_logic;
    IUC_AWREADY : in  std_logic := '0';

    IUC_WID    : out std_logic_vector(3 downto 0);
    IUC_WDATA  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    IUC_WSTRB  : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    IUC_WLAST  : out std_logic;
    IUC_WVALID : out std_logic;
    IUC_WREADY : in  std_logic := '0';

    IUC_BID    : in  std_logic_vector(3 downto 0) := (others => '0');
    IUC_BRESP  : in  std_logic_vector(1 downto 0) := (others => '0');
    IUC_BVALID : in  std_logic                    := '0';
    IUC_BREADY : out std_logic;

    --AXI3 cacheable instruction master
    IC_ARID    : out std_logic_vector(3 downto 0);
    IC_ARADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    IC_ARLEN   : out std_logic_vector(3 downto 0);
    IC_ARSIZE  : out std_logic_vector(2 downto 0);
    IC_ARBURST : out std_logic_vector(1 downto 0);
    IC_ARLOCK  : out std_logic_vector(1 downto 0);
    IC_ARCACHE : out std_logic_vector(3 downto 0);
    IC_ARPROT  : out std_logic_vector(2 downto 0);
    IC_ARVALID : out std_logic;
    IC_ARREADY : in  std_logic := '0';

    IC_RID    : in  std_logic_vector(3 downto 0)            := (others => '0');
    IC_RDATA  : in  std_logic_vector(DRAM_WIDTH-1 downto 0) := (others => '0');
    IC_RRESP  : in  std_logic_vector(1 downto 0)            := (others => '0');
    IC_RLAST  : in  std_logic                               := '0';
    IC_RVALID : in  std_logic                               := '0';
    IC_RREADY : out std_logic;

    IC_AWID    : out std_logic_vector(3 downto 0);
    IC_AWADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    IC_AWLEN   : out std_logic_vector(3 downto 0);
    IC_AWSIZE  : out std_logic_vector(2 downto 0);
    IC_AWBURST : out std_logic_vector(1 downto 0);
    IC_AWLOCK  : out std_logic_vector(1 downto 0);
    IC_AWCACHE : out std_logic_vector(3 downto 0);
    IC_AWPROT  : out std_logic_vector(2 downto 0);
    IC_AWVALID : out std_logic;
    IC_AWREADY : in  std_logic := '0';

    IC_WID    : out std_logic_vector(3 downto 0);
    IC_WDATA  : out std_logic_vector(DRAM_WIDTH-1 downto 0);
    IC_WSTRB  : out std_logic_vector(DRAM_WIDTH/8 -1 downto 0);
    IC_WLAST  : out std_logic;
    IC_WVALID : out std_logic;
    IC_WREADY : in  std_logic                    := '0';
    IC_BID    : in  std_logic_vector(3 downto 0) := (others => '0');
    IC_BRESP  : in  std_logic_vector(1 downto 0) := (others => '0');
    IC_BVALID : in  std_logic                    := '0';
    IC_BREADY : out std_logic;

    -------------------------------------------------------------------------------
    -- Scratchpad Slave
    -------------------------------------------------------------------------------
    --Avalon scratchpad slave
    avm_scratch_address       : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0) := (others => '0');
    avm_scratch_byteenable    : in  std_logic_vector(REGISTER_SIZE/8 -1 downto 0)     := (others => '0');
    avm_scratch_read          : in  std_logic                                         := '0';
    avm_scratch_readdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    avm_scratch_write         : in  std_logic                                         := '0';
    avm_scratch_writedata     : in  std_logic_vector(REGISTER_SIZE-1 downto 0)        := (others => '0');
    avm_scratch_waitrequest   : out std_logic;
    avm_scratch_readdatavalid : out std_logic;

    --WISHBONE scratchpad slave
    sp_ADR_I   : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0) := (others => '0');
    sp_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    sp_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0)        := (others => '0');
    sp_WE_I    : in  std_logic                                         := '0';
    sp_SEL_I   : in  std_logic_vector(REGISTER_SIZE/8 -1 downto 0)     := (others => '0');
    sp_STB_I   : in  std_logic                                         := '0';
    sp_ACK_O   : out std_logic;
    sp_CYC_I   : in  std_logic                                         := '0';
    sp_CTI_I   : in  std_logic_vector(2 downto 0)                      := (others => '0');
    sp_STALL_O : out std_logic;

    -------------------------------------------------------------------------------
    -- Interrupts
    -------------------------------------------------------------------------------
    global_interrupts : in std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0) := (others => '0')
    );

end entity orca;

architecture rtl of orca is
  signal core_data_address    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal core_data_byteenable : std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
  signal core_data_read       : std_logic;
  signal core_data_readdata   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal core_data_write      : std_logic;
  signal core_data_writedata  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal core_data_ack        : std_logic;

  signal core_instruction_address       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal core_instruction_read          : std_logic;
  signal core_instruction_readdata      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal core_instruction_waitrequest   : std_logic;
  signal core_instruction_readdatavalid : std_logic;

  signal sp_address   : std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
  signal sp_byte_en   : std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
  signal sp_write_en  : std_logic;
  signal sp_read_en   : std_logic;
  signal sp_writedata : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sp_readdata  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sp_ack       : std_logic;

begin  -- architecture rtl
  assert (AVALON_ENABLE + WISHBONE_ENABLE + AXI_ENABLE = 1) report "Exactly one bus type must be enabled" severity failure;

  -----------------------------------------------------------------------------
  -- AVALON
  -----------------------------------------------------------------------------
  avalon_enabled : if AVALON_ENABLE = 1 generate
    signal is_writing : std_logic;
    signal is_reading : std_logic;
    signal write_ack  : std_logic;

    signal ack_mask : std_logic;
  begin
    core_data_readdata <= avm_data_readdata;

    core_data_ack  <= avm_data_readdatavalid or write_ack;
    avm_data_write <= is_writing;
    avm_data_read  <= is_reading;
    process(clk)

    begin
      if rising_edge(clk) then

        if (is_writing or is_reading) = '1' and avm_data_waitrequest = '1' then

        else
          is_reading          <= core_data_read;
          avm_data_address    <= core_data_address;
          is_writing          <= core_data_write;
          avm_data_writedata  <= core_data_writedata;
          avm_data_byteenable <= core_data_byteenable;
        end if;

        write_ack <= '0';
        if is_writing = '1' and avm_data_waitrequest = '0' then
          write_ack <= '1';
        end if;
      end if;

    end process;

    avm_instruction_address        <= core_instruction_address;
    avm_instruction_read           <= core_instruction_read;
    core_instruction_readdata      <= avm_instruction_readdata;
    core_instruction_waitrequest   <= avm_instruction_waitrequest;
    core_instruction_readdatavalid <= avm_instruction_readdatavalid;

    sp_address              <= avm_scratch_address;
    sp_byte_en              <= avm_scratch_byteenable;
    sp_read_en              <= avm_scratch_read;
    sp_write_en             <= avm_scratch_write;
    sp_writedata            <= avm_scratch_writedata;
    avm_scratch_readdata    <= sp_readdata;
    avm_scratch_waitrequest <= '0';
    process(clk)
    begin
      if rising_edge(clk) then
        if sp_ack = '1' then
          ack_mask <= '0';
        end if;
        if sp_read_en = '1' then
          ack_mask <= '1';
        end if;
      end if;
    end process;
    avm_scratch_readdatavalid <= sp_ack and ack_mask;

  end generate avalon_enabled;

  -----------------------------------------------------------------------------
  -- WISHBONE
  -----------------------------------------------------------------------------
  wishbone_enabled : if WISHBONE_ENABLE = 1 generate
    signal is_read_transaction : std_logic;
  begin
    core_data_readdata <= data_DAT_I;
    core_data_ack      <= data_ACK_I;

    instr_ADR_O                    <= core_instruction_address;
    instr_CYC_O                    <= core_instruction_read;
    instr_STB_O                    <= core_instruction_read;
    core_instruction_readdata      <= instr_DAT_I;
    core_instruction_waitrequest   <= instr_STALL_I;
    core_instruction_readdatavalid <= instr_ACK_I;

    process(clk)
    begin
      if rising_edge(clk) then
        if data_STALL_I = '0' then
          data_ADR_O <= core_data_address;
          data_SEL_O <= core_data_byteenable;
          data_CYC_O <= core_data_read or core_data_write;
          data_STB_O <= core_data_read or core_data_write;
          data_WE_O  <= core_data_write;
          data_DAT_O <= core_data_writedata;
        end if;
      end if;
    end process;

    --scrachpad slave
    sp_address   <= sp_ADR_I;
    sp_DAT_O     <= sp_readdata;
    sp_writedata <= sp_DAT_I;
    sp_write_en  <= sp_WE_I and sp_STB_I and sp_CYC_I;
    sp_read_en   <= not sp_WE_I and sp_STB_I and sp_CYC_I;
    sp_byte_en   <= sp_SEL_I;
    sp_ACK_O     <= sp_ack;
    sp_STALL_O   <= '0';


  end generate wishbone_enabled;

  axi_enabled : if AXI_ENABLE = 1 generate
    constant A4L_BURST_LEN  : std_logic_vector(3 downto 0) := "0000";
    constant A4L_BURST_SIZE : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(log2(REGISTER_SIZE/8), 3));
    constant A4L_BURST_INCR : std_logic_vector(1 downto 0) := "01";
    constant A4L_LOCK_VAL   : std_logic_vector(1 downto 0) := "00";
    constant A4L_CACHE_VAL  : std_logic_vector(3 downto 0) := "0000";

    signal axi_resetn : std_logic;

    signal instr_AWID    : std_logic_vector(3 downto 0);
    signal instr_AWADDR  : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal instr_AWPROT  : std_logic_vector(2 downto 0);
    signal instr_AWVALID : std_logic;
    signal instr_AWREADY : std_logic;

    signal instr_WID    : std_logic_vector(3 downto 0);
    signal instr_WDATA  : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal instr_WSTRB  : std_logic_vector(REGISTER_SIZE/BYTE_SIZE-1 downto 0);
    signal instr_WVALID : std_logic;
    signal instr_WREADY : std_logic;

    signal instr_BID    : std_logic_vector(3 downto 0);
    signal instr_BRESP  : std_logic_vector(1 downto 0);
    signal instr_BVALID : std_logic;
    signal instr_BREADY : std_logic;

    signal instr_ARID    : std_logic_vector(3 downto 0);
    signal instr_ARADDR  : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal instr_ARPROT  : std_logic_vector(2 downto 0);
    signal instr_ARVALID : std_logic;
    signal instr_ARREADY : std_logic;

    signal instr_RID    : std_logic_vector(3 downto 0);
    signal instr_RDATA  : std_logic_vector(REGISTER_SIZE -1 downto 0);
    signal instr_RRESP  : std_logic_vector(1 downto 0);
    signal instr_RVALID : std_logic;
    signal instr_RREADY : std_logic;

    signal core_instruction_write     : std_logic;
    signal core_instruction_writedata : std_logic_vector(REGISTER_SIZE-1 downto 0);
  begin
    axi_resetn                 <= not reset;
    core_instruction_write     <= '0';
    core_instruction_writedata <= (others => '0');

    --Uncached bus signals are AXI4L, translate to AXI3 if needed
    DUC_AWID    <= (others => '0');
    DUC_AWLEN   <= A4L_BURST_LEN;
    DUC_AWSIZE  <= A4L_BURST_SIZE;
    DUC_AWBURST <= A4L_BURST_INCR;
    DUC_AWLOCK  <= A4L_LOCK_VAL;
    DUC_AWCACHE <= A4L_CACHE_VAL;
    DUC_WID     <= (others => '0');
    DUC_WLAST   <= '1';
    DUC_ARID    <= (others => '0');
    DUC_ARLEN   <= A4L_BURST_LEN;
    DUC_ARSIZE  <= A4L_BURST_SIZE;
    DUC_ARBURST <= A4L_BURST_INCR;
    DUC_ARLOCK  <= A4L_LOCK_VAL;
    DUC_ARCACHE <= A4L_CACHE_VAL;

    IUC_AWID    <= (others => '0');
    IUC_AWLEN   <= A4L_BURST_LEN;
    IUC_AWSIZE  <= A4L_BURST_SIZE;
    IUC_AWBURST <= A4L_BURST_INCR;
    IUC_AWLOCK  <= A4L_LOCK_VAL;
    IUC_AWCACHE <= A4L_CACHE_VAL;
    IUC_WID     <= (others => '0');
    IUC_WLAST   <= '1';
    IUC_ARID    <= (others => '0');
    IUC_ARLEN   <= A4L_BURST_LEN;
    IUC_ARSIZE  <= A4L_BURST_SIZE;
    IUC_ARBURST <= A4L_BURST_INCR;
    IUC_ARLOCK  <= A4L_LOCK_VAL;
    IUC_ARCACHE <= A4L_CACHE_VAL;

    data_master : a4l_master
      generic map (
        ADDR_WIDTH    => REGISTER_SIZE,
        REGISTER_SIZE => REGISTER_SIZE,
        BYTE_SIZE     => BYTE_SIZE
        )
      port map (
        clk     => clk,
        aresetn => axi_resetn,

        core_data_address    => core_data_address,
        core_data_byteenable => core_data_byteenable,
        core_data_read       => core_data_read,
        core_data_readdata   => core_data_readdata,
        core_data_write      => core_data_write,
        core_data_writedata  => core_data_writedata,
        core_data_ack        => core_data_ack,

        AWADDR  => DUC_AWADDR,
        AWPROT  => DUC_AWPROT,
        AWVALID => DUC_AWVALID,
        AWREADY => DUC_AWREADY,

        WSTRB  => DUC_WSTRB,
        WVALID => DUC_WVALID,
        WDATA  => DUC_WDATA,
        WREADY => DUC_WREADY,

        BRESP  => DUC_BRESP,
        BVALID => DUC_BVALID,
        BREADY => DUC_BREADY,

        ARADDR  => DUC_ARADDR,
        ARPROT  => DUC_ARPROT,
        ARVALID => DUC_ARVALID,
        ARREADY => DUC_ARREADY,

        RDATA  => DUC_RDATA,
        RRESP  => DUC_RRESP,
        RVALID => DUC_RVALID,
        RREADY => DUC_RREADY
        );

    -- Instruction read port
    instruction_master : a4l_instruction_master
      generic map (
        REGISTER_SIZE => REGISTER_SIZE,
        BYTE_SIZE     => BYTE_SIZE
        )
      port map (
        clk                            => clk,
        aresetn                        => axi_resetn,
        core_instruction_address       => core_instruction_address,
        core_instruction_read          => core_instruction_read,
        core_instruction_readdata      => core_instruction_readdata,
        core_instruction_readdatavalid => core_instruction_readdatavalid,
        core_instruction_write         => core_instruction_write,
        core_instruction_writedata     => core_instruction_writedata,
        core_instruction_waitrequest   => core_instruction_waitrequest,

        AWADDR  => instr_AWADDR,
        AWPROT  => instr_AWPROT,
        AWVALID => instr_AWVALID,
        AWREADY => instr_AWREADY,

        WSTRB  => instr_WSTRB,
        WVALID => instr_WVALID,
        WDATA  => instr_WDATA,
        WREADY => instr_WREADY,

        BRESP  => instr_BRESP,
        BVALID => instr_BVALID,
        BREADY => instr_BREADY,

        ARADDR  => instr_ARADDR,
        ARPROT  => instr_ARPROT,
        ARVALID => instr_ARVALID,
        ARREADY => instr_ARREADY,

        RDATA  => instr_RDATA,
        RRESP  => instr_RRESP,
        RVALID => instr_RVALID,
        RREADY => instr_RREADY
        );

    instruction_cache : if ICACHE_SIZE /= 0 generate
      signal cache_AWID    : std_logic_vector(3 downto 0);
      signal cache_AWADDR  : std_logic_vector(REGISTER_SIZE-1 downto 0);
      signal cache_AWPROT  : std_logic_vector(2 downto 0);
      signal cache_AWVALID : std_logic;
      signal cache_AWREADY : std_logic;

      signal cache_WID    : std_logic_vector(3 downto 0);
      signal cache_WDATA  : std_logic_vector(REGISTER_SIZE -1 downto 0);
      signal cache_WSTRB  : std_logic_vector(REGISTER_SIZE/BYTE_SIZE-1 downto 0);
      signal cache_WVALID : std_logic;
      signal cache_WREADY : std_logic;

      signal cache_BID    : std_logic_vector(3 downto 0);
      signal cache_BRESP  : std_logic_vector(1 downto 0);
      signal cache_BVALID : std_logic;
      signal cache_BREADY : std_logic;

      signal cache_ARID    : std_logic_vector(3 downto 0);
      signal cache_ARADDR  : std_logic_vector(REGISTER_SIZE-1 downto 0);
      signal cache_ARPROT  : std_logic_vector(2 downto 0);
      signal cache_ARVALID : std_logic;
      signal cache_ARREADY : std_logic;

      signal cache_RID    : std_logic_vector(3 downto 0);
      signal cache_RDATA  : std_logic_vector(REGISTER_SIZE -1 downto 0);
      signal cache_RRESP  : std_logic_vector(1 downto 0);
      signal cache_RVALID : std_logic;
      signal cache_RREADY : std_logic;
    begin

      instruction_cache_mux : cache_mux
        generic map (
          UC_ADDR_BASE  => IUC_ADDR_BASE,
          UC_ADDR_LAST  => IUC_ADDR_LAST,
          ADDR_WIDTH    => REGISTER_SIZE,
          REGISTER_SIZE => REGISTER_SIZE,
          BYTE_SIZE     => BYTE_SIZE
          )
        port map (
          clk   => clk,
          reset => reset,

          in_AWID    => instr_AWID,
          in_AWADDR  => instr_AWADDR,
          in_AWPROT  => instr_AWPROT,
          in_AWVALID => instr_AWVALID,
          in_AWREADY => instr_AWREADY,

          in_WID    => instr_WID,
          in_WDATA  => instr_WDATA,
          in_WSTRB  => instr_WSTRB,
          in_WVALID => instr_WVALID,
          in_WREADY => instr_WREADY,

          in_BID    => instr_BID,
          in_BRESP  => instr_BRESP,
          in_BVALID => instr_BVALID,
          in_BREADY => instr_BREADY,

          in_ARID    => instr_ARID,
          in_ARADDR  => instr_ARADDR,
          in_ARPROT  => instr_ARPROT,
          in_ARVALID => instr_ARVALID,
          in_ARREADY => instr_ARREADY,

          in_RID    => instr_RID,
          in_RDATA  => instr_RDATA,
          in_RRESP  => instr_RRESP,
          in_RVALID => instr_RVALID,
          in_RREADY => instr_RREADY,

          cache_AWID    => cache_AWID,
          cache_AWADDR  => cache_AWADDR,
          cache_AWPROT  => cache_AWPROT,
          cache_AWVALID => cache_AWVALID,
          cache_AWREADY => cache_AWREADY,

          cache_WID    => cache_WID,
          cache_WDATA  => cache_WDATA,
          cache_WSTRB  => cache_WSTRB,
          cache_WVALID => cache_WVALID,
          cache_WREADY => cache_WREADY,

          cache_BID    => cache_BID,
          cache_BRESP  => cache_BRESP,
          cache_BVALID => cache_BVALID,
          cache_BREADY => cache_BREADY,

          cache_ARID    => cache_ARID,
          cache_ARADDR  => cache_ARADDR,
          cache_ARPROT  => cache_ARPROT,
          cache_ARVALID => cache_ARVALID,
          cache_ARREADY => cache_ARREADY,

          cache_RID    => cache_RID,
          cache_RDATA  => cache_RDATA,
          cache_RRESP  => cache_RRESP,
          cache_RVALID => cache_RVALID,
          cache_RREADY => cache_RREADY,

          uc_AWID    => IUC_AWID,
          uc_AWADDR  => IUC_AWADDR,
          uc_AWPROT  => IUC_AWPROT,
          uc_AWVALID => IUC_AWVALID,
          uc_AWREADY => IUC_AWREADY,

          uc_WID    => IUC_WID,
          uc_WDATA  => IUC_WDATA,
          uc_WSTRB  => IUC_WSTRB,
          uc_WVALID => IUC_WVALID,
          uc_WREADY => IUC_WREADY,

          uc_BID    => IUC_BID,
          uc_BRESP  => IUC_BRESP,
          uc_BVALID => IUC_BVALID,
          uc_BREADY => IUC_BREADY,

          uc_ARID    => IUC_ARID,
          uc_ARADDR  => IUC_ARADDR,
          uc_ARPROT  => IUC_ARPROT,
          uc_ARVALID => IUC_ARVALID,
          uc_ARREADY => IUC_ARREADY,

          uc_RID    => IUC_RID,
          uc_RDATA  => IUC_RDATA,
          uc_RRESP  => IUC_RRESP,
          uc_RVALID => IUC_RVALID,
          uc_RREADY => IUC_RREADY
          );

      instruction_cache : icache
        generic map (
          CACHE_SIZE => ICACHE_SIZE,       -- Byte size of cache
          LINE_SIZE  => ICACHE_LINE_SIZE,  -- Bytes per cache line 
          ADDR_WIDTH => REGISTER_SIZE,
          ORCA_WIDTH => REGISTER_SIZE,
          DRAM_WIDTH => DRAM_WIDTH,
          BYTE_SIZE  => BYTE_SIZE,
          BURST_EN   => BURST_EN,
          FAMILY     => FAMILY
          )
        port map (
          clk   => clk,
          reset => reset,

          orca_AWID    => cache_AWID,
          orca_AWADDR  => cache_AWADDR,
          orca_AWPROT  => cache_AWPROT,
          orca_AWVALID => cache_AWVALID,
          orca_AWREADY => cache_AWREADY,

          orca_WID    => cache_WID,
          orca_WDATA  => cache_WDATA,
          orca_WSTRB  => cache_WSTRB,
          orca_WVALID => cache_WVALID,
          orca_WREADY => cache_WREADY,

          orca_BID    => cache_BID,
          orca_BRESP  => cache_BRESP,
          orca_BVALID => cache_BVALID,
          orca_BREADY => cache_BREADY,

          orca_ARID    => cache_ARID,
          orca_ARADDR  => cache_ARADDR,
          orca_ARPROT  => cache_ARPROT,
          orca_ARVALID => cache_ARVALID,
          orca_ARREADY => cache_ARREADY,

          orca_RID    => cache_RID,
          orca_RDATA  => cache_RDATA,
          orca_RRESP  => cache_RRESP,
          orca_RVALID => cache_RVALID,
          orca_RREADY => cache_RREADY,

          dram_AWID    => IC_AWID,
          dram_AWADDR  => IC_AWADDR,
          dram_AWLEN   => IC_AWLEN,
          dram_AWSIZE  => IC_AWSIZE,
          dram_AWBURST => IC_AWBURST,

          dram_AWLOCK  => IC_AWLOCK,
          dram_AWCACHE => IC_AWCACHE,
          dram_AWPROT  => IC_AWPROT,
          dram_AWVALID => IC_AWVALID,
          dram_AWREADY => IC_AWREADY,

          dram_WID    => IC_WID,
          dram_WDATA  => IC_WDATA,
          dram_WSTRB  => IC_WSTRB,
          dram_WLAST  => IC_WLAST,
          dram_WVALID => IC_WVALID,
          dram_WREADY => IC_WREADY,

          dram_BID    => IC_BID,
          dram_BRESP  => IC_BRESP,
          dram_BVALID => IC_BVALID,
          dram_BREADY => IC_BREADY,

          dram_ARID    => IC_ARID,
          dram_ARADDR  => IC_ARADDR,
          dram_ARLEN   => IC_ARLEN,
          dram_ARSIZE  => IC_ARSIZE,
          dram_ARBURST => IC_ARBURST,
          dram_ARLOCK  => IC_ARLOCK,
          dram_ARCACHE => IC_ARCACHE,
          dram_ARPROT  => IC_ARPROT,
          dram_ARVALID => IC_ARVALID,
          dram_ARREADY => IC_ARREADY,

          dram_RID    => IC_RID,
          dram_RDATA  => IC_RDATA,
          dram_RRESP  => IC_RRESP,
          dram_RLAST  => IC_RLAST,
          dram_RVALID => IC_RVALID,
          dram_RREADY => IC_RREADY
          );
    end generate instruction_cache;

    no_instruction_cache : if ICACHE_SIZE = 0 generate
    begin
      IC_AWID    <= (others => '0');
      IC_AWADDR  <= (others => '0');
      IC_AWLEN   <= (others => '0');
      IC_AWSIZE  <= (others => '0');
      IC_AWBURST <= (others => '0');

      IC_AWLOCK  <= (others => '0');
      IC_AWCACHE <= (others => '0');
      IC_AWPROT  <= (others => '0');
      IC_AWVALID <= '0';

      IC_WID    <= (others => '0');
      IC_WDATA  <= (others => '0');
      IC_WSTRB  <= (others => '0');
      IC_WLAST  <= '0';
      IC_WVALID <= '0';

      IC_BREADY <= '0';

      IC_ARID    <= (others => '0');
      IC_ARADDR  <= (others => '0');
      IC_ARLEN   <= (others => '0');
      IC_ARSIZE  <= (others => '0');
      IC_ARBURST <= (others => '0');
      IC_ARLOCK  <= (others => '0');
      IC_ARCACHE <= (others => '0');
      IC_ARPROT  <= (others => '0');
      IC_ARVALID <= '0';

      IC_RREADY <= '0';

      IUC_AWID      <= instr_AWID;
      IUC_AWADDR    <= instr_AWADDR;
      IUC_AWPROT    <= instr_AWPROT;
      IUC_AWVALID   <= instr_AWVALID;
      instr_AWREADY <= IUC_AWREADY;

      IUC_WID      <= instr_WID;
      IUC_WDATA    <= instr_WDATA;
      IUC_WSTRB    <= instr_WSTRB;
      IUC_WVALID   <= instr_WVALID;
      instr_WREADY <= IUC_WREADY;

      instr_BID    <= IUC_BID;
      instr_BRESP  <= IUC_BRESP;
      instr_BVALID <= IUC_BVALID;
      IUC_BREADY   <= instr_BREADY;

      IUC_ARID      <= instr_ARID;
      IUC_ARADDR    <= instr_ARADDR;
      IUC_ARPROT    <= instr_ARPROT;
      IUC_ARVALID   <= instr_ARVALID;
      instr_ARREADY <= IUC_ARREADY;

      instr_RID    <= IUC_RID;
      instr_RDATA  <= IUC_RDATA;
      instr_RRESP  <= IUC_RRESP;
      instr_RVALID <= IUC_RVALID;
      IUC_RREADY   <= instr_RREADY;
    end generate no_instruction_cache;
  end generate axi_enabled;

  core : orca_core
    generic map(
      REGISTER_SIZE      => REGISTER_SIZE,
      RESET_VECTOR       => RESET_VECTOR,
      INTERRUPT_VECTOR   => INTERRUPT_VECTOR,
      MULTIPLY_ENABLE    => MULTIPLY_ENABLE,
      DIVIDE_ENABLE      => DIVIDE_ENABLE,
      SHIFTER_MAX_CYCLES => SHIFTER_MAX_CYCLES,
      POWER_OPTIMIZED    => POWER_OPTIMIZED,
      COUNTER_LENGTH     => COUNTER_LENGTH,
      ENABLE_EXCEPTIONS  => ENABLE_EXCEPTIONS,
      BRANCH_PREDICTORS  => BRANCH_PREDICTORS,
      PIPELINE_STAGES    => PIPELINE_STAGES,
      LVE_ENABLE         => LVE_ENABLE,
      NUM_EXT_INTERRUPTS => CONDITIONAL(ENABLE_EXT_INTERRUPTS > 0, NUM_EXT_INTERRUPTS, 0),
      SCRATCHPAD_SIZE    => CONDITIONAL(LVE_ENABLE = 1, 2**SCRATCHPAD_ADDR_BITS, 0),
      FAMILY             => FAMILY)

    port map(
      clk            => clk,
      scratchpad_clk => scratchpad_clk,
      reset          => reset,

                                        --avalon master bus
      core_data_address              => core_data_address,
      core_data_byteenable           => core_data_byteenable,
      core_data_read                 => core_data_read,
      core_data_readdata             => core_data_readdata,
      core_data_write                => core_data_write,
      core_data_writedata            => core_data_writedata,
      core_data_ack                  => core_data_ack,
                                        --avalon master bus
      core_instruction_address       => core_instruction_address,
      core_instruction_read          => core_instruction_read,
      core_instruction_readdata      => core_instruction_readdata,
      core_instruction_waitrequest   => core_instruction_waitrequest,
      core_instruction_readdatavalid => core_instruction_readdatavalid,

      sp_address   => sp_address(CONDITIONAL(LVE_ENABLE = 1, SCRATCHPAD_ADDR_BITS, 0)-1 downto 0),
      sp_byte_en   => sp_byte_en,
      sp_write_en  => sp_write_en,
      sp_read_en   => sp_read_en,
      sp_writedata => sp_writedata,
      sp_readdata  => sp_readdata,
      sp_ack       => sp_ack,

      external_interrupts => global_interrupts(CONDITIONAL(ENABLE_EXT_INTERRUPTS > 0, NUM_EXT_INTERRUPTS, 0)-1 downto 0));

end architecture rtl;
