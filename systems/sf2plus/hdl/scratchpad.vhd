-- scratchpad.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;
use work.architecture_pkg.all;
use work.component_pkg.all;

entity scratchpad is
  generic (
    VECTOR_LANES  : integer := 1;
    SCRATCHPAD_KB : integer := 8;

    CFG_FAM : config_family_type;

    ADDR_WIDTH : integer := 1
    );
  port (
    clk    : in std_logic;
    reset  : in std_logic;
    clk_2x : in std_logic;

    scratch_port_a : in std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    scratch_port_b : in std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    scratch_port_c : in std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    scratch_port_d : in std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

    readdata_a : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    readdata_b : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    readdata_c : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    readdata_d : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
    );

  -- attribute secure_netlist     : string;  -- OFF, ENCRYPT, (PROHIBIT not allowed in Vivado)
  -- attribute secure_config      : string;  -- OFF, PROTECT
  -- attribute secure_net_editing : string;  -- OFF, PROHIBIT
  -- attribute secure_bitstream   : string;  -- OFF, PROHIBIT
  -- attribute secure_net_probing : string;  -- OFF, PROHIBIT
  -- attribute check_license      : string;

  -- attribute secure_netlist of scratchpad : entity is "OFF";
  -- attribute secure_config  of scratchpad : entity is "OFF";
  -- attribute check_license  of scratchpad : entity is "ipvblox_mxp";

end scratchpad;

architecture rtl of scratchpad is
  constant REG_BEFORE_RAM_ADDR_SEL : boolean := CFG_SEL(CFG_FAM).REG_BEFORE_RAM_ADDR_SEL;
  constant COMBI_SCRATCH_PORT_ADDR : boolean := CFG_SEL(CFG_FAM).COMBI_SCRATCH_PORT_ADDR;
  constant REG_RAM_ADDR_P1         : boolean := CFG_SEL(CFG_FAM).REG_RAM_ADDR_P1;
  constant REG_RAM_ADDR_LTE        : boolean := CFG_SEL(CFG_FAM).REG_RAM_ADDR_LTE;

  constant BYTE_LANES     : integer := VECTOR_LANES*4;
  constant RAM_DEPTH      : integer := (SCRATCHPAD_KB*1024)/BYTE_LANES;
  constant RAM_ADDR_WIDTH : integer := log2(RAM_DEPTH);
  constant BYTE_SEL_W     : integer := log2(BYTE_LANES);

  type scratchpad_control_in is record
    addr      : std_logic_vector(ADDR_WIDTH-1 downto 0);
    byteena   : std_logic_vector(BYTE_LANES-1 downto 0);
    writedata : scratchpad_data(BYTE_LANES-1 downto 0);
    we        : std_logic;
  end record;

  signal scratch_port_a_record : scratchpad_control_in;
  signal scratch_port_b_record : scratchpad_control_in;
  signal scratch_port_c_record : scratchpad_control_in;
  signal scratch_port_d_record : scratchpad_control_in;

  signal addr_a_ce, addr_b_ce, addr_c_ce, addr_d_ce : std_logic;
  signal addr_a, addr_b, addr_c, addr_d             : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal addr_a_p1, addr_b_p1, addr_c_p1, addr_d_p1 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal lte_a, lte_b, lte_c, lte_d                 : std_logic_vector(BYTE_LANES-1 downto 0);

  type   ram_addr is array (BYTE_LANES-1 downto 0) of std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  type   ram_addr_shifter is array (EXTRA_SCRATCH_DRIVE_STAGE*2 downto 0) of ram_addr;
  signal ram_addr_a         : ram_addr_shifter;
  signal ram_addr_b         : ram_addr_shifter;
  type   ram_enable_shifter is array (EXTRA_SCRATCH_DRIVE_STAGE*2 downto 0) of std_logic_vector(BYTE_LANES-1 downto 0);
  signal ram_byteena_a      : ram_enable_shifter;
  signal ram_byteena_b      : ram_enable_shifter;
  type   ram_data_shifter is array (EXTRA_SCRATCH_DRIVE_STAGE*2 downto 0) of std_logic_vector((BYTE_LANES*9)-1 downto 0);
  signal ram_data_a         : ram_data_shifter;
  signal ram_data_b         : ram_data_shifter;
  signal ram_we_a           : ram_enable_shifter;
  signal ram_we_b           : ram_enable_shifter;
  signal ram_readdata_a     : std_logic_vector((BYTE_LANES*9)-1 downto 0);
  signal ram_readdata_b     : std_logic_vector((BYTE_LANES*9)-1 downto 0);
  signal ram_readdata_a_d2x : std_logic_vector((BYTE_LANES*9)-1 downto 0);
  signal ram_readdata_b_d2x : std_logic_vector((BYTE_LANES*9)-1 downto 0);

  signal next_ram_addr_a    : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal next_ram_addr_b    : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal next_ram_addr_a_p1 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal next_ram_addr_b_p1 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);

  signal ram_addr_a_p0 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal ram_addr_b_p0 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal ram_addr_a_p1 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
  signal ram_addr_b_p1 : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);

  signal ram_addr_a_lte : std_logic_vector(BYTE_LANES-1 downto 0);
  signal ram_addr_b_lte : std_logic_vector(BYTE_LANES-1 downto 0);

  signal toggler     : std_logic;
  signal toggler_d2x : std_logic;
  signal firstcycle  : std_logic_vector(4+VECTOR_LANES-1 downto 0);
  signal secondcycle : std_logic;
