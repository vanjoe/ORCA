library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.rv_components.all;

entity riscV_xil is

  generic (
    REGISTER_SIZE      : integer              := 32;
    RESET_VECTOR       : natural              := 16#00000000#;
    MULTIPLY_ENABLE    : natural range 0 to 1 := 0;
    DIVIDE_ENABLE      : natural range 0 to 1 := 0;
    SHIFTER_MAX_CYCLES : natural              := 1;
    COUNTER_LENGTH     : natural              := 64;
    ENABLE_EXCEPTIONS  : natural              := 1;
    BRANCH_PREDICTORS  : natural              := 0;
    PIPELINE_STAGES    : natural range 4 to 5 := 5;
    LVE_ENABLE         : natural range 0 to 1 := 0;
    ENABLE_EXT_INTERRUPTS : natural range 0 to 1 := 0;
    NUM_EXT_INTERRUPTS : natural range 1 to 32 := 1;
    SCRATCHPAD_ADDR_BITS : integer            := 10;
    FORWARD_ALU_ONLY   : natural range 0 to 1 := 1;
    IRAM_SIZE          : natural              := 8192;
    BYTE_SIZE          : integer              := 8);

  port (clk : in std_logic;
        clk_2x : in std_logic;
        reset : in std_logic;
        
        data_AWID    : out std_logic_vector(3 downto 0);
        data_AWADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
        data_AWLEN   : out std_logic_vector(3 downto 0);
        data_AWSIZE  : out std_logic_vector(2 downto 0);
        data_AWBURST : out std_logic_vector(1 downto 0); 
        
        data_AWLOCK  : out std_logic_vector(1 downto 0);
        data_AWCACHE : out std_logic_vector(3 downto 0);
        data_AWPROT  : out std_logic_vector(2 downto 0);
        data_AWVALID : out std_logic;
        data_AWREADY : in std_logic;

        data_WID     : out std_logic_vector(3 downto 0);
        data_WDATA   : out std_logic_vector(REGISTER_SIZE -1 downto 0);
        data_WSTRB   : out std_logic_vector(REGISTER_SIZE/BYTE_SIZE -1 downto 0);
        data_WLAST   : out std_logic;
        data_WVALID  : out std_logic;
        data_WREADY  : in std_logic;

        data_BID     : in std_logic_vector(3 downto 0);
        data_BRESP   : in std_logic_vector(1 downto 0);
        data_BVALID  : in std_logic;
        data_BREADY  : out std_logic;

        data_ARID    : out std_logic_vector(3 downto 0);
        data_ARADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
        data_ARLEN   : out std_logic_vector(3 downto 0);
        data_ARSIZE  : out std_logic_vector(2 downto 0);
        data_ARBURST : out std_logic_vector(1 downto 0);
        data_ARLOCK  : out std_logic_vector(1 downto 0);
        data_ARCACHE : out std_logic_vector(3 downto 0);
        data_ARPROT  : out std_logic_vector(2 downto 0);
        data_ARVALID : out std_logic;
        data_ARREADY : in std_logic;

        data_RID     : in std_logic_vector(3 downto 0);
        data_RDATA   : in std_logic_vector(REGISTER_SIZE -1 downto 0);
        data_RRESP   : in std_logic_vector(1 downto 0);
        data_RLAST   : in std_logic;
        data_RVALID  : in std_logic;
        data_RREADY  : out std_logic;
        
        instr_AWID    : out std_logic_vector(3 downto 0);
        instr_AWADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
        instr_AWLEN   : out std_logic_vector(3 downto 0);
        instr_AWSIZE  : out std_logic_vector(2 downto 0);
        instr_AWBURST : out std_logic_vector(1 downto 0); 

        instr_AWLOCK  : out std_logic_vector(1 downto 0);
        instr_AWCACHE : out std_logic_vector(3 downto 0);
        instr_AWPROT  : out std_logic_vector(2 downto 0);
        instr_AWVALID : out std_logic;
        instr_AWREADY : in std_logic;

        instr_WID     : out std_logic_vector(3 downto 0);
        instr_WDATA   : out std_logic_vector(REGISTER_SIZE -1 downto 0);
        instr_WSTRB   : out std_logic_vector(REGISTER_SIZE/BYTE_SIZE -1 downto 0);
        instr_WLAST   : out std_logic;
        instr_WVALID  : out std_logic;
        instr_WREADY  : in std_logic;

        instr_BID     : in std_logic_vector(3 downto 0);
        instr_BRESP   : in std_logic_vector(1 downto 0);
        instr_BVALID  : in std_logic;
        instr_BREADY  : out std_logic;

        instr_ARID    : out std_logic_vector(3 downto 0);
        instr_ARADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
        instr_ARLEN   : out std_logic_vector(3 downto 0);
        instr_ARSIZE  : out std_logic_vector(2 downto 0);
        instr_ARBURST : out std_logic_vector(1 downto 0);
        instr_ARLOCK  : out std_logic_vector(1 downto 0);
        instr_ARCACHE : out std_logic_vector(3 downto 0);
        instr_ARPROT  : out std_logic_vector(2 downto 0);
        instr_ARVALID : out std_logic;
        instr_ARREADY : in std_logic;

        instr_RID     : in std_logic_vector(3 downto 0);
        instr_RDATA   : in std_logic_vector(REGISTER_SIZE -1 downto 0);
        instr_RRESP   : in std_logic_vector(1 downto 0);
        instr_RLAST   : in std_logic;
        instr_RVALID  : in std_logic;
        instr_RREADY  : out std_logic
      );

