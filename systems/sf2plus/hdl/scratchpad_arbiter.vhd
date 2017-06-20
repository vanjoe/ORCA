-- scratchpad_arbiter.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;
use work.isa_pkg.all;
use work.architecture_pkg.all;
use work.component_pkg.all;

entity scratchpad_arbiter is
  generic (
    VECTOR_LANES : integer := 1;

    CFG_FAM : config_family_type;

    ADDR_WIDTH : integer := 1
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    request_in  : in  std_logic_vector(scratchpad_requests_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    request_out : out std_logic_vector(scratchpad_requests_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

    scratch_port_d : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    readdata_d     : in  scratchpad_data((VECTOR_LANES*4)-1 downto 0)
    );

  -- attribute secure_netlist     : string;  -- OFF, ENCRYPT, (PROHIBIT not allowed in Vivado)
  -- attribute secure_config      : string;  -- OFF, PROTECT
  -- attribute secure_net_editing : string;  -- OFF, PROHIBIT
  -- attribute secure_bitstream   : string;  -- OFF, PROHIBIT
  -- attribute secure_net_probing : string;  -- OFF, PROHIBIT
  -- attribute check_license      : string;

  -- attribute secure_netlist of scratchpad_arbiter : entity is "OFF";
  -- attribute secure_config  of scratchpad_arbiter : entity is "OFF";
  -- attribute check_license  of scratchpad_arbiter : entity is "ipvblox_mxp";

end entity scratchpad_arbiter;

architecture rtl of scratchpad_arbiter is
  constant COMBI_SCRATCH_PORT_ADDR : boolean := CFG_SEL(CFG_FAM).COMBI_SCRATCH_PORT_ADDR;

  --FIXME: Tune extra align stages for needed
  constant EXTRA_ALIGN_STAGES : natural := arbiter_extra_align_stages(VECTOR_LANES);

  type scratchpad_request_in is record
    rd        : std_logic;
    wr        : std_logic;
    addr      : std_logic_vector(ADDR_WIDTH-1 downto 0);
    writedata : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    byteena   : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  end record;
  type scratchpad_requests_in is array (SCRATCHPAD_REQUESTORS-1 downto 0) of scratchpad_request_in;

  type scratchpad_request_out is record
    waitrequest   : std_logic;
    readdatavalid : std_logic;
    readdata      : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    readdata_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
  end record;
  type scratchpad_requests_out is array (SCRATCHPAD_REQUESTORS-1 downto 0) of scratchpad_request_out;

  function scratchpad_request_in_to_record (
    flat_request : std_logic_vector)
    return scratchpad_request_in;
  function scratchpad_request_in_to_record (
    flat_request : std_logic_vector)
    return scratchpad_request_in is
    variable current_loc       : integer := 0;
    variable record_request    : scratchpad_request_in;
    variable flat_request_copy : std_logic_vector(flat_request'length-1 downto 0);
  begin
    --Quick way to normalize slice right to 0
    flat_request_copy := flat_request;

    current_loc              := 0;
    record_request.rd        := flat_request_copy(current_loc);
    current_loc              := current_loc + 1;
    record_request.wr        := flat_request_copy(current_loc);
    current_loc              := current_loc + 1;
    record_request.addr      := flat_request_copy(current_loc+record_request.addr'length-1 downto current_loc);
    current_loc              := current_loc + record_request.addr'length;
    record_request.writedata := byte9_to_scratchpad_data(flat_request_copy(current_loc+(record_request.writedata'length*9)-1 downto current_loc));
    current_loc              := current_loc + (record_request.writedata'length*9);
    record_request.byteena   := flat_request_copy(current_loc+record_request.byteena'length-1 downto current_loc);

    return record_request;
  end scratchpad_request_in_to_record;

  signal request_in_record  : scratchpad_requests_in;
  signal request_out_record : scratchpad_requests_out;

  type validshift_array is array (SCRATCHPAD_READ_DELAY+EXTRA_ALIGN_STAGES+1 downto 1) of std_logic_vector(SCRATCHPAD_REQUESTORS-1 downto 0);
  type addrshift_array is array (SCRATCHPAD_READ_DELAY+EXTRA_ALIGN_STAGES+1 downto 1) of std_logic_vector(ADDR_WIDTH-1 downto 0);

  signal read_valid         : std_logic_vector(SCRATCHPAD_REQUESTORS-1 downto 0);
  signal read_valid_d       : validshift_array;
  signal we                 : std_logic;
  signal we_d               : std_logic_vector(SCRATCHPAD_READ_DELAY+EXTRA_ALIGN_STAGES+1 downto 1);
  signal addr               : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal addr_d             : addrshift_array;
  signal request            : std_logic_vector(SCRATCHPAD_REQUESTORS-1 downto 0);
  signal read_request       : std_logic_vector(SCRATCHPAD_REQUESTORS-1 downto 0);
  signal selected_requestor : integer range 0 to SCRATCHPAD_REQUESTORS-1;
  signal selected_onehot    : std_logic_vector(SCRATCHPAD_REQUESTORS-1 downto 0);
  signal read_granted       : std_logic;

  type   align_2d_scratchpad is array (EXTRA_ALIGN_STAGES downto 0) of std_logic_vector(((VECTOR_LANES*4)*9)-1 downto 0);
  type   align_2d_byteena is array (EXTRA_ALIGN_STAGES downto 0) of std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal data_shifter_in     : align_2d_scratchpad;
  signal data_shifter_out    : align_2d_scratchpad;
  signal byteena_shifter_in  : align_2d_byteena;
  signal byteena_shifter_out : align_2d_byteena;

  type   align_2d_offset is array (EXTRA_ALIGN_STAGES downto 0) of std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);
  signal data_shift_amount        : align_2d_offset;
  signal data_shift_amount_masked : align_2d_offset;

  signal return_shift        : std_logic;
  signal return_shift_amount : std_logic_vector(log2(VECTOR_LANES*4)-1 downto 0);

  signal scratch_port_d_addr      : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal scratch_port_d_byteena   : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal scratch_port_d_writedata : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal scratch_port_d_we        : std_logic;

  signal scratch_port_d_addr_ce : std_logic;

  signal readdata_d_shifted : scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  signal selected_addr           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal selected_byteena        : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal selected_writedata_flat : std_logic_vector((VECTOR_LANES*4*9)-1 downto 0);
  signal shifted_byteena         : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal shifted_writedata       : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
begin
  scratch_port_d <= scratchpad_control_in_flatten(scratch_port_d_addr,
                                                  scratch_port_d_addr_ce,
                                                  scratch_port_d_byteena,
                                                  scratch_port_d_writedata,
                                                  scratch_port_d_we);

  -- Might be more efficient to code as a single mux by rearranging data,
  -- depending on how synthesis tools work.  But small enough I'm not going to
  -- worry about it for now.
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if read_granted = '1' then
        scratch_port_d_we <= '0';
      else
        scratch_port_d_we <= we_d(EXTRA_ALIGN_STAGES);
      end if;
      scratch_port_d_byteena   <= shifted_byteena;
      scratch_port_d_writedata <= shifted_writedata;
    end if;
  end process;

  addr_combi_gen : if COMBI_SCRATCH_PORT_ADDR = true generate
    -- combinational output
    scratch_port_d_addr <= addr when read_granted = '1' else
                              addr_d(EXTRA_ALIGN_STAGES);
    scratch_port_d_addr_ce <= '1';
  end generate addr_combi_gen;

  addr_reg_gen : if COMBI_SCRATCH_PORT_ADDR = false generate
    process (clk)
    begin
      if clk'event and clk = '1' then
        if read_granted = '1' then
          scratch_port_d_addr <= addr;
        else
          scratch_port_d_addr <= addr_d(EXTRA_ALIGN_STAGES);
        end if;
      end if;
    end process;

    scratch_port_d_addr_ce <= '0';
  end generate addr_reg_gen;

  requestors_gen : for greq in SCRATCHPAD_REQUESTORS-1 downto 0 generate
    request_in_record(greq) <=
      scratchpad_request_in_to_record(request_in(((greq+1)*scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH))-1 downto
                                                 (greq*scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH))));
    request_out(((greq+1)*scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH))-1 downto
                (greq*scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH))) <=
      scratchpad_request_out_flatten(request_out_record(greq).waitrequest,
                                     request_out_record(greq).readdatavalid,
                                     request_out_record(greq).readdata,
                                     request_out_record(greq).readdata_addr);


    request(greq)      <= request_in_record(greq).rd or request_in_record(greq).wr;
    read_request(greq) <= request_in_record(greq).rd;

    request_out_record(greq).waitrequest   <= not selected_onehot(greq);
    request_out_record(greq).readdata      <= readdata_d_shifted;
    request_out_record(greq).readdatavalid <= read_valid_d(read_valid_d'left)(greq);
    request_out_record(greq).readdata_addr <= addr_d(addr_d'left);
  end generate requestors_gen;

  -- purpose: priority select requestor
  process (request, return_shift, request_in_record)
  begin  -- process
    selected_requestor <= 0;
    selected_onehot    <= (others => '0');
    we                 <= '0';
    read_granted       <= '0';
    addr               <= request_in_record(0).addr;
    for ireq in SCRATCHPAD_REQUESTORS-1 downto 0 loop
      if request(ireq) = '1' then
        selected_requestor    <= ireq;
        selected_onehot       <= (others => '0');
        selected_onehot(ireq) <= (not return_shift) or request_in_record(ireq).rd;
        we                    <= (not return_shift) and request_in_record(ireq).wr;
        read_granted          <= request_in_record(ireq).rd;
        addr                  <= request_in_record(ireq).addr;
      end if;
    end loop;  -- ireq
  end process;

  read_valid <= selected_onehot and read_request;

  -- purpose: shift readdatavalid and address signal to align with readdata
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      read_valid_d(1) <= read_valid;
      addr_d(1)       <= addr;
      we_d(1)         <= we;

      read_valid_d(read_valid_d'left downto read_valid_d'right+1) <=
        read_valid_d(read_valid_d'left-1 downto read_valid_d'right);
      addr_d(addr_d'left downto addr_d'right+1) <=
        addr_d(addr_d'left-1 downto addr_d'right);
      we_d(we_d'left downto we_d'right+1) <=
        we_d(we_d'left-1 downto we_d'right);

      return_shift <= or_slv(read_valid_d(SCRATCHPAD_READ_DELAY));

      --Right shift; use 0-left shift amount
      return_shift_amount <=
        std_logic_vector(to_unsigned(0, return_shift_amount'length) -
                         unsigned(addr_d(SCRATCHPAD_READ_DELAY)(log2(VECTOR_LANES*4)-1 downto 0)));
      if reset = '1' then
        return_shift <= '0';
      end if;
    end if;
  end process;

  --Mux between shifters; stall write if return will be busy
  data_shifter_in(0) <= scratchpad_data_to_byte9(readdata_d) when return_shift = '1' else
                        selected_writedata_flat;
  data_shift_amount(0) <=
    return_shift_amount when return_shift = '1' else
    selected_addr(log2(VECTOR_LANES*4)-1 downto 0);
  --Byteenables ignored on reads; always use write byteenables
  byteena_shifter_in(0) <= selected_byteena;

  barrel_shifters_gen : for gstage in EXTRA_ALIGN_STAGES downto 0 generate
                                        -- purpose: Mask offsets for each stage so final shift amount is correct
    offset_mask_proc : process (data_shift_amount(gstage))
    begin  -- process offset_mask_proc
      data_shift_amount_masked(gstage) <= (others => '0');

      data_shift_amount_masked(gstage)(
        ((((EXTRA_ALIGN_STAGES-gstage)+1)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES))-1 downto
        ((((EXTRA_ALIGN_STAGES-gstage)+0)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES))) <=
        data_shift_amount(gstage)(
          ((((EXTRA_ALIGN_STAGES-gstage)+1)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES))-1 downto
          ((((EXTRA_ALIGN_STAGES-gstage)+0)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES)));
    end process offset_mask_proc;

    data_shifter : component barrel_shifter
      generic map (
        WORD_WIDTH => 9,
        WORDS      => (VECTOR_LANES*4),
        LEFT_SHIFT => true
        )
      port map (
        data_in      => data_shifter_in(gstage),
        shift_amount => data_shift_amount_masked(gstage),
        data_out     => data_shifter_out(gstage)
        );

    --Byteenables ignored on reads; always use write byteenables
    byteena_shifter : component barrel_shifter
      generic map (
        WORD_WIDTH => 1,
        WORDS      => (VECTOR_LANES*4),
        LEFT_SHIFT => true
        )
      port map (
        data_in      => byteena_shifter_in(gstage),
        shift_amount => data_shift_amount_masked(gstage),
        data_out     => byteena_shifter_out(gstage)
        );

    shifter_reg_gen : if gstage > 0 generate
      shifter_reg_proc : process (clk)
      begin  -- process shifter_reg
        if clk'event and clk = '1' then  -- rising clock edge
          data_shift_amount(gstage)  <= data_shift_amount(gstage-1);
          data_shifter_in(gstage)    <= data_shifter_out(gstage-1);
          byteena_shifter_in(gstage) <= byteena_shifter_out(gstage-1);

          if reset = '1' then  --Prevent shift register inference for timing
            data_shift_amount(gstage) <= (others => '0');
          end if;
        end if;
      end process shifter_reg_proc;
    end generate shifter_reg_gen;
  end generate barrel_shifters_gen;

  readdata_d_shifted <= byte9_to_scratchpad_data(data_shifter_out(EXTRA_ALIGN_STAGES));
  shifted_writedata  <= byte9_to_scratchpad_data(data_shifter_out(EXTRA_ALIGN_STAGES));
  shifted_byteena    <= byteena_shifter_out(EXTRA_ALIGN_STAGES);

  selected_writedata_flat <= scratchpad_data_to_byte9(request_in_record(selected_requestor).writedata);
  selected_byteena        <= request_in_record(selected_requestor).byteena;
  selected_addr           <= request_in_record(selected_requestor).addr;

end architecture rtl;