begin
  scratch_port_a_record.addr      <= scratchpad_control_in_get(scratch_port_a, CONTROL_IN_ADDR, VECTOR_LANES, ADDR_WIDTH);
  scratch_port_a_record.byteena   <= scratchpad_control_in_get(scratch_port_a, CONTROL_IN_BYTEENA, VECTOR_LANES, ADDR_WIDTH);
  scratch_port_a_record.writedata <=
    byte9_to_scratchpad_data(scratchpad_control_in_get(scratch_port_a, CONTROL_IN_WRITEDATA, VECTOR_LANES, ADDR_WIDTH));
  scratch_port_a_record.we        <= scratchpad_control_in_get(scratch_port_a, CONTROL_IN_WE, VECTOR_LANES, ADDR_WIDTH)(0);
  scratch_port_b_record.addr      <= scratchpad_control_in_get(scratch_port_b, CONTROL_IN_ADDR, VECTOR_LANES, ADDR_WIDTH);
  scratch_port_b_record.byteena   <= scratchpad_control_in_get(scratch_port_b, CONTROL_IN_BYTEENA, VECTOR_LANES, ADDR_WIDTH);
  scratch_port_b_record.writedata <=
    byte9_to_scratchpad_data(scratchpad_control_in_get(scratch_port_b, CONTROL_IN_WRITEDATA, VECTOR_LANES, ADDR_WIDTH));
  scratch_port_b_record.we        <= scratchpad_control_in_get(scratch_port_b, CONTROL_IN_WE, VECTOR_LANES, ADDR_WIDTH)(0);
  scratch_port_c_record.addr      <= scratchpad_control_in_get(scratch_port_c, CONTROL_IN_ADDR, VECTOR_LANES, ADDR_WIDTH);
  scratch_port_c_record.byteena   <= scratchpad_control_in_get(scratch_port_c, CONTROL_IN_BYTEENA, VECTOR_LANES, ADDR_WIDTH);
  scratch_port_c_record.writedata <=
    byte9_to_scratchpad_data(scratchpad_control_in_get(scratch_port_c, CONTROL_IN_WRITEDATA, VECTOR_LANES, ADDR_WIDTH));
  scratch_port_c_record.we        <= scratchpad_control_in_get(scratch_port_c, CONTROL_IN_WE, VECTOR_LANES, ADDR_WIDTH)(0);
  scratch_port_d_record.addr      <= scratchpad_control_in_get(scratch_port_d, CONTROL_IN_ADDR, VECTOR_LANES, ADDR_WIDTH);
  scratch_port_d_record.byteena   <= scratchpad_control_in_get(scratch_port_d, CONTROL_IN_BYTEENA, VECTOR_LANES, ADDR_WIDTH);
  scratch_port_d_record.writedata <=
    byte9_to_scratchpad_data(scratchpad_control_in_get(scratch_port_d, CONTROL_IN_WRITEDATA, VECTOR_LANES, ADDR_WIDTH));
  scratch_port_d_record.we <= scratchpad_control_in_get(scratch_port_d, CONTROL_IN_WE, VECTOR_LANES, ADDR_WIDTH)(0);

  addr_a_ce <= scratchpad_control_in_get(scratch_port_a, CONTROL_IN_ADDR_CE, VECTOR_LANES, ADDR_WIDTH)(0);
  addr_b_ce <= scratchpad_control_in_get(scratch_port_b, CONTROL_IN_ADDR_CE, VECTOR_LANES, ADDR_WIDTH)(0);
  addr_c_ce <= scratchpad_control_in_get(scratch_port_c, CONTROL_IN_ADDR_CE, VECTOR_LANES, ADDR_WIDTH)(0);
  addr_d_ce <= scratchpad_control_in_get(scratch_port_d, CONTROL_IN_ADDR_CE, VECTOR_LANES, ADDR_WIDTH)(0);

  -- purpose: toggler for use in finding firstcycle
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if reset = '1' then               -- synchronous reset (active high)
        toggler <= '0';
      else
        toggler <= not toggler;
      end if;
    end if;
  end process;

  -- purpose: toggler_d2x for use in finding firstcycle
  process (clk_2x)
  begin  -- process
    if clk_2x'event and clk_2x = '1' then  -- rising clock edge
      toggler_d2x <= toggler;
      secondcycle <= toggler_d2x xor toggler;
      firstcycle  <= (others => secondcycle);
      if reset = '1' then
        secondcycle <= '0';

        --Shift register here just to ensure that logic doesn't get optimized away
        firstcycle(0)                        <= secondcycle;
        firstcycle(firstcycle'left downto 1) <= firstcycle(firstcycle'left-1 downto 0);
      end if;
    end if;
  end process;

  -- purpose: register 2x data for capture on 1x clk
  process (clk_2x)
  begin  -- process
    if clk_2x'event and clk_2x = '1' then  -- rising clock edge
      ram_readdata_a_d2x <= ram_readdata_a;
      ram_readdata_b_d2x <= ram_readdata_b;
    end if;
  end process;

  -- purpose: register data on 1x clock for timing
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      readdata_a <= byte9_to_scratchpad_data(ram_readdata_a);
      readdata_b <= byte9_to_scratchpad_data(ram_readdata_b);
      readdata_c <= byte9_to_scratchpad_data(ram_readdata_a_d2x);
      readdata_d <= byte9_to_scratchpad_data(ram_readdata_b_d2x);
    end if;
  end process;

  addr_reg_gen : if COMBI_SCRATCH_PORT_ADDR = true generate
    process (clk)
    begin
      if clk'event and clk = '1' then
        if reset = '1' then
          addr_a <= (others => '0');
          addr_b <= (others => '0');
          addr_c <= (others => '0');
          addr_d <= (others => '0');
        else
          if addr_a_ce = '1' then
            addr_a <= scratch_port_a_record.addr;
          end if;
          if addr_b_ce = '1' then
            addr_b <= scratch_port_b_record.addr;
          end if;
          if addr_c_ce = '1' then
            addr_c <= scratch_port_c_record.addr;
          end if;
          if addr_d_ce = '1' then
            addr_d <= scratch_port_d_record.addr;
          end if;
        end if;
      end if;
    end process;
  end generate addr_reg_gen;

  no_addr_reg_gen : if COMBI_SCRATCH_PORT_ADDR = false generate
    addr_a <= scratch_port_a_record.addr;
    addr_b <= scratch_port_b_record.addr;
    addr_c <= scratch_port_c_record.addr;
    addr_d <= scratch_port_d_record.addr;
  end generate no_addr_reg_gen;

  addr_p1_reg_gen : if (COMBI_SCRATCH_PORT_ADDR = true) and (REG_RAM_ADDR_P1 = true) generate
    process (clk)
    begin
      if clk'event and clk = '1' then
        if reset = '1' then
          addr_a_p1 <= (others => '0');
          addr_b_p1 <= (others => '0');
          addr_c_p1 <= (others => '0');
          addr_d_p1 <= (others => '0');
        else
          if addr_a_ce = '1' then
            addr_a_p1 <= std_logic_vector(unsigned(scratch_port_a_record.addr(ADDR_WIDTH-1 downto BYTE_SEL_W)) +
                                          to_unsigned(1, RAM_ADDR_WIDTH));
          end if;
          if addr_b_ce = '1' then
            addr_b_p1 <= std_logic_vector(unsigned(scratch_port_b_record.addr(ADDR_WIDTH-1 downto BYTE_SEL_W)) +
                                          to_unsigned(1, RAM_ADDR_WIDTH));
          end if;
          if addr_c_ce = '1' then
            addr_c_p1 <= std_logic_vector(unsigned(scratch_port_c_record.addr(ADDR_WIDTH-1 downto BYTE_SEL_W)) +
                                          to_unsigned(1, RAM_ADDR_WIDTH));
          end if;
          if addr_d_ce = '1' then
            addr_d_p1 <= std_logic_vector(unsigned(scratch_port_d_record.addr(ADDR_WIDTH-1 downto BYTE_SEL_W)) +
                                          to_unsigned(1, RAM_ADDR_WIDTH));
          end if;
        end if;
      end if;
    end process;
  end generate addr_p1_reg_gen;

  -- purpose: register next_ram_addr signals for timing
  next_ram_addr_a <= addr_a when firstcycle(VECTOR_LANES) = '1'   else addr_c;
  next_ram_addr_b <= addr_b when firstcycle(VECTOR_LANES+1) = '1' else addr_d;

  addr_p1_from_reg_gen : if (COMBI_SCRATCH_PORT_ADDR = true) and (REG_RAM_ADDR_P1 = true) generate
    next_ram_addr_a_p1 <= addr_a_p1 when firstcycle(VECTOR_LANES+2) = '1' else addr_c_p1;
    next_ram_addr_b_p1 <= addr_b_p1 when firstcycle(VECTOR_LANES+3) = '1' else addr_d_p1;
  end generate addr_p1_from_reg_gen;

  addr_p1_combi_gen : if (COMBI_SCRATCH_PORT_ADDR = false) or (REG_RAM_ADDR_P1 = false) generate
    next_ram_addr_a_p1 <= std_logic_vector(unsigned(addr_a(ADDR_WIDTH-1 downto BYTE_SEL_W)) +
                                           to_unsigned(1, RAM_ADDR_WIDTH))
                          when firstcycle(VECTOR_LANES+2) = '1' else
                          std_logic_vector(unsigned(addr_c(ADDR_WIDTH-1 downto BYTE_SEL_W)) +
                                           to_unsigned(1, RAM_ADDR_WIDTH));
    next_ram_addr_b_p1 <= std_logic_vector(unsigned(addr_b(ADDR_WIDTH-1 downto BYTE_SEL_W)) +
                                           to_unsigned(1, RAM_ADDR_WIDTH))
                          when firstcycle(VECTOR_LANES+3) = '1' else
                          std_logic_vector(unsigned(addr_d(ADDR_WIDTH-1 downto BYTE_SEL_W)) +
                                           to_unsigned(1, RAM_ADDR_WIDTH));
  end generate addr_p1_combi_gen;

  lte_reg_gen : if (COMBI_SCRATCH_PORT_ADDR = true) and (REG_RAM_ADDR_LTE = true) generate
    process (clk)
    begin
      if clk'event and clk = '1' then
        if reset = '1' then
          lte_a <= (others => '0');
          lte_b <= (others => '0');
          lte_c <= (others => '0');
          lte_d <= (others => '0');
        else
          for i in BYTE_LANES-1 downto 0 loop
            if addr_a_ce = '1' then
              if unsigned(scratch_port_a_record.addr(BYTE_SEL_W-1 downto 0)) <= to_unsigned(i, BYTE_SEL_W) then
                lte_a(i) <= '1';
              else
                lte_a(i) <= '0';
              end if;
            end if;  -- ce
            if addr_b_ce = '1' then
              if unsigned(scratch_port_b_record.addr(BYTE_SEL_W-1 downto 0)) <= to_unsigned(i, BYTE_SEL_W) then
                lte_b(i) <= '1';
              else
                lte_b(i) <= '0';
              end if;
            end if;  -- ce
            if addr_c_ce = '1' then
              if unsigned(scratch_port_c_record.addr(BYTE_SEL_W-1 downto 0)) <= to_unsigned(i, BYTE_SEL_W) then
                lte_c(i) <= '1';
              else
                lte_c(i) <= '0';
              end if;
            end if;  -- ce
            if addr_d_ce = '1' then
              if unsigned(scratch_port_d_record.addr(BYTE_SEL_W-1 downto 0)) <= to_unsigned(i, BYTE_SEL_W) then
                lte_d(i) <= '1';
              else
                lte_d(i) <= '0';
              end if;
            end if;  -- ce
          end loop;  -- i
        end if;
      end if;
    end process;

    lte_2x_gen : for gbyte in BYTE_LANES-1 downto 0 generate
      ram_addr_a_lte(gbyte) <= lte_a(gbyte) when firstcycle(gbyte/4) = '1' else lte_c(gbyte);
      ram_addr_b_lte(gbyte) <= lte_b(gbyte) when firstcycle(gbyte/4) = '1' else lte_d(gbyte);
    end generate lte_2x_gen;

  end generate lte_reg_gen;

  ram_addr_lte_before_gen : if (REG_BEFORE_RAM_ADDR_SEL = true) and (REG_RAM_ADDR_LTE = false) generate
    process (clk_2x)
    begin  -- process
      if clk_2x'event and clk_2x = '1' then  -- rising clock edge
        for ibyte in BYTE_LANES-1 downto 0 loop
          if unsigned(next_ram_addr_a(BYTE_SEL_W-1 downto 0)) <= to_unsigned(ibyte, BYTE_SEL_W) then
            ram_addr_a_lte(ibyte) <= '1';
          else
            ram_addr_a_lte(ibyte) <= '0';
          end if;
          if unsigned(next_ram_addr_b(BYTE_SEL_W-1 downto 0)) <= to_unsigned(ibyte, BYTE_SEL_W) then
            ram_addr_b_lte(ibyte) <= '1';
          else
            ram_addr_b_lte(ibyte) <= '0';
          end if;
        end loop;  -- i
      end if;
    end process;
  end generate ram_addr_lte_before_gen;

  ram_addr_lte_after_gen : if (REG_BEFORE_RAM_ADDR_SEL = false) and (REG_RAM_ADDR_LTE = false) generate
    lte_after_byte_gen : for gbyte in BYTE_LANES-1 downto 0 generate
      ram_addr_a_lte(gbyte) <= '1' when (unsigned(next_ram_addr_a(BYTE_SEL_W-1 downto 0)) <=
                                         to_unsigned(gbyte, BYTE_SEL_W)) else
                               '0';
      ram_addr_b_lte(gbyte) <= '1' when (unsigned(next_ram_addr_b(BYTE_SEL_W-1 downto 0)) <=
                                         to_unsigned(gbyte, BYTE_SEL_W)) else
                               '0';
    end generate lte_after_byte_gen;
  end generate ram_addr_lte_after_gen;

  ram_reg_before_gen : if REG_BEFORE_RAM_ADDR_SEL = true generate
    ram_addr_reg : process (clk_2x)
    begin  -- process ram_addr_reg
      if clk_2x'event and clk_2x = '1' then  -- rising clock edge
        ram_addr_a_p0 <= next_ram_addr_a(ADDR_WIDTH-1 downto BYTE_SEL_W);
        ram_addr_b_p0 <= next_ram_addr_b(ADDR_WIDTH-1 downto BYTE_SEL_W);
        ram_addr_a_p1 <= next_ram_addr_a_p1;
        ram_addr_b_p1 <= next_ram_addr_b_p1;
      end if;
    end process ram_addr_reg;
  end generate ram_reg_before_gen;

  ram_reg_after_gen : if REG_BEFORE_RAM_ADDR_SEL = false generate
    ram_addr_a_p0 <= next_ram_addr_a(ADDR_WIDTH-1 downto BYTE_SEL_W);
    ram_addr_b_p0 <= next_ram_addr_b(ADDR_WIDTH-1 downto BYTE_SEL_W);
    ram_addr_a_p1 <= next_ram_addr_a_p1;
    ram_addr_b_p1 <= next_ram_addr_b_p1;
  end generate ram_reg_after_gen;

  -- Generate an individually addressable scratchpad RAM for each byte
  scratchpad_gen : for gbyte in BYTE_LANES-1 downto 0 generate
    signal we_a, we_b, we_c, we_d : std_logic;
  begin

    xil_we_gen : if CFG_FAM /= CFG_FAM_ALTERA generate
      -- Xilinx BRAMs don't have separate write enable and byte enable ports,
      -- so combine the two signals together.
      we_a <= scratch_port_a_record.we and scratch_port_a_record.byteena(gbyte);
      we_b <= scratch_port_b_record.we and scratch_port_b_record.byteena(gbyte);
      we_c <= scratch_port_c_record.we and scratch_port_c_record.byteena(gbyte);
      we_d <= scratch_port_d_record.we and scratch_port_d_record.byteena(gbyte);
    end generate xil_we_gen;

    alt_we_gen : if CFG_FAM = CFG_FAM_ALTERA generate
      we_a <= scratch_port_a_record.we;
      we_b <= scratch_port_b_record.we;
      we_c <= scratch_port_c_record.we;
      we_d <= scratch_port_d_record.we;
    end generate alt_we_gen;

    -- purpose: Register RAM address and data
    ram_reg_proc : process (clk_2x)
    begin  -- process
      if clk_2x'event and clk_2x = '1' then  -- rising clock edge
        if firstcycle(gbyte/4) = '1' then
          ram_byteena_a(0)(gbyte)                     <= scratch_port_a_record.byteena(gbyte);
          ram_data_a(0)((gbyte+1)*9-1 downto gbyte*9) <= scratchpad_data_to_byte9(scratch_port_a_record.writedata)((gbyte+1)*9-1 downto gbyte*9);
          ram_we_a(0)(gbyte)                          <= we_a;
        else
          ram_byteena_a(0)(gbyte)                     <= scratch_port_c_record.byteena(gbyte);
          ram_data_a(0)((gbyte+1)*9-1 downto gbyte*9) <= scratchpad_data_to_byte9(scratch_port_c_record.writedata)((gbyte+1)*9-1 downto gbyte*9);
          ram_we_a(0)(gbyte)                          <= we_c;
        end if;
        if firstcycle(gbyte/4) = '1' then
          ram_byteena_b(0)(gbyte)                     <= scratch_port_b_record.byteena(gbyte);
          ram_data_b(0)((gbyte+1)*9-1 downto gbyte*9) <= scratchpad_data_to_byte9(scratch_port_b_record.writedata)((gbyte+1)*9-1 downto gbyte*9);
          ram_we_b(0)(gbyte)                          <= we_b;
        else
          ram_byteena_b(0)(gbyte)                     <= scratch_port_d_record.byteena(gbyte);
          ram_data_b(0)((gbyte+1)*9-1 downto gbyte*9) <= scratchpad_data_to_byte9(scratch_port_d_record.writedata)((gbyte+1)*9-1 downto gbyte*9);
          ram_we_b(0)(gbyte)                          <= we_d;
        end if;
      end if;
    end process ram_reg_proc;

    no_reg_before_ram_addr_gen : if REG_BEFORE_RAM_ADDR_SEL = false generate
      ram_addr_reg_proc : process (clk_2x)
      begin  -- process ram_addr_reg_proc
        if clk_2x'event and clk_2x = '1' then  -- rising clock edge
          if ram_addr_a_lte(gbyte) = '1' then
            ram_addr_a(0)(gbyte) <= ram_addr_a_p0;
          else
            ram_addr_a(0)(gbyte) <= ram_addr_a_p1;
          end if;
          if ram_addr_b_lte(gbyte) = '1' then
            ram_addr_b(0)(gbyte) <= ram_addr_b_p0;
          else
            ram_addr_b(0)(gbyte) <= ram_addr_b_p1;
          end if;
        end if;
      end process ram_addr_reg_proc;
    end generate no_reg_before_ram_addr_gen;

    reg_before_ram_addr_gen : if REG_BEFORE_RAM_ADDR_SEL = true generate
      ram_addr_a(0)(gbyte) <= ram_addr_a_p0 when ram_addr_a_lte(gbyte) = '1' else
                              ram_addr_a_p1;
      ram_addr_b(0)(gbyte) <= ram_addr_b_p0 when ram_addr_b_lte(gbyte) = '1' else
                              ram_addr_b_p1;
    end generate reg_before_ram_addr_gen;


    xil_ram_gen : if CFG_FAM /= CFG_FAM_ALTERA generate

      scratchpad_memory : scratchpad_ram_xil
        generic map (
          RAM_DEPTH => RAM_DEPTH
          )
        port map (
          address_a  => ram_addr_a(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte),
          address_b  => ram_addr_b(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte),
          clock      => clk_2x,
          data_a     => ram_data_a(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte*9+8 downto gbyte*9),
          data_b     => ram_data_b(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte*9+8 downto gbyte*9),
          wren_a     => ram_we_a(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte),
          wren_b     => ram_we_b(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte),
          readdata_a => ram_readdata_a(gbyte*9+8 downto gbyte*9),
          readdata_b => ram_readdata_b(gbyte*9+8 downto gbyte*9)
          );
    end generate xil_ram_gen;