end entity riscV_xil;

architecture rtl of riscV_xil is
  signal orca_reset             : std_logic;
begin
  rv : component orca 
    generic map (
      REGISTER_SIZE         => REGISTER_SIZE,
      AVALON_ENABLE         => 0,
      WISHBONE_ENABLE       => 0,
      AXI_ENABLE            => 1,
      RESET_VECTOR          => RESET_VECTOR,
      MULTIPLY_ENABLE       => MULTIPLY_ENABLE,
      DIVIDE_ENABLE         => DIVIDE_ENABLE,
      SHIFTER_MAX_CYCLES    => SHIFTER_MAX_CYCLES,
      COUNTER_LENGTH        => COUNTER_LENGTH,
      ENABLE_EXCEPTIONS     => ENABLE_EXCEPTIONS,
      BRANCH_PREDICTORS     => BRANCH_PREDICTORS,
      PIPELINE_STAGES       => PIPELINE_STAGES,
      LVE_ENABLE            => LVE_ENABLE,
      ENABLE_EXT_INTERRUPTS => ENABLE_EXT_INTERRUPTS,
      NUM_EXT_INTERRUPTS    => NUM_EXT_INTERRUPTS,
      SCRATCHPAD_ADDR_BITS  => SCRATCHPAD_ADDR_BITS,
      FAMILY                => "XILINX")
    port map (
      clk => clk,
      scratchpad_clk => clk_2x,
      reset => reset,

      -- Avalon Data Bus
      avm_data_address              => OPEN, 
      avm_data_byteenable           => OPEN, 
      avm_data_read                 => OPEN, 
      avm_data_readdata             => (others => '-'), 
      avm_data_write                => OPEN, 
      avm_data_writedata            => OPEN, 
      avm_data_waitrequest          => '-', 
      avm_data_readdatavalid        => '-', 
      -- Avalon instruction bus
      avm_instruction_address       => OPEN, 
      avm_instruction_read          => OPEN, 
      avm_instruction_readdata      => OPEN, 
      avm_instruction_waitrequest   => '-', 
      avm_instruction_readdatavalid => OPEN, 
      -- Wishbone Data Bus
      data_ADR_O                    => OPEN, 
      data_DAT_I                    => (others => '-'), 
      data_DAT_O                    => OPEN, 
      data_WE_O                     => OPEN, 
      data_SEL_O                    => OPEN, 
      data_STB_O                    => OPEN, 
      data_ACK_I                    => '-', 
      data_CYC_O                    => OPEN, 
      data_CTI_O                    => OPEN, 
      data_STALL_I                  => '-', 
      -- Wishbone Instruction Bus
      instr_ADR_O                   => OPEN, 
      instr_DAT_I                   => (others => '-'), 
      instr_STB_O                   => OPEN, 
      instr_ACK_I                   => '-', 
      instr_CYC_O                   => OPEN, 
      instr_CTI_O                   => OPEN, 
      instr_STALL_I                 => '-', 
      -- AXI Write Address Channel
      data_AWID                     => data_AWID, 
      data_AWADDR                   => data_AWADDR,
      data_AWLEN                    => data_AWLEN, 
      data_AWSIZE                   => data_AWSIZE, 
      data_AWBURST                  => data_AWBURST,
      data_AWLOCK                   => data_AWLOCK, 
      data_AWCACHE                  => data_AWCACHE,
      data_AWPROT                   => data_AWPROT, 
      data_AWVALID                  => data_AWVALID,
      data_AWREADY                  => data_AWREADY,
      -- AXI Write Data Channel
      data_WID                      => data_WID, 
      data_WDATA                    => data_WDATA, 
      data_WSTRB                    => data_WSTRB, 
      data_WLAST                    => data_WLAST, 
      data_WVALID                   => data_WVALID, 
      data_WREADY                   => data_WREADY, 
      -- AXI Write Response Channel
      data_BID                      => data_BID, 
      data_BRESP                    => data_BRESP,
      data_BVALID                   => data_BVALID,
      data_BREADY                   => data_BREADY, 
      -- AXI Read address channel
      data_ARID                     => data_ARID, 
      data_ARADDR                   => data_ARADDR, 
      data_ARLEN                    => data_ARLEN, 
      data_ARSIZE                   => data_ARSIZE, 
      data_ARBURST                  => data_ARBURST, 
      data_ARLOCK                   => data_ARLOCK, 
      data_ARCACHE                  => data_ARCACHE, 
      data_ARPROT                   => data_ARPROT, 
      data_ARVALID                  => data_ARVALID, 
      data_ARREADY                  => data_ARREADY, 
      -- AXI Read Data Channel
      data_RID                      => data_RID, 
      data_RDATA                    => data_RDATA, 
      data_RRESP                    => data_RRESP, 
      data_RLAST                    => data_RLAST, 
      data_RVALID                   => data_RVALID, 
      data_RREADY                   => data_RREADY, 
      -- AXI Instruction Read Address Channel 
      instr_ARID                    => instr_ARID,     
      instr_ARADDR                  => instr_ARADDR,  
      instr_ARLEN                   => instr_ARLEN,   
      instr_ARSIZE                  => instr_ARSIZE,  
      instr_ARBURST                 => instr_ARBURST, 
      instr_ARLOCK                  => instr_ARLOCK, 
      instr_ARCACHE                 => instr_ARCACHE, 
      instr_ARPROT                  => instr_ARPROT,  
      instr_ARVALID                 => instr_ARVALID, 
      instr_ARREADY                 => instr_ARREADY, 
      -- AXI Instruction Read Data Channel
      instr_RID                     => instr_RID,
      instr_RDATA                   => instr_RDATA,
      instr_RRESP                   => instr_RRESP,
      instr_RLAST                   => instr_RLAST,
      instr_RVALID                  => instr_RVALID,
      instr_RREADY                  => instr_RREADY,
      -- AXI Instruction Write Address Channel
      instr_AWID                    => instr_AWID,
      instr_AWADDR                  => instr_AWADDR,
      instr_AWLEN                   => instr_AWLEN,
      instr_AWSIZE                  => instr_AWSIZE,
      instr_AWBURST                 => instr_AWBURST,
      instr_AWLOCK                  => instr_AWLOCK,
      instr_AWCACHE                 => instr_AWCACHE,
      instr_AWPROT                  => instr_AWPROT,
      instr_AWVALID                 => instr_AWVALID,
      instr_AWREADY                 => instr_AWREADY,
      -- AXI Instruction Write Data Channel
      instr_WID                     =>  instr_WID,
      instr_WDATA                   =>  instr_WDATA,
      instr_WSTRB                   =>  instr_WSTRB,
      instr_WLAST                   =>  instr_WLAST,
      instr_WVALID                  =>  instr_WVALID,
      instr_WREADY                  =>  instr_WREADY,
      -- AXI Instruction Write Response Channel
      instr_BID                     =>  instr_BID,
      instr_BRESP                   =>  instr_BRESP ,
      instr_BVALID                  =>  instr_BVALID,
      instr_BREADY                  =>  instr_BREADY,
      -- Avalon Scratchpad Slave
      avm_scratch_address           => (others => '-'), 
      avm_scratch_byteenable        => (others => '-'), 
      avm_scratch_read              => '-', 
      avm_scratch_readdata          => OPEN, 
      avm_scratch_write             => '-', 
      avm_scratch_writedata         => (others => '-'), 
      avm_scratch_waitrequest       => OPEN, 
      avm_scratch_readdatavalid     => OPEN, 
      -- Wishbone Scratchpad Slave
      sp_ADR_I                      => (others => '-'),
      sp_DAT_O                      => OPEN, 
      sp_DAT_I                      => (others => '-'), 
      sp_WE_I                       => '-', 
      sp_SEL_I                      => (others => '-'), 
      sp_STB_I                      => '-', 
      sp_ACK_O                      => OPEN, 
      sp_CYC_I                      => '-', 
      sp_CTI_I                      => (others => '-'),
      sp_STALL_O                    => OPEN, 
      -- Interupt Vector
      global_interrupts             => (others => '0')
      );


end architecture rtl;



