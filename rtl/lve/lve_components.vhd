library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.utils.all;
use work.constants_pkg.all;

package lve_components is
  constant LVE_WIDTH : natural := 32;
  component lve_top is
    generic (
      POWER_OPTIMIZED      : integer              := 0;
      SCRATCHPAD_ADDR_BITS : integer              := 16;
      AXI_ENABLE           : integer range 0 to 1 := 0;
      WISHBONE_ENABLE      : integer range 0 to 1 := 0);
    port (
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;


      --WISHBONE data SLAVE
      slave_ADR_I   : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0) := (others => '0');
      slave_DAT_O   : out std_logic_vector(LVE_WIDTH-1 downto 0);
      slave_DAT_I   : in  std_logic_vector(LVE_WIDTH-1 downto 0)            := (others => '0');
      slave_WE_I    : in  std_logic                                         := '0';
      slave_SEL_I   : in  std_logic_vector((LVE_WIDTH/8)-1 downto 0)        := (others => '0');
      slave_STB_I   : in  std_logic                                         := '0';
      slave_ACK_O   : out std_logic;
      slave_CYC_I   : in  std_logic                                         := '0';
      slave_CTI_I   : in  std_logic_vector(2 downto 0)                      := (others => '0');
      slave_STALL_O : out std_logic;

      -------------------------------------------------------------------------------
      --AXI
      -------------------------------------------------------------------------------
      --AXI4-Lite slave port
      --A full AXI3 interface is exposed for systems that require it, but
      --only the A4L signals are needed
      slave_ARID    : in  std_logic_vector(3 downto 0)                      := (others => '0');
      slave_ARADDR  : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0) := (others => '0');
      slave_ARLEN   : in  std_logic_vector(3 downto 0)                      := (others => '0');
      slave_ARSIZE  : in  std_logic_vector(2 downto 0)                      := (others => '0');
      slave_ARBURST : in  std_logic_vector(1 downto 0)                      := (others => '0');
      slave_ARLOCK  : in  std_logic_vector(1 downto 0)                      := (others => '0');
      slave_ARCACHE : in  std_logic_vector(3 downto 0)                      := (others => '0');
      slave_ARPROT  : in  std_logic_vector(2 downto 0)                      := (others => '0');
      slave_ARVALID : in  std_logic                                         := '0';
      slave_ARREADY : out std_logic;

      slave_RID    : out std_logic_vector(3 downto 0);
      slave_RDATA  : out std_logic_vector(LVE_WIDTH-1 downto 0);
      slave_RRESP  : out std_logic_vector(1 downto 0);
      slave_RLAST  : out std_logic;
      slave_RVALID : out std_logic;
      slave_RREADY : in  std_logic := '0';

      slave_AWID    : in  std_logic_vector(3 downto 0)                      := (others => '0');
      slave_AWADDR  : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0) := (others => '0');
      slave_AWLEN   : in  std_logic_vector(3 downto 0)                      := (others => '0');
      slave_AWSIZE  : in  std_logic_vector(2 downto 0)                      := (others => '0');
      slave_AWBURST : in  std_logic_vector(1 downto 0)                      := (others => '0');
      slave_AWLOCK  : in  std_logic_vector(1 downto 0)                      := (others => '0');
      slave_AWCACHE : in  std_logic_vector(3 downto 0)                      := (others => '0');
      slave_AWPROT  : in  std_logic_vector(2 downto 0)                      := (others => '0');
      slave_AWVALID : in  std_logic                                         := '0';
      slave_AWREADY : out std_logic;

      slave_WID    : in  std_logic_vector(3 downto 0)               := (others => '0');
      slave_WDATA  : in  std_logic_vector(LVE_WIDTH-1 downto 0)     := (others => '0');
      slave_WSTRB  : in  std_logic_vector((LVE_WIDTH/8)-1 downto 0) := (others => '0');
      slave_WLAST  : in  std_logic                                  := '0';
      slave_WVALID : in  std_logic                                  := '0';
      slave_WREADY : out std_logic;

      slave_BID    : out std_logic_vector(3 downto 0);
      slave_BRESP  : out std_logic_vector(1 downto 0);
      slave_BVALID : out std_logic;
      slave_BREADY : in  std_logic := '0';

      vcp_data0 : in std_logic_vector(LVE_WIDTH-1 downto 0);
      vcp_data1 : in std_logic_vector(LVE_WIDTH-1 downto 0);
      vcp_data2 : in std_logic_vector(LVE_WIDTH-1 downto 0);

      vcp_instruction      : in  std_logic_vector(40 downto 0)          := (others => '0');
      vcp_valid_instr      : in  std_logic                              := '0';
      vcp_writeback_data   : out std_logic_vector(31 downto 0);
      vcp_writeback_en     : out std_logic;
      vcp_ready            : out std_logic;
      vcp_executing        : out std_logic;
      vcp_alu_data1        : out std_logic_vector(LVE_WIDTH-1 downto 0);
      vcp_alu_data2        : out std_logic_vector(LVE_WIDTH-1 downto 0);
      vcp_alu_op_size      : out std_logic_vector(1 downto 0);
      vcp_alu_source_valid : out std_logic;
      vcp_alu_result       : in  std_logic_vector(LVE_WIDTH-1 downto 0) := (others => '0');
      vcp_alu_result_valid : in  std_logic                              := '0'
      );
  end component;

  component lve_core is
    generic (
      POWER_OPTIMIZED : integer;
      SCRATCHPAD_SIZE : integer);
    port (
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;
      instruction    : in std_logic_vector(31 downto 0);
      valid_instr    : in std_logic;



      slave_address  : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
      slave_read_en  : in  std_logic;
      slave_write_en : in  std_logic;
      slave_byte_en  : in  std_logic_vector((LVE_WIDTH/8)-1 downto 0);
      slave_data_in  : in  std_logic_vector(LVE_WIDTH-1 downto 0);
      slave_data_out : out std_logic_vector(LVE_WIDTH-1 downto 0);
      slave_ack      : out std_logic;

      rs1_data : in std_logic_vector(LVE_WIDTH-1 downto 0);
      rs2_data : in std_logic_vector(LVE_WIDTH-1 downto 0);
      rs3_data : in std_logic_vector(LVE_WIDTH-1 downto 0);

      lve_ready            : out    std_logic;
      lve_executing        : out    std_logic;
      lve_writeback_data   : out    std_logic_vector(31 downto 0);
      lve_writeback_en     : out    std_logic;
      lve_alu_data1        : buffer std_logic_vector(LVE_WIDTH-1 downto 0);
      lve_alu_data2        : buffer std_logic_vector(LVE_WIDTH-1 downto 0);
      lve_alu_op_size      : out    std_logic_vector(1 downto 0);
      lve_alu_source_valid : out    std_logic;
      lve_alu_result       : in     std_logic_vector(LVE_WIDTH-1 downto 0);
      lve_alu_result_valid : in     std_logic
      );
  end component;
  type VCUSTOM_ENUM is (VCUSTOM0, VCUSTOM1, VCUSTOM2, VCUSTOM3, VCUSTOM4, VCUSTOM5, VCUSTOM6, VCUSTOM7);
  component lve_ci is
    port (
      clk   : in std_logic;
      reset : in std_logic;

      func : VCUSTOM_ENUM;

      pause : in std_logic;

      valid_in : in std_logic;
      data1_in : in std_logic_vector(LVE_WIDTH-1 downto 0);
      data2_in : in std_logic_vector(LVE_WIDTH-1 downto 0);

      align1_in : in std_logic_vector(1 downto 0);
      align2_in : in std_logic_vector(1 downto 0);

      valid_out        : out std_logic;
      byte_en_out      : out std_logic_vector(3 downto 0);
      write_enable_out : out std_logic;
      data_out         : out std_logic_vector(LVE_WIDTH-1 downto 0)
      );
  end component;
  component ram_4port is
    generic (
      MEM_DEPTH       : natural;
      MEM_WIDTH       : natural;
      POWER_OPTIMIZED : boolean
      );
    port (
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;

      pause_lve_in  : in  std_logic;
      pause_lve_out : out std_logic;
                                        --read source A
      raddr0        : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      ren0          : in  std_logic;
      scalar_value  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      scalar_enable : in  std_logic;
      data_out0     : out std_logic_vector(MEM_WIDTH-1 downto 0);
                                        --read source B
      raddr1        : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      ren1          : in  std_logic;
      enum_value    : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      enum_enable   : in  std_logic;
      data_out1     : out std_logic_vector(MEM_WIDTH-1 downto 0);
      ack01         : out std_logic;
                                        --write dest
      waddr2        : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      byte_en2      : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      wen2          : in  std_logic;
      data_in2      : in  std_logic_vector(MEM_WIDTH-1 downto 0);
                                        --external slave port
      rwaddr3       : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      wen3          : in  std_logic;
      ren3          : in  std_logic;    --cannot be asserted same cycle as wen3
      byte_en3      : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      data_in3      : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      ack3          : out std_logic;
      data_out3     : out std_logic_vector(MEM_WIDTH-1 downto 0)
      );
  end component;

end package lve_components;