--    alt_ram_gen : if CFG_FAM = CFG_FAM_ALTERA generate
--      scratchpad_memory : scratchpad_ram
--        generic map (
--          RAM_DEPTH => RAM_DEPTH
--          )
--        port map (
--          address_a  => ram_addr_a(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte),
--          address_b  => ram_addr_b(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte),
--          byteena_a  => ram_byteena_a(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte downto gbyte),
--          byteena_b  => ram_byteena_b(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte downto gbyte),
--          clock      => clk_2x,
--          data_a     => ram_data_a(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte*9+8 downto gbyte*9),
--          data_b     => ram_data_b(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte*9+8 downto gbyte*9),
--          wren_a     => ram_we_a(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte),
--          wren_b     => ram_we_b(EXTRA_SCRATCH_DRIVE_STAGE*2)(gbyte),
--          readdata_a => ram_readdata_a(gbyte*9+8 downto gbyte*9),
--          readdata_b => ram_readdata_b(gbyte*9+8 downto gbyte*9)
--          );
--    end generate alt_ram_gen;
  end generate scratchpad_gen;

  scratchpad_drive_delay : if EXTRA_SCRATCH_DRIVE_STAGE /= 0 generate
    delay_proc : process (clk_2x)
    begin  -- process delay_proc
      if clk_2x'event and clk_2x = '1' then  -- rising clock edge
        ram_addr_a(ram_addr_a'left downto 1)       <= ram_addr_a(ram_addr_a'left-1 downto 0);
        ram_addr_b(ram_addr_b'left downto 1)       <= ram_addr_b(ram_addr_b'left-1 downto 0);
        ram_data_a(ram_data_a'left downto 1)       <= ram_data_a(ram_data_a'left-1 downto 0);
        ram_data_b(ram_data_b'left downto 1)       <= ram_data_b(ram_data_b'left-1 downto 0);
        ram_we_a(ram_we_a'left downto 1)           <= ram_we_a(ram_we_a'left-1 downto 0);
        ram_we_b(ram_we_b'left downto 1)           <= ram_we_b(ram_we_b'left-1 downto 0);
        ram_byteena_a(ram_byteena_a'left downto 1) <= ram_byteena_a(ram_byteena_a'left-1 downto 0);
        ram_byteena_b(ram_byteena_b'left downto 1) <= ram_byteena_b(ram_byteena_b'left-1 downto 0);
        if reset = '1' then
          ram_addr_a(ram_addr_a'left downto 1)       <= (others => (others => (others => '0')));
          ram_addr_b(ram_addr_b'left downto 1)       <= (others => (others => (others => '0')));
          ram_data_a(ram_data_a'left downto 1)       <= (others => (others => '0'));
          ram_data_b(ram_data_b'left downto 1)       <= (others => (others => '0'));
          ram_we_a(ram_we_a'left downto 1)           <= (others => (others => '0'));
          ram_we_b(ram_we_b'left downto 1)           <= (others => (others => '0'));
          ram_byteena_a(ram_byteena_a'left downto 1) <= (others => (others => '0'));
          ram_byteena_b(ram_byteena_b'left downto 1) <= (others => (others => '0'));
        end if;
      end if;
    end process delay_proc;
  end generate scratchpad_drive_delay;

end rtl;
