library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity memory_interface is
  generic (
    REGISTER_SIZE        : positive range 32 to 32 := 32;
    SCRATCHPAD_ADDR_BITS : positive                := 10;

    --BUS Select
    AVALON_ENABLE   : integer range 0 to 1 := 0;
    WISHBONE_ENABLE : integer range 0 to 1 := 0;
    AXI_ENABLE      : integer range 0 to 1 := 0;

    WISHBONE_SINGLE_CYCLE_READS : natural range 0 to 1          := 0;
    DATA_REQUEST_REGISTER       : natural range 0 to 2          := 1;
    DATA_RETURN_REGISTER        : natural range 0 to 1          := 0;
    IUC_ADDR_BASE               : std_logic_vector(31 downto 0) := X"00000000";
    IUC_ADDR_LAST               : std_logic_vector(31 downto 0) := X"00000000";
    IAUX_ADDR_BASE              : std_logic_vector(31 downto 0) := X"00000000";
    IAUX_ADDR_LAST              : std_logic_vector(31 downto 0) := X"00000000";
    ICACHE_SIZE                 : natural                       := 8192;
    ICACHE_LINE_SIZE            : integer range 16 to 256       := 32;
    ICACHE_EXTERNAL_WIDTH       : integer                       := 32;
    ICACHE_MAX_BURSTLENGTH      : positive                      := 16;
    ICACHE_BURST_EN             : integer range 0 to 1          := 0
    );
  port (
    clk            : in std_logic;
    scratchpad_clk : in std_logic;
    reset          : in std_logic;

    --Instruction Orca-internal memory-mapped master
    ifetch_oimm_address       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    ifetch_oimm_requestvalid  : in  std_logic;
    ifetch_oimm_readnotwrite  : in  std_logic;
    ifetch_oimm_readdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    ifetch_oimm_waitrequest   : out std_logic;
    ifetch_oimm_readdatavalid : out std_logic;

    --Data Orca-internal memory-mapped master
    lsu_oimm_address       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    lsu_oimm_byteenable    : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    lsu_oimm_requestvalid  : in  std_logic;
    lsu_oimm_readnotwrite  : in  std_logic;
    lsu_oimm_writedata     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    lsu_oimm_readdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    lsu_oimm_readdatavalid : out std_logic;
    lsu_oimm_waitrequest   : out std_logic;

    --Scratchpad memory-mapped slave
    sp_address   : out std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
    sp_byte_en   : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    sp_write_en  : out std_logic;
    sp_read_en   : out std_logic;
    sp_writedata : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    sp_readdata  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    sp_ack       : in  std_logic;

    -------------------------------------------------------------------------------
    --AVALON
    -------------------------------------------------------------------------------
    --Avalon data master
    avm_data_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    avm_data_byteenable    : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    avm_data_read          : out std_logic;
    avm_data_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
    avm_data_write         : out std_logic;
    avm_data_writedata     : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    avm_data_waitrequest   : in  std_logic                                  := '0';
    avm_data_readdatavalid : in  std_logic                                  := '0';

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
    data_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
    data_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_WE_O    : out std_logic;
    data_SEL_O   : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    data_STB_O   : out std_logic;
    data_ACK_I   : in  std_logic                                  := '0';
    data_CYC_O   : out std_logic;
    data_CTI_O   : out std_logic_vector(2 downto 0);
    data_STALL_I : in  std_logic                                  := '0';

    --WISHBONE instruction master
    instr_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
    instr_STB_O   : out std_logic;
    instr_ACK_I   : in  std_logic                                  := '0';
    instr_CYC_O   : out std_logic;
    instr_CTI_O   : out std_logic_vector(2 downto 0);
    instr_STALL_I : in  std_logic                                  := '0';

    -------------------------------------------------------------------------------
    --AXI
    -------------------------------------------------------------------------------
    --AXI4-Lite uncached data master
    --A full AXI3 interface is exposed for systems that require it, but
    --only the A4L signals are needed
    DUC_AWID    : out std_logic_vector(3 downto 0);
    DUC_AWADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    DUC_AWLEN   : out std_logic_vector(3 downto 0);
    DUC_AWSIZE  : out std_logic_vector(2 downto 0);
    DUC_AWBURST : out std_logic_vector(1 downto 0);
    DUC_AWLOCK  : out std_logic_vector(1 downto 0);
    DUC_AWCACHE : out std_logic_vector(3 downto 0);
    DUC_AWPROT  : out std_logic_vector(2 downto 0);
    DUC_AWVALID : out std_logic;
    DUC_AWREADY : in  std_logic := '0';

    DUC_WID    : out std_logic_vector(3 downto 0);
    DUC_WDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    DUC_WSTRB  : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    DUC_WLAST  : out std_logic;
    DUC_WVALID : out std_logic;
    DUC_WREADY : in  std_logic := '0';

    DUC_BID    : in  std_logic_vector(3 downto 0) := (others => '0');
    DUC_BRESP  : in  std_logic_vector(1 downto 0) := (others => '0');
    DUC_BVALID : in  std_logic                    := '0';
    DUC_BREADY : out std_logic;

    DUC_ARID    : out std_logic_vector(3 downto 0);
    DUC_ARADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    DUC_ARLEN   : out std_logic_vector(3 downto 0);
    DUC_ARSIZE  : out std_logic_vector(2 downto 0);
    DUC_ARBURST : out std_logic_vector(1 downto 0);
    DUC_ARLOCK  : out std_logic_vector(1 downto 0);
    DUC_ARCACHE : out std_logic_vector(3 downto 0);
    DUC_ARPROT  : out std_logic_vector(2 downto 0);
    DUC_ARVALID : out std_logic;
    DUC_ARREADY : in  std_logic := '0';

    DUC_RID    : in  std_logic_vector(3 downto 0)               := (others => '0');
    DUC_RDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
    DUC_RRESP  : in  std_logic_vector(1 downto 0)               := (others => '0');
    DUC_RLAST  : in  std_logic                                  := '0';
    DUC_RVALID : in  std_logic                                  := '0';
    DUC_RREADY : out std_logic;

    --AXI4-Lite uncached instruction master
    --A full AXI3 interface is exposed for systems that require it, but
    --only the A4L signals are needed
    IUC_ARID    : out std_logic_vector(3 downto 0);
    IUC_ARADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    IUC_ARLEN   : out std_logic_vector(3 downto 0);
    IUC_ARSIZE  : out std_logic_vector(2 downto 0);
    IUC_ARBURST : out std_logic_vector(1 downto 0);
    IUC_ARLOCK  : out std_logic_vector(1 downto 0);
    IUC_ARCACHE : out std_logic_vector(3 downto 0);
    IUC_ARPROT  : out std_logic_vector(2 downto 0);
    IUC_ARVALID : out std_logic;
    IUC_ARREADY : in  std_logic := '0';

    IUC_RID    : in  std_logic_vector(3 downto 0)               := (others => '0');
    IUC_RDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
    IUC_RRESP  : in  std_logic_vector(1 downto 0)               := (others => '0');
    IUC_RLAST  : in  std_logic                                  := '0';
    IUC_RVALID : in  std_logic                                  := '0';
    IUC_RREADY : out std_logic;

    IUC_AWID    : out std_logic_vector(3 downto 0);
    IUC_AWADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    IUC_AWLEN   : out std_logic_vector(3 downto 0);
    IUC_AWSIZE  : out std_logic_vector(2 downto 0);
    IUC_AWBURST : out std_logic_vector(1 downto 0);
    IUC_AWLOCK  : out std_logic_vector(1 downto 0);
    IUC_AWCACHE : out std_logic_vector(3 downto 0);
    IUC_AWPROT  : out std_logic_vector(2 downto 0);
    IUC_AWVALID : out std_logic;
    IUC_AWREADY : in  std_logic := '0';

    IUC_WID    : out std_logic_vector(3 downto 0);
    IUC_WDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    IUC_WSTRB  : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    IUC_WLAST  : out std_logic;
    IUC_WVALID : out std_logic;
    IUC_WREADY : in  std_logic := '0';

    IUC_BID    : in  std_logic_vector(3 downto 0) := (others => '0');
    IUC_BRESP  : in  std_logic_vector(1 downto 0) := (others => '0');
    IUC_BVALID : in  std_logic                    := '0';
    IUC_BREADY : out std_logic;

    --Xilinx local memory bus instruction master
    ILMB_Addr         : out std_logic_vector(0 to REGISTER_SIZE-1);
    ILMB_Byte_Enable  : out std_logic_vector(0 to (REGISTER_SIZE/8)-1);
    ILMB_Data_Write   : out std_logic_vector(0 to REGISTER_SIZE-1);
    ILMB_AS           : out std_logic;
    ILMB_Read_Strobe  : out std_logic;
    ILMB_Write_Strobe : out std_logic;
    ILMB_Data_Read    : in  std_logic_vector(0 to REGISTER_SIZE-1);
    ILMB_Ready        : in  std_logic;
    ILMB_Wait         : in  std_logic;
    ILMB_CE           : in  std_logic;
    ILMB_UE           : in  std_logic;

    --AXI3 cacheable instruction master
    IC_ARID    : out std_logic_vector(3 downto 0);
    IC_ARADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    IC_ARLEN   : out std_logic_vector(3 downto 0);
    IC_ARSIZE  : out std_logic_vector(2 downto 0);
    IC_ARBURST : out std_logic_vector(1 downto 0);
    IC_ARLOCK  : out std_logic_vector(1 downto 0);
    IC_ARCACHE : out std_logic_vector(3 downto 0);
    IC_ARPROT  : out std_logic_vector(2 downto 0);
    IC_ARVALID : out std_logic;
    IC_ARREADY : in  std_logic := '0';

    IC_RID    : in  std_logic_vector(3 downto 0)                       := (others => '0');
    IC_RDATA  : in  std_logic_vector(ICACHE_EXTERNAL_WIDTH-1 downto 0) := (others => '0');
    IC_RRESP  : in  std_logic_vector(1 downto 0)                       := (others => '0');
    IC_RLAST  : in  std_logic                                          := '0';
    IC_RVALID : in  std_logic                                          := '0';
    IC_RREADY : out std_logic;

    IC_AWID    : out std_logic_vector(3 downto 0);
    IC_AWADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    IC_AWLEN   : out std_logic_vector(3 downto 0);
    IC_AWSIZE  : out std_logic_vector(2 downto 0);
    IC_AWBURST : out std_logic_vector(1 downto 0);
    IC_AWLOCK  : out std_logic_vector(1 downto 0);
    IC_AWCACHE : out std_logic_vector(3 downto 0);
    IC_AWPROT  : out std_logic_vector(2 downto 0);
    IC_AWVALID : out std_logic;
    IC_AWREADY : in  std_logic := '0';

    IC_WID    : out std_logic_vector(3 downto 0);
    IC_WDATA  : out std_logic_vector(ICACHE_EXTERNAL_WIDTH-1 downto 0);
    IC_WSTRB  : out std_logic_vector((ICACHE_EXTERNAL_WIDTH/8)-1 downto 0);
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
    avm_scratch_byteenable    : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0)    := (others => '0');
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
    sp_SEL_I   : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0)    := (others => '0');
    sp_STB_I   : in  std_logic                                         := '0';
    sp_ACK_O   : out std_logic;
    sp_CYC_I   : in  std_logic                                         := '0';
    sp_CTI_I   : in  std_logic_vector(2 downto 0)                      := (others => '0');
    sp_STALL_O : out std_logic
    );
