library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.utils.all;
use work.constants_pkg.all;

package lve_components is
  constant LVE_WIDTH    : natural := 32;
  component lve_core is
    generic (
      POWER_OPTIMIZED  : integer;
      SCRATCHPAD_SIZE  : integer);
    port (
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;
      instruction    : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
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
      POWER_OPTIMIZED : boolean;
      FAMILY          : string
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
