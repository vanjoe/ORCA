library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.idram_components.all;
use work.idram_utils.all;

entity idram is
  generic (
    --Port types: 0 = AXI4Lite, 1 = AXI3, 2 = AXI4
    INSTR_PORT_TYPE : natural range 0 to 2 := 0;
    DATA_PORT_TYPE  : natural range 0 to 2 := 0;
    SIZE            : integer              := 32768;
    RAM_WIDTH       : integer              := 32;
    ADDR_WIDTH      : integer              := 32
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    instr_AWID    : in std_logic_vector(13 downto 0);
    instr_AWADDR  : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    instr_AWLEN   : in std_logic_vector(7-(4*(INSTR_PORT_TYPE mod 2)) downto 0);
    instr_AWSIZE  : in std_logic_vector(2 downto 0);
    instr_AWBURST : in std_logic_vector(1 downto 0);

    instr_AWLOCK  : in  std_logic_vector(1 downto 0);
    instr_AWCACHE : in  std_logic_vector(3 downto 0);
    instr_AWPROT  : in  std_logic_vector(2 downto 0);
    instr_AWVALID : in  std_logic;
    instr_AWREADY : out std_logic;

    instr_WID    : in  std_logic_vector(13 downto 0);
    instr_WDATA  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
    instr_WSTRB  : in  std_logic_vector((RAM_WIDTH/8)-1 downto 0);
    instr_WLAST  : in  std_logic;
    instr_WVALID : in  std_logic;
    instr_WREADY : out std_logic;

    instr_BID    : out std_logic_vector(13 downto 0);
    instr_BRESP  : out std_logic_vector(1 downto 0);
    instr_BVALID : out std_logic;
    instr_BREADY : in  std_logic;

    instr_ARID    : in  std_logic_vector(13 downto 0);
    instr_ARADDR  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    instr_ARLEN   : in  std_logic_vector(7-(4*(INSTR_PORT_TYPE mod 2)) downto 0);
    instr_ARSIZE  : in  std_logic_vector(2 downto 0);
    instr_ARBURST : in  std_logic_vector(1 downto 0);
    instr_ARLOCK  : in  std_logic_vector(1 downto 0);
    instr_ARCACHE : in  std_logic_vector(3 downto 0);
    instr_ARPROT  : in  std_logic_vector(2 downto 0);
    instr_ARVALID : in  std_logic;
    instr_ARREADY : out std_logic;

    instr_RID    : out std_logic_vector(13 downto 0);
    instr_RDATA  : out std_logic_vector(RAM_WIDTH-1 downto 0);
    instr_RRESP  : out std_logic_vector(1 downto 0);
    instr_RLAST  : out std_logic;
    instr_RVALID : out std_logic;
    instr_RREADY : in  std_logic;

    data_AWID    : in std_logic_vector(13 downto 0);
    data_AWADDR  : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    data_AWLEN   : in std_logic_vector(7-(4*(DATA_PORT_TYPE mod 2)) downto 0);
    data_AWSIZE  : in std_logic_vector(2 downto 0);
    data_AWBURST : in std_logic_vector(1 downto 0);

    data_AWLOCK  : in  std_logic_vector(1 downto 0);
    data_AWCACHE : in  std_logic_vector(3 downto 0);
    data_AWPROT  : in  std_logic_vector(2 downto 0);
    data_AWVALID : in  std_logic;
    data_AWREADY : out std_logic;

    data_WID    : in  std_logic_vector(13 downto 0);
    data_WDATA  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
    data_WSTRB  : in  std_logic_vector((RAM_WIDTH/8)-1 downto 0);
    data_WLAST  : in  std_logic;
    data_WVALID : in  std_logic;
    data_WREADY : out std_logic;

    data_BID    : out std_logic_vector(13 downto 0);
    data_BRESP  : out std_logic_vector(1 downto 0);
    data_BVALID : out std_logic;
    data_BREADY : in  std_logic;

    data_ARID    : in  std_logic_vector(13 downto 0);
    data_ARADDR  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    data_ARLEN   : in  std_logic_vector(7-(4*(DATA_PORT_TYPE mod 2)) downto 0);
    data_ARSIZE  : in  std_logic_vector(2 downto 0);
    data_ARBURST : in  std_logic_vector(1 downto 0);
    data_ARLOCK  : in  std_logic_vector(1 downto 0);
    data_ARCACHE : in  std_logic_vector(3 downto 0);
    data_ARPROT  : in  std_logic_vector(2 downto 0);
    data_ARVALID : in  std_logic;
    data_ARREADY : out std_logic;

    data_RID    : out std_logic_vector(13 downto 0);
    data_RDATA  : out std_logic_vector(RAM_WIDTH-1 downto 0);
    data_RRESP  : out std_logic_vector(1 downto 0);
    data_RLAST  : out std_logic;
    data_RVALID : out std_logic;
    data_RREADY : in  std_logic
    );