end entity memory_interface;

architecture rtl of memory_interface is
  signal lsu_oimm_waitrequest_int : std_logic;

  constant A4L_BURST_LEN  : std_logic_vector(3 downto 0) := "0000";
  constant A4L_BURST_SIZE : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(log2(REGISTER_SIZE/8), 3));
  constant A4L_BURST_INCR : std_logic_vector(1 downto 0) := "01";
  constant A4L_LOCK_VAL   : std_logic_vector(1 downto 0) := "00";
  constant A4L_CACHE_VAL  : std_logic_vector(3 downto 0) := "0000";

  signal data_oimm_address       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_oimm_byteenable    : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
  signal data_oimm_requestvalid  : std_logic;
  signal data_oimm_readnotwrite  : std_logic;
  signal data_oimm_writedata     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_oimm_readdata      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_oimm_readdatavalid : std_logic;
  signal data_oimm_waitrequest   : std_logic;

  signal iuc_oimm_address       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal iuc_oimm_byteenable    : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
  signal iuc_oimm_requestvalid  : std_logic;
  signal iuc_oimm_readnotwrite  : std_logic;
  signal iuc_oimm_writedata     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal iuc_oimm_readdata      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal iuc_oimm_readdatavalid : std_logic;
  signal iuc_oimm_waitrequest   : std_logic;

  signal iaux_oimm_address       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal iaux_oimm_byteenable    : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
  signal iaux_oimm_requestvalid  : std_logic;
  signal iaux_oimm_readnotwrite  : std_logic;
  signal iaux_oimm_writedata     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal iaux_oimm_readdata      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal iaux_oimm_readdatavalid : std_logic;
  signal iaux_oimm_waitrequest   : std_logic;

  signal icacheint_oimm_address       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal icacheint_oimm_byteenable    : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
  signal icacheint_oimm_requestvalid  : std_logic;
  signal icacheint_oimm_readnotwrite  : std_logic;
  signal icacheint_oimm_writedata     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal icacheint_oimm_readdata      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal icacheint_oimm_readdatavalid : std_logic;
  signal icacheint_oimm_waitrequest   : std_logic;

  signal ic_oimm_address            : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ic_oimm_burstlength        : std_logic_vector(log2(ICACHE_MAX_BURSTLENGTH+1)-1 downto 0);
  signal ic_oimm_burstlength_minus1 : std_logic_vector(log2(ICACHE_MAX_BURSTLENGTH)-1 downto 0);
  signal ic_oimm_byteenable         : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
  signal ic_oimm_requestvalid       : std_logic;
  signal ic_oimm_readnotwrite       : std_logic;
  signal ic_oimm_writedata          : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ic_oimm_readdata           : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ic_oimm_readdatavalid      : std_logic;
  signal ic_oimm_waitrequest        : std_logic;

  signal ifetch_oimm_byteenable : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
  signal ifetch_oimm_writedata  : std_logic_vector(REGISTER_SIZE-1 downto 0);
