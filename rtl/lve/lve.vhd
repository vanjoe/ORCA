library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

library work;
use work.utils.all;
use work.constants_pkg.all;
use work.lve_components.all;


entity lve_top is
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
    slave_ADR_I   : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
    slave_DAT_O   : out std_logic_vector(LVE_WIDTH-1 downto 0) := (others => '0');
    slave_DAT_I   : in  std_logic_vector(LVE_WIDTH-1 downto 0);
    slave_WE_I    : in  std_logic;
    slave_SEL_I   : in  std_logic_vector((LVE_WIDTH/8)-1 downto 0);
    slave_STB_I   : in  std_logic;
    slave_ACK_O   : out std_logic                              := '0';
    slave_CYC_I   : in  std_logic;
    slave_CTI_I   : in  std_logic_vector(2 downto 0);
    slave_STALL_O : out std_logic                              := '0';

    -------------------------------------------------------------------------------
    --AXI
    -------------------------------------------------------------------------------
    --AXI4-Lite slave port
    --A full AXI3 interface is exposed for systems that require it, but
    --only the A4L signals are needed
    slave_ARID    : in  std_logic_vector(3 downto 0);
    slave_ARADDR  : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
    slave_ARLEN   : in  std_logic_vector(3 downto 0);
    slave_ARSIZE  : in  std_logic_vector(2 downto 0);
    slave_ARBURST : in  std_logic_vector(1 downto 0);
    slave_ARLOCK  : in  std_logic_vector(1 downto 0);
    slave_ARCACHE : in  std_logic_vector(3 downto 0);
    slave_ARPROT  : in  std_logic_vector(2 downto 0);
    slave_ARVALID : in  std_logic;
    slave_ARREADY : out std_logic;

    slave_RID    : out std_logic_vector(3 downto 0);
    slave_RDATA  : out std_logic_vector(LVE_WIDTH-1 downto 0);
    slave_RRESP  : out std_logic_vector(1 downto 0);
    slave_RLAST  : out std_logic;
    slave_RVALID : out std_logic;
    slave_RREADY : in  std_logic;

    slave_AWID    : in  std_logic_vector(3 downto 0);
    slave_AWADDR  : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
    slave_AWLEN   : in  std_logic_vector(3 downto 0);
    slave_AWSIZE  : in  std_logic_vector(2 downto 0);
    slave_AWBURST : in  std_logic_vector(1 downto 0);
    slave_AWLOCK  : in  std_logic_vector(1 downto 0);
    slave_AWCACHE : in  std_logic_vector(3 downto 0);
    slave_AWPROT  : in  std_logic_vector(2 downto 0);
    slave_AWVALID : in  std_logic;
    slave_AWREADY : out std_logic;

    slave_WID    : in  std_logic_vector(3 downto 0);
    slave_WDATA  : in  std_logic_vector(LVE_WIDTH-1 downto 0);
    slave_WSTRB  : in  std_logic_vector((LVE_WIDTH/8)-1 downto 0);
    slave_WLAST  : in  std_logic;
    slave_WVALID : in  std_logic;
    slave_WREADY : out std_logic;

    slave_BID    : out std_logic_vector(3 downto 0);
    slave_BRESP  : out std_logic_vector(1 downto 0);
    slave_BVALID : out std_logic;
    slave_BREADY : in  std_logic;

    vcp_data0 : in std_logic_vector(LVE_WIDTH-1 downto 0);
    vcp_data1 : in std_logic_vector(LVE_WIDTH-1 downto 0);
    vcp_data2 : in std_logic_vector(LVE_WIDTH-1 downto 0);

    vcp_instruction      : in  std_logic_vector(40 downto 0);
    vcp_valid_instr      : in  std_logic;
    vcp_writeback_data   : out std_logic_vector(31 downto 0);
    vcp_writeback_en     : out std_logic;
    vcp_ready            : out std_logic;
    vcp_alu_data1        : out std_logic_vector(LVE_WIDTH-1 downto 0);
    vcp_alu_data2        : out std_logic_vector(LVE_WIDTH-1 downto 0);
    vcp_alu_op_size      : out std_logic_vector(1 downto 0);
    vcp_alu_source_valid : out std_logic;
    vcp_alu_result       : in  std_logic_vector(LVE_WIDTH-1 downto 0);
    vcp_alu_result_valid : in  std_logic
    );