end entity idram;

architecture rtl of idram is

  constant BYTES_PER_WORD : integer := RAM_WIDTH/8;

  signal address  : std_logic_vector(log2(SIZE/BYTES_PER_WORD)-1 downto 0);
  signal write_en : std_logic;

  signal instr_AWREADY_internal   : std_logic;
  signal instr_WREADY_internal    : std_logic;
  signal instr_BVALID_internal    : std_logic;
  signal instr_ARREADY_internal   : std_logic;
  signal instr_RVALID_internal    : std_logic;
  signal instr_address            : std_logic_vector(log2(SIZE/BYTES_PER_WORD)-1 downto 0);
  signal instr_read_en            : std_logic;
  signal instr_write_en           : std_logic;
  signal instr_byte_sel           : std_logic_vector(RAM_WIDTH/8-1 downto 0);
  signal instr_en                 : std_logic;
  signal instr_read_resp_stalled  : std_logic;
  signal instr_write_resp_stalled : std_logic;

  signal data_AWREADY_internal   : std_logic;
  signal data_WREADY_internal    : std_logic;
  signal data_BVALID_internal    : std_logic;
  signal data_ARREADY_internal   : std_logic;
  signal data_RVALID_internal    : std_logic;
  signal data_address            : std_logic_vector(log2(SIZE/BYTES_PER_WORD)-1 downto 0);
  signal data_read_en            : std_logic;
  signal data_write_en           : std_logic;
  signal data_byte_sel           : std_logic_vector(RAM_WIDTH/8-1 downto 0);
  signal data_en                 : std_logic;
  signal data_read_resp_stalled  : std_logic;
  signal data_write_resp_stalled : std_logic;