begin  -- architecture rtl
  lsu_oimm_waitrequest <= lsu_oimm_waitrequest_int;

  assert (AVALON_ENABLE + WISHBONE_ENABLE + AXI_ENABLE) = 1 report
    "Exactly one bus type must be enabled"
    severity failure;
  assert (AXI_ENABLE = 1) or (ICACHE_SIZE = 0) report
    "ICache is currently only implemented for AXI, please change ICACHE_SIZE to 0 for other bus types."
    severity failure;

  --Instruction master is read only, fill in these signals for submodules that
  --need them.
  ifetch_oimm_writedata  <= (others => '-');
  ifetch_oimm_byteenable <= (others => '1');

  -----------------------------------------------------------------------------
  -- Optional Data Memory Request Register
  -----------------------------------------------------------------------------
  no_data_request_register_gen : if DATA_REQUEST_REGISTER = 0 generate
    --Passthrough, lowest fmax but no extra resources or added latency.
    data_oimm_address      <= lsu_oimm_address;
    data_oimm_byteenable   <= lsu_oimm_byteenable;
    data_oimm_requestvalid <= lsu_oimm_requestvalid;
    data_oimm_readnotwrite <= lsu_oimm_readnotwrite;
    data_oimm_writedata    <= lsu_oimm_writedata;

    lsu_oimm_waitrequest_int <= data_oimm_waitrequest;
  end generate no_data_request_register_gen;
  light_data_request_register_gen : if DATA_REQUEST_REGISTER = 1 generate
    signal lsu_oimm_address_held      : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal lsu_oimm_byteenable_held   : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    signal lsu_oimm_requestvalid_held : std_logic;
    signal lsu_oimm_readnotwrite_held : std_logic;
    signal lsu_oimm_writedata_held    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  begin
    --Light register; breaks waitrequest/stall combinational path but does not break
    --address/etc. path.  Does not add latency if slave is not asserting
    --waitrequest, but will reduce throughput if the slave does.
    data_oimm_address      <= lsu_oimm_address_held      when lsu_oimm_waitrequest_int = '1' else lsu_oimm_address;
    data_oimm_byteenable   <= lsu_oimm_byteenable_held   when lsu_oimm_waitrequest_int = '1' else lsu_oimm_byteenable;
    data_oimm_requestvalid <= lsu_oimm_requestvalid_held when lsu_oimm_waitrequest_int = '1' else lsu_oimm_requestvalid;
    data_oimm_readnotwrite <= lsu_oimm_readnotwrite_held when lsu_oimm_waitrequest_int = '1' else lsu_oimm_readnotwrite;
    data_oimm_writedata    <= lsu_oimm_writedata_held    when lsu_oimm_waitrequest_int = '1' else lsu_oimm_writedata;

    process(clk)
    begin
      if rising_edge(clk) then
        --When coming out of reset, need to put waitrequest down
        if lsu_oimm_requestvalid_held = '0' then
          lsu_oimm_waitrequest_int <= '0';
        end if;

        if data_oimm_waitrequest = '0' then
          lsu_oimm_waitrequest_int <= '0';
        end if;

        if lsu_oimm_waitrequest_int = '0' then
          lsu_oimm_address_held      <= lsu_oimm_address;
          lsu_oimm_byteenable_held   <= lsu_oimm_byteenable;
          lsu_oimm_requestvalid_held <= lsu_oimm_requestvalid;
          lsu_oimm_readnotwrite_held <= lsu_oimm_readnotwrite;
          lsu_oimm_writedata_held    <= lsu_oimm_writedata;
          lsu_oimm_waitrequest_int   <= data_oimm_waitrequest and lsu_oimm_requestvalid;
        end if;

        if reset = '1' then
          lsu_oimm_requestvalid_held <= '0';
          lsu_oimm_waitrequest_int   <= '1';
        end if;
      end if;
    end process;
  end generate light_data_request_register_gen;
  full_data_request_register_gen : if DATA_REQUEST_REGISTER /= 0 and DATA_REQUEST_REGISTER /= 1 generate
    signal registered_oimm_address      : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal registered_oimm_byteenable   : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    signal registered_oimm_requestvalid : std_logic;
    signal registered_oimm_readnotwrite : std_logic;
    signal registered_oimm_writedata    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  begin
    --Full register; breaks waitrequest/stall combinational path and address/etc.
    --path. Always adds one cycle of latency but does not reduce throughput.
    process(clk)
    begin
      if rising_edge(clk) then
        --When coming out of reset, need to put waitrequest down
        if registered_oimm_requestvalid = '0' then
          lsu_oimm_waitrequest_int <= '0';
        end if;

        if data_oimm_waitrequest = '0' then
          data_oimm_requestvalid <= '0';
          if registered_oimm_requestvalid = '1' then
            data_oimm_address            <= registered_oimm_address;
            data_oimm_byteenable         <= registered_oimm_byteenable;
            data_oimm_readnotwrite       <= registered_oimm_readnotwrite;
            data_oimm_requestvalid       <= registered_oimm_requestvalid;
            data_oimm_writedata          <= registered_oimm_writedata;
            registered_oimm_requestvalid <= '0';
            lsu_oimm_waitrequest_int     <= '0';
          else
            data_oimm_address      <= lsu_oimm_address;
            data_oimm_byteenable   <= lsu_oimm_byteenable;
            data_oimm_readnotwrite <= lsu_oimm_readnotwrite;
            data_oimm_requestvalid <= lsu_oimm_requestvalid and (not lsu_oimm_waitrequest_int);
            data_oimm_writedata    <= lsu_oimm_writedata;
          end if;
        else
          if lsu_oimm_waitrequest_int = '0' then
            if data_oimm_requestvalid = '1' then
              registered_oimm_address      <= lsu_oimm_address;
              registered_oimm_byteenable   <= lsu_oimm_byteenable;
              registered_oimm_requestvalid <= lsu_oimm_requestvalid;
              registered_oimm_readnotwrite <= lsu_oimm_readnotwrite;
              registered_oimm_writedata    <= lsu_oimm_writedata;
              lsu_oimm_waitrequest_int     <= lsu_oimm_requestvalid;
            else
              data_oimm_address      <= lsu_oimm_address;
              data_oimm_byteenable   <= lsu_oimm_byteenable;
              data_oimm_readnotwrite <= lsu_oimm_readnotwrite;
              data_oimm_requestvalid <= lsu_oimm_requestvalid;
              data_oimm_writedata    <= lsu_oimm_writedata;
            end if;
          end if;
        end if;

        if reset = '1' then
          data_oimm_requestvalid       <= '0';
          registered_oimm_requestvalid <= '0';
          lsu_oimm_waitrequest_int     <= '1';
        end if;
      end if;
    end process;

  end generate full_data_request_register_gen;

  -----------------------------------------------------------------------------
  -- Optional Data Memory Return Register
  -----------------------------------------------------------------------------
  no_data_return_register_gen : if DATA_RETURN_REGISTER = 0 generate
    lsu_oimm_readdata      <= data_oimm_readdata;
    lsu_oimm_readdatavalid <= data_oimm_readdatavalid;
  end generate no_data_return_register_gen;
  data_return_register_gen : if DATA_RETURN_REGISTER /= 0 generate
    process(clk)
    begin
      if rising_edge(clk) then
        lsu_oimm_readdata      <= data_oimm_readdata;
        lsu_oimm_readdatavalid <= data_oimm_readdatavalid;
      end if;
    end process;
  end generate data_return_register_gen;


  -----------------------------------------------------------------------------
  -- Instruction cache and mux
  -----------------------------------------------------------------------------
  instruction_cache_mux : cache_mux
    generic map (
      REGISTER_SIZE   => REGISTER_SIZE,
      CACHE_SIZE      => ICACHE_SIZE,
      CACHE_LINE_SIZE => ICACHE_LINE_SIZE,
      UC_ADDR_BASE    => IUC_ADDR_BASE,
      UC_ADDR_LAST    => IUC_ADDR_LAST,
      AUX_ADDR_BASE   => IAUX_ADDR_BASE,
      AUX_ADDR_LAST   => IAUX_ADDR_LAST,
      ADDR_WIDTH      => REGISTER_SIZE,
      DATA_WIDTH      => REGISTER_SIZE
      )
    port map (
      clk   => clk,
      reset => reset,

      oimm_address       => ifetch_oimm_address,
      oimm_byteenable    => ifetch_oimm_byteenable,
      oimm_requestvalid  => ifetch_oimm_requestvalid,
      oimm_readnotwrite  => ifetch_oimm_readnotwrite,
      oimm_writedata     => ifetch_oimm_writedata,
      oimm_readdata      => ifetch_oimm_readdata,
      oimm_readdatavalid => ifetch_oimm_readdatavalid,
      oimm_waitrequest   => ifetch_oimm_waitrequest,

      cacheint_oimm_address       => icacheint_oimm_address,
      cacheint_oimm_byteenable    => icacheint_oimm_byteenable,
      cacheint_oimm_requestvalid  => icacheint_oimm_requestvalid,
      cacheint_oimm_readnotwrite  => icacheint_oimm_readnotwrite,
      cacheint_oimm_writedata     => icacheint_oimm_writedata,
      cacheint_oimm_readdata      => icacheint_oimm_readdata,
      cacheint_oimm_readdatavalid => icacheint_oimm_readdatavalid,
      cacheint_oimm_waitrequest   => icacheint_oimm_waitrequest,

      uc_oimm_address       => iuc_oimm_address,
      uc_oimm_byteenable    => iuc_oimm_byteenable,
      uc_oimm_requestvalid  => iuc_oimm_requestvalid,
      uc_oimm_readnotwrite  => iuc_oimm_readnotwrite,
      uc_oimm_writedata     => iuc_oimm_writedata,
      uc_oimm_readdata      => iuc_oimm_readdata,
      uc_oimm_readdatavalid => iuc_oimm_readdatavalid,
      uc_oimm_waitrequest   => iuc_oimm_waitrequest,

      aux_oimm_address       => iaux_oimm_address,
      aux_oimm_byteenable    => iaux_oimm_byteenable,
      aux_oimm_requestvalid  => iaux_oimm_requestvalid,
      aux_oimm_readnotwrite  => iaux_oimm_readnotwrite,
      aux_oimm_writedata     => iaux_oimm_writedata,
      aux_oimm_readdata      => iaux_oimm_readdata,
      aux_oimm_readdatavalid => iaux_oimm_readdatavalid,
      aux_oimm_waitrequest   => iaux_oimm_waitrequest
      );

  instruction_cache : if ICACHE_SIZE /= 0 generate
    instruction_cache : icache
      generic map (
        CACHE_SIZE      => ICACHE_SIZE,       -- Byte size of cache
        LINE_SIZE       => ICACHE_LINE_SIZE,  -- Bytes per cache line 
        ADDR_WIDTH      => REGISTER_SIZE,
        INTERNAL_WIDTH  => REGISTER_SIZE,
        EXTERNAL_WIDTH  => ICACHE_EXTERNAL_WIDTH,
        MAX_BURSTLENGTH => ICACHE_MAX_BURSTLENGTH,
        BURST_EN        => ICACHE_BURST_EN
        )
      port map (
        clk   => clk,
        reset => reset,

        cacheint_oimm_address       => icacheint_oimm_address,
        cacheint_oimm_byteenable    => icacheint_oimm_byteenable,
        cacheint_oimm_requestvalid  => icacheint_oimm_requestvalid,
        cacheint_oimm_readnotwrite  => icacheint_oimm_readnotwrite,
        cacheint_oimm_writedata     => icacheint_oimm_writedata,
        cacheint_oimm_readdata      => icacheint_oimm_readdata,
        cacheint_oimm_readdatavalid => icacheint_oimm_readdatavalid,
        cacheint_oimm_waitrequest   => icacheint_oimm_waitrequest,

        c_oimm_address            => ic_oimm_address,
        c_oimm_burstlength        => ic_oimm_burstlength,
        c_oimm_burstlength_minus1 => ic_oimm_burstlength_minus1,
        c_oimm_byteenable         => ic_oimm_byteenable,
        c_oimm_requestvalid       => ic_oimm_requestvalid,
        c_oimm_readnotwrite       => ic_oimm_readnotwrite,
        c_oimm_writedata          => ic_oimm_writedata,
        c_oimm_readdata           => ic_oimm_readdata,
        c_oimm_readdatavalid      => ic_oimm_readdatavalid,
        c_oimm_waitrequest        => ic_oimm_waitrequest
        );
  end generate instruction_cache;

  -----------------------------------------------------------------------------
  -- LMB (AUX)
  -----------------------------------------------------------------------------
  lmb_aux_enabled : if true generate
    signal read_in_flight  : std_logic;
    signal write_in_flight : std_logic;
  begin
    ILMB_Addr         <= iaux_oimm_address;
    ILMB_Byte_Enable  <= iaux_oimm_byteenable;
    ILMB_Data_Write   <= iaux_oimm_writedata;
    ILMB_AS           <= iaux_oimm_requestvalid and (not iaux_oimm_waitrequest);
    ILMB_Read_Strobe  <= iaux_oimm_readnotwrite and iaux_oimm_requestvalid and (not iaux_oimm_waitrequest);
    ILMB_Write_Strobe <= (not iaux_oimm_readnotwrite) and iaux_oimm_requestvalid and (not iaux_oimm_waitrequest);

    --The LMB spec (which is inside the MicroBlaze Processor Reference Guide)
    --is vague about how Wait and Ready differ and can be used.  A conservative
    --reading is that a new request can be sent as soon as Ready is asserted
    --and there's no reason to pay attention to Wait.
    --It's not explicitly stated but looking at Xilinx's HDL it's clear that
    --Ready can't be asserted on the same cycle as the strobe signals.
    process (clk) is
    begin  -- process
      if clk'event and clk = '1' then   -- rising clock edge
        if ILMB_Ready = '1' then
          read_in_flight  <= '0';
          write_in_flight <= '0';
        end if;

        if iaux_oimm_requestvalid = '1' and iaux_oimm_waitrequest = '0' then
          if iaux_oimm_readnotwrite = '1' then
            read_in_flight <= '1';
          else
            write_in_flight <= '1';
          end if;
        end if;

        if reset = '1' then             -- synchronous reset (active high)
          read_in_flight  <= '0';
          write_in_flight <= '0';
        end if;
      end if;
    end process;

    iaux_oimm_readdata      <= ILMB_Data_Read;
    iaux_oimm_readdatavalid <= ILMB_Ready and read_in_flight;
    iaux_oimm_waitrequest   <= (read_in_flight or write_in_flight) and (not ILMB_Ready);
  end generate lmb_aux_enabled;
  lmb_aux_disabled : if false generate
    ILMB_Addr         <= (others => '0');
    ILMB_Byte_Enable  <= (others => '0');
    ILMB_Data_Write   <= (others => '0');
    ILMB_AS           <= '0';
    ILMB_Read_Strobe  <= '0';
    ILMB_Write_Strobe <= '0';
  end generate lmb_aux_disabled;


  -----------------------------------------------------------------------------
  -- AVALON
  -----------------------------------------------------------------------------
  avalon_enabled : if AVALON_ENABLE /= 0 generate
    signal reading : std_logic;
    signal writing : std_logic;
  begin
    avm_instruction_address <= iuc_oimm_address;
    avm_instruction_read    <= iuc_oimm_readnotwrite and iuc_oimm_requestvalid;
    iuc_oimm_readdata       <= avm_instruction_readdata;
    iuc_oimm_waitrequest    <= avm_instruction_waitrequest;
    iuc_oimm_readdatavalid  <= avm_instruction_readdatavalid;

    avm_data_address        <= data_oimm_address;
    avm_data_byteenable     <= data_oimm_byteenable;
    avm_data_read           <= data_oimm_readnotwrite and data_oimm_requestvalid;
    data_oimm_readdata      <= avm_data_readdata;
    avm_data_write          <= (not data_oimm_readnotwrite) and data_oimm_requestvalid;
    avm_data_writedata      <= data_oimm_writedata;
    data_oimm_waitrequest   <= avm_data_waitrequest;
    data_oimm_readdatavalid <= avm_data_readdatavalid;

    sp_address              <= avm_scratch_address;
    sp_byte_en              <= avm_scratch_byteenable;
    sp_read_en              <= avm_scratch_read;
    sp_write_en             <= avm_scratch_write;
    sp_writedata            <= avm_scratch_writedata;
    avm_scratch_readdata    <= sp_readdata;
    avm_scratch_waitrequest <= (reading or writing) and (not sp_ack);
    process(clk)
    begin
      if rising_edge(clk) then
        if (reading = '0' and writing = '0') or sp_ack = '1' then
          reading <= avm_scratch_read;
          writing <= avm_scratch_write;
        end if;

        if reset = '1' then
          reading <= '0';
          writing <= '0';
        end if;
      end if;
    end process;
    --Note this is not generic for WISHBONE where apparently ACK can be combinational based on
    --STB/CYC (Avalon requires at least one clock edge between read and readdatavalid).
    --However, the scratchpad will always have at least one cycle of delay so
    --this is valid.
    avm_scratch_readdatavalid <= sp_ack and reading;

    sp_DAT_O   <= (others => '0');
    sp_ACK_O   <= '0';
    sp_STALL_O <= '1';
  end generate avalon_enabled;
  avalon_disabled : if AVALON_ENABLE = 0 generate
    avm_data_address          <= (others => '0');
    avm_data_byteenable       <= (others => '0');
    avm_data_read             <= '0';
    avm_data_write            <= '0';
    avm_data_writedata        <= (others => '0');
    avm_instruction_address   <= (others => '0');
    avm_instruction_read      <= '0';
    avm_scratch_readdata      <= (others => '0');
    avm_scratch_waitrequest   <= '1';
    avm_scratch_readdatavalid <= '0';

    --Default to WISHBONE slave if not Avalon (LVE not interfaced to AXI yet)
    sp_address   <= sp_ADR_I;
    sp_DAT_O     <= sp_readdata;
    sp_writedata <= sp_DAT_I;
    sp_write_en  <= sp_WE_I and sp_STB_I and sp_CYC_I;
    sp_read_en   <= not sp_WE_I and sp_STB_I and sp_CYC_I;
    sp_byte_en   <= sp_SEL_I;
    sp_ACK_O     <= sp_ack;
    sp_STALL_O   <= '0';
  end generate avalon_disabled;

  -----------------------------------------------------------------------------
  -- WISHBONE
  -----------------------------------------------------------------------------
  wishbone_enabled : if WISHBONE_ENABLE /= 0 generate
    signal reading               : std_logic;
    signal writing               : std_logic;
    signal awaiting_ack          : std_logic;
    signal delayed_readdatavalid : std_logic;
    signal delayed_readdata      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  begin
    awaiting_ack <= reading or writing;

    no_single_cycle_gen : if WISHBONE_SINGLE_CYCLE_READS = 0 generate
      data_oimm_readdata      <= data_DAT_I;
      data_oimm_readdatavalid <= data_ACK_I and reading;
    end generate no_single_cycle_gen;
    single_cycle_gen : if WISHBONE_SINGLE_CYCLE_READS /= 0 generate
      data_oimm_readdata      <= data_DAT_I when delayed_readdatavalid = '0' else delayed_readdata;
      data_oimm_readdatavalid <= (data_ACK_I and reading) or delayed_readdatavalid;
    end generate single_cycle_gen;
    data_oimm_waitrequest <= data_STALL_I or (awaiting_ack and (not data_ACK_I));
    data_ADR_O            <= data_oimm_address;
    data_STB_O            <= data_oimm_requestvalid and ((not awaiting_ack) or data_ACK_I);
    data_CYC_O            <= data_oimm_requestvalid and ((not awaiting_ack) or data_ACK_I);
    data_CTI_O            <= (others => '0');
    data_SEL_O            <= data_oimm_byteenable;
    data_WE_O             <= not data_oimm_readnotwrite;
    data_DAT_O            <= data_oimm_writedata;
    process(clk)
    begin
      if rising_edge(clk) then
        delayed_readdata      <= data_DAT_I;
        delayed_readdatavalid <= '0';
        if data_ACK_I = '1' then
          reading <= '0';
          writing <= '0';
        end if;
        if data_oimm_waitrequest = '0' then
          --Allow one ACK in flight.  Must delay single cycle reads to conform
          --to Avalon spec (readdatavalid can't come back on the same cycle as
          --read is asserted).
          if awaiting_ack = '0' and data_ACK_I = '1' then
            delayed_readdatavalid <= data_oimm_readnotwrite and data_oimm_requestvalid;
            reading               <= '0';
            writing               <= '0';
          else
            reading <= data_oimm_readnotwrite and data_oimm_requestvalid;
            writing <= (not data_oimm_readnotwrite) and data_oimm_requestvalid;
          end if;
        end if;

        if reset = '1' then
          delayed_readdatavalid <= '0';
          reading               <= '0';
          writing               <= '0';
        end if;
      end if;
    end process;

    instr_ADR_O            <= iuc_oimm_address;
    instr_CYC_O            <= iuc_oimm_readnotwrite and iuc_oimm_requestvalid;
    instr_CTI_O            <= (others => '0');
    instr_STB_O            <= iuc_oimm_readnotwrite and iuc_oimm_requestvalid;
    iuc_oimm_readdata      <= instr_DAT_I;
    iuc_oimm_waitrequest   <= instr_STALL_I;
    iuc_oimm_readdatavalid <= instr_ACK_I;
  end generate wishbone_enabled;
  wishbone_disabled : if WISHBONE_ENABLE = 0 generate
    data_ADR_O  <= (others => '0');
    data_STB_O  <= '0';
    data_CYC_O  <= '0';
    data_CTI_O  <= (others => '0');
    data_SEL_O  <= (others => '0');
    data_WE_O   <= '0';
    data_DAT_O  <= (others => '0');
    instr_ADR_O <= (others => '0');
    instr_CYC_O <= '0';
    instr_CTI_O <= (others => '0');
    instr_STB_O <= '0';
  end generate wishbone_disabled;

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

  axi_enabled : if AXI_ENABLE /= 0 generate
    signal axi_resetn : std_logic;

    signal instr_AWID    : std_logic_vector(3 downto 0);
    signal instr_AWADDR  : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal instr_AWPROT  : std_logic_vector(2 downto 0);
    signal instr_AWVALID : std_logic;
    signal instr_AWREADY : std_logic;

    signal instr_WID    : std_logic_vector(3 downto 0);
    signal instr_WDATA  : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal instr_WSTRB  : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
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
    signal instr_RDATA  : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal instr_RRESP  : std_logic_vector(1 downto 0);
    signal instr_RVALID : std_logic;
    signal instr_RREADY : std_logic;
  begin
    axi_resetn <= not reset;

    iuc_master : a4l_master
      generic map (
        ADDR_WIDTH => REGISTER_SIZE,
        DATA_WIDTH => REGISTER_SIZE
        )
      port map (
        clk     => clk,
        aresetn => axi_resetn,

        oimm_address       => iuc_oimm_address,
        oimm_byteenable    => iuc_oimm_byteenable,
        oimm_requestvalid  => iuc_oimm_requestvalid,
        oimm_readnotwrite  => iuc_oimm_readnotwrite,
        oimm_writedata     => iuc_oimm_writedata,
        oimm_readdata      => iuc_oimm_readdata,
        oimm_readdatavalid => iuc_oimm_readdatavalid,
        oimm_waitrequest   => iuc_oimm_waitrequest,

        AWADDR  => IUC_AWADDR,
        AWPROT  => IUC_AWPROT,
        AWVALID => IUC_AWVALID,
        AWREADY => IUC_AWREADY,

        WSTRB  => IUC_WSTRB,
        WVALID => IUC_WVALID,
        WDATA  => IUC_WDATA,
        WREADY => IUC_WREADY,

        BRESP  => IUC_BRESP,
        BVALID => IUC_BVALID,
        BREADY => IUC_BREADY,

        ARADDR  => IUC_ARADDR,
        ARPROT  => IUC_ARPROT,
        ARVALID => IUC_ARVALID,
        ARREADY => IUC_ARREADY,

        RDATA  => IUC_RDATA,
        RRESP  => IUC_RRESP,
        RVALID => IUC_RVALID,
        RREADY => IUC_RREADY
        );

    ic_master : axi_master
      generic map (
        ADDR_WIDTH      => REGISTER_SIZE,
        DATA_WIDTH      => REGISTER_SIZE,
        ID_WIDTH        => 4,
        MAX_BURSTLENGTH => ICACHE_MAX_BURSTLENGTH
        )
      port map (
        clk     => clk,
        aresetn => axi_resetn,

        oimm_address            => ic_oimm_address,
        oimm_burstlength        => ic_oimm_burstlength,
        oimm_burstlength_minus1 => ic_oimm_burstlength_minus1,
        oimm_byteenable         => ic_oimm_byteenable,
        oimm_requestvalid       => ic_oimm_requestvalid,
        oimm_readnotwrite       => ic_oimm_readnotwrite,
        oimm_writedata          => ic_oimm_writedata,
        oimm_readdata           => ic_oimm_readdata,
        oimm_readdatavalid      => ic_oimm_readdatavalid,
        oimm_waitrequest        => ic_oimm_waitrequest,

        AWID    => IC_AWID,
        AWADDR  => IC_AWADDR,
        AWLEN   => IC_AWLEN,
        AWSIZE  => IC_AWSIZE,
        AWBURST => IC_AWBURST,
        AWLOCK  => IC_AWLOCK,
        AWCACHE => IC_AWCACHE,
        AWPROT  => IC_AWPROT,
        AWVALID => IC_AWVALID,
        AWREADY => IC_AWREADY,

        WID    => IC_WID,
        WSTRB  => IC_WSTRB,
        WVALID => IC_WVALID,
        WLAST  => IC_WLAST,
        WDATA  => IC_WDATA,
        WREADY => IC_WREADY,

        BID    => IC_BID,
        BRESP  => IC_BRESP,
        BVALID => IC_BVALID,
        BREADY => IC_BREADY,

        ARID    => IC_ARID,
        ARADDR  => IC_ARADDR,
        ARLEN   => IC_ARLEN,
        ARSIZE  => IC_ARSIZE,
        ARBURST => IC_ARBURST,
        ARLOCK  => IC_ARLOCK,
        ARCACHE => IC_ARCACHE,
        ARPROT  => IC_ARPROT,
        ARVALID => IC_ARVALID,
        ARREADY => IC_ARREADY,

        RID    => IC_RID,
        RDATA  => IC_RDATA,
        RRESP  => IC_RRESP,
        RLAST  => IC_RLAST,
        RVALID => IC_RVALID,
        RREADY => IC_RREADY
        );

    data_master : a4l_master
      generic map (
        ADDR_WIDTH => REGISTER_SIZE,
        DATA_WIDTH => REGISTER_SIZE
        )
      port map (
        clk     => clk,
        aresetn => axi_resetn,

        oimm_address       => data_oimm_address,
        oimm_byteenable    => data_oimm_byteenable,
        oimm_requestvalid  => data_oimm_requestvalid,
        oimm_readnotwrite  => data_oimm_readnotwrite,
        oimm_writedata     => data_oimm_writedata,
        oimm_readdata      => data_oimm_readdata,
        oimm_readdatavalid => data_oimm_readdatavalid,
        oimm_waitrequest   => data_oimm_waitrequest,

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
  end generate axi_enabled;
  axi_disabled : if AXI_ENABLE = 0 generate
    DUC_AWADDR  <= (others => '0');
    DUC_AWPROT  <= (others => '0');
    DUC_AWVALID <= '0';
    DUC_WDATA   <= (others => '0');
    DUC_WSTRB   <= (others => '0');
    DUC_WVALID  <= '0';
    DUC_BREADY  <= '0';
    DUC_ARADDR  <= (others => '0');
    DUC_ARPROT  <= (others => '0');
    DUC_ARVALID <= '0';
    DUC_RREADY  <= '0';

    IUC_AWADDR  <= (others => '0');
    IUC_AWPROT  <= (others => '0');
    IUC_AWVALID <= '0';
    IUC_WDATA   <= (others => '0');
    IUC_WSTRB   <= (others => '0');
    IUC_WVALID  <= '0';
    IUC_BREADY  <= '0';
    IUC_ARADDR  <= (others => '0');
    IUC_ARPROT  <= (others => '0');
    IUC_ARVALID <= '0';
    IUC_RREADY  <= '0';

    IC_ARID    <= (others => '0');
    IC_ARADDR  <= (others => '0');
    IC_ARLEN   <= (others => '0');
    IC_ARSIZE  <= (others => '0');
    IC_ARBURST <= (others => '0');
    IC_ARLOCK  <= (others => '0');
    IC_ARCACHE <= (others => '0');
    IC_ARPROT  <= (others => '0');
    IC_ARVALID <= '0';
    IC_RREADY  <= '0';
    IC_AWID    <= (others => '0');
    IC_AWADDR  <= (others => '0');
    IC_AWLEN   <= (others => '0');
    IC_AWSIZE  <= (others => '0');
    IC_AWBURST <= (others => '0');
    IC_AWLOCK  <= (others => '0');
    IC_AWCACHE <= (others => '0');
    IC_AWPROT  <= (others => '0');
    IC_AWVALID <= '0';
    IC_WID     <= (others => '0');
    IC_WDATA   <= (others => '0');
    IC_WSTRB   <= (others => '0');
    IC_WLAST   <= '0';
    IC_WVALID  <= '0';
    IC_BREADY  <= '0';
  end generate axi_disabled;

end architecture rtl;