end entity;

architecture rtl of lve_top is

  signal slave_address  : std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
  signal slave_read_en  : std_logic;
  signal slave_write_en : std_logic;
  signal slave_byte_en  : std_logic_vector((LVE_WIDTH/8)-1 downto 0);
  signal slave_data_in  : std_logic_vector(LVE_WIDTH-1 downto 0);
  signal slave_data_out : std_logic_vector(LVE_WIDTH-1 downto 0);
  signal slave_ack      : std_logic;

begin  -- architecture rtl

  assert (WISHBONE_ENABLE + AXI_ENABLE) = 1 report "Exactly one bus type must be enabled" severity failure;

  axi_handler : if AXI_ENABLE = 1 generate
    signal reading     : std_logic;
    signal writing     : std_logic;
    signal busy        : std_logic;
    signal ID_register : std_logic_vector(slave_rid'range);
  begin
    busy          <= reading or writing;
    slave_awready <= not busy and slave_awvalid and slave_wvalid;
    slave_wready  <= not busy and slave_awvalid and slave_wvalid;
    slave_arready <= not busy;

    slave_bvalid <= writing and slave_ack;
    slave_rvalid <= reading and slave_ack;
    slave_rdata  <= slave_data_out;
    slave_bid    <= ID_register;
    slave_rid    <= ID_register;

    slave_rresp <= (others => '0');
    slave_rlast <= '1';
    slave_bresp <= (others => '0');

    process (clk) is
    begin  -- process
      if rising_edge(clk) then          -- rising clock edge
        slave_address <= slave_awaddr;
        if slave_arvalid = '1' then
          slave_address <= slave_araddr;
        end if;
        slave_data_in  <= slave_wdata;
        slave_byte_en  <= slave_wstrb;
        slave_read_en  <= slave_arvalid and not busy;
        slave_write_en <= slave_awvalid and slave_wvalid and not busy;
        if (slave_arvalid and not busy) = '1' then
          reading     <= '1';
          ID_register <= slave_arid;
        end if;
        if (slave_awvalid and slave_wvalid and not busy) = '1' then
          writing     <= '1';
          ID_register <= slave_awid;
        end if;
        if slave_ack = '1' then
          reading <= '0';
          writing <= '0';
        end if;
        if reset = '1' then
          reading     <= '0';
          writing     <= '0';
          ID_register <= (others => '0');
        end if;
      end if;
    end process;

  end generate axi_handler;

  wishbone_handler : if WISHBONE_ENABLE = 1 generate

    --Inputs
    slave_address  <= slave_ADR_I;
    slave_write_en <= slave_STB_I and slave_CYC_I and slave_WE_I;
    slave_read_en  <= slave_STB_I and slave_CYC_I and not slave_WE_I;
    slave_byte_en  <= slave_SEL_I;
    slave_data_in  <= slave_DAT_I;
    --outputs
    slave_DAT_O    <= slave_data_out;
    slave_ack_O    <= slave_ack;
  end generate wishbone_handler;

  core : lve_core
    generic map (
      POWER_OPTIMIZED => POWER_OPTIMIZED,
      SCRATCHPAD_SIZE => 2**SCRATCHPAD_ADDR_BITS)

    port map (
      clk            => clk,
      scratchpad_clk => scratchpad_clk,
      reset          => reset,

      slave_address  => slave_address,
      slave_read_en  => slave_read_en,
      slave_write_en => slave_write_en,
      slave_byte_en  => slave_byte_en,
      slave_data_in  => slave_data_in,
      slave_data_out => slave_data_out,
      slave_ack      => slave_ack,

      rs1_data => vcp_data0,
      rs2_data => vcp_data1,
      rs3_data => vcp_data2,

      instruction          => vcp_instruction(31 downto 0),
      valid_instr          => vcp_valid_instr,
      lve_ready            => vcp_ready,
      lve_writeback_data   => vcp_writeback_data,
      lve_writeback_en      => vcp_writeback_en,
      lve_alu_data1        => vcp_alu_data1,
      lve_alu_data2        => vcp_alu_data2,
      lve_alu_op_size      => vcp_alu_op_size,
      lve_alu_source_valid => vcp_alu_source_valid,
      lve_alu_result       => vcp_alu_result,
      lve_alu_result_valid => vcp_alu_result_valid);



end architecture rtl;