begin
  instr_RRESP            <= (others => '0');
  instr_BRESP            <= (others => '0');
  instr_ARREADY_internal <= (not reset) and (not instr_read_resp_stalled);
  instr_ARREADY          <= instr_ARREADY_internal;
  instr_AWREADY_internal <= (not reset) and
                            (((not instr_ARREADY_internal) or (not instr_ARVALID)) and (not instr_write_resp_stalled));
  instr_AWREADY         <= instr_AWREADY_internal;
  instr_WREADY_internal <= instr_AWREADY_internal;
  instr_WREADY          <= instr_WREADY_internal;
  instr_address <=
    instr_ARADDR(instr_address'left+log2(BYTES_PER_WORD) downto log2(BYTES_PER_WORD)) when
    instr_read_en = '1' else
    instr_AWADDR(data_address'left+log2(BYTES_PER_WORD) downto log2(BYTES_PER_WORD));
  instr_read_en            <= instr_ARVALID and instr_ARREADY_internal;
  instr_write_en           <= instr_AWVALID and instr_WVALID and instr_AWREADY_internal and instr_WREADY_internal;
  instr_byte_sel           <= (others => '1') when instr_read_en = '1' else instr_WSTRB;
  instr_en                 <= instr_write_en or instr_read_en;
  instr_read_resp_stalled  <= instr_RVALID_internal and (not instr_RREADY);
  instr_RVALID             <= instr_RVALID_internal;
  instr_write_resp_stalled <= instr_BVALID_internal and (not instr_BREADY);
  instr_BVALID             <= instr_BVALID_internal;

  data_RRESP            <= (others => '0');
  data_BRESP            <= (others => '0');
  data_ARREADY_internal <= (not reset) and (not data_read_resp_stalled);
  data_ARREADY          <= data_ARREADY_internal;
  data_AWREADY_internal <= (not reset) and
                           (((not data_ARREADY_internal) or (not data_ARVALID)) and (not data_write_resp_stalled));
  data_AWREADY         <= data_AWREADY_internal;
  data_WREADY_internal <= data_AWREADY_internal;
  data_WREADY          <= data_WREADY_internal;
  data_address <=
    data_ARADDR(data_address'left+log2(BYTES_PER_WORD) downto log2(BYTES_PER_WORD)) when
    data_read_en = '1' else
    data_AWADDR(data_address'left+log2(BYTES_PER_WORD) downto log2(BYTES_PER_WORD));
  data_read_en            <= data_ARVALID and data_ARREADY_internal;
  data_write_en           <= data_AWVALID and data_WVALID and data_AWREADY_internal and data_WREADY_internal;
  data_byte_sel           <= (others => '1') when data_read_en = '1' else data_WSTRB;
  data_en                 <= data_write_en or data_read_en;
  data_read_resp_stalled  <= data_RVALID_internal and (not data_RREADY);
  data_RVALID             <= data_RVALID_internal;
  data_write_resp_stalled <= data_BVALID_internal and (not data_BREADY);
  data_BVALID             <= data_BVALID_internal;

  instruction_port : process(clk)
  begin
    if rising_edge(clk) then
      if instr_RREADY = '1' then
        instr_RVALID_internal <= '0';
      end if;
      if instr_read_en = '1' then
        instr_RVALID_internal <= '1';
        instr_RID             <= instr_ARID;
      end if;

      if instr_BREADY = '1' then
        instr_BVALID_internal <= '0';
      end if;
      if instr_write_en = '1' then
        instr_BVALID_internal <= '1';
        instr_BID             <= instr_AWID;
      end if;

      if reset = '1' then
        instr_RVALID_internal <= '0';
        instr_BVALID_internal <= '0';
      end if;
    end if;
  end process;

  data_port : process(clk)
  begin
    if rising_edge(clk) then
      if data_RREADY = '1' then
        data_RVALID_internal <= '0';
      end if;
      if data_read_en = '1' then
        data_RVALID_internal <= '1';
      end if;

      if data_BREADY = '1' then
        data_BVALID_internal <= '0';
      end if;
      if data_write_en = '1' then
        data_BVALID_internal <= '1';
      end if;

      if reset = '1' then
        data_RVALID_internal <= '0';
        data_BVALID_internal <= '0';
      end if;
    end if;
  end process;

  ram : component idram_xilinx
    generic map (
      RAM_DEPTH => SIZE/4,
      RAM_WIDTH => RAM_WIDTH
      )
    port map (
      clk => clk,

      instr_address  => instr_address,
      instr_data_in  => instr_WDATA,
      instr_we       => instr_write_en,
      instr_en       => instr_en,
      instr_be       => instr_byte_sel,
      instr_readdata => instr_RDATA,

      data_address  => data_address,
      data_data_in  => data_WDATA,
      data_we       => data_write_en,
      data_en       => data_en,
      data_be       => data_byte_sel,
      data_readdata => data_RDATA
      );

  --Only valid for A4L, needs fixing for AXI3/AXI4
  instr_RLAST <= '1';
  data_RLAST  <= '1';

end architecture rtl;
