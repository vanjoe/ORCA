-- Direct Fast Simplex Link interface to MicroBlaze CPU.
-- fsl_handler.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
library work;
use work.util_pkg.all;
use work.isa_pkg.all;
use work.architecture_pkg.all;
use work.component_pkg.all;

entity fsl_handler is
  generic (
    CFG_FAM           : config_family_type;
    MIN_MULTIPLIER_HW : min_size_type := BYTE;
    ADDR_WIDTH        : integer       := 1
    );
  port(
    FSL_Clk : in std_logic;

    FSL_S_Read   : in  std_logic;
    FSL_S_Data   : out std_logic_vector(0 to 31);
    FSL_S_Exists : out std_logic;

    FSL_M_Write : in  std_logic;
    FSL_M_Data  : in  std_logic_vector(0 to 31);
    FSL_M_Full  : out std_logic;

    core_pipeline_empty : in std_logic;
    dma_pipeline_empty  : in std_logic;

    instr_fifo_read     : in  std_logic;
    instr_fifo_readdata : out instruction_type;
    instr_fifo_empty    : out std_logic;

    mask_status_update  : in std_logic;
    mask_length_nonzero : in std_logic;

    clk   : in std_logic;
    reset : in std_logic
    );
end entity fsl_handler;

---------------------------------------------------------------------------
-- All vector instructions other than GET/SET_PARAM require 4 "put"
-- instructions. The first "put" provides the opcode and flags in the lower
-- 16 bits; the next three "put" instrs provide operands a, b, and dest.
-- e.g.
--   ; Assume rA, rB, rD contain operands a, b, dest
--   ori r1, r0, op_flags
--   ; note: 16-bit immediate is sign-extended to 32-bits, but we don't care
--   ; about the upper 16 bits.
--   put r1, FSL0
--   put rA, FSL0
--   put rB, FSL0
--   put rD, FSL0
--
-- The opcode and flags are encoded as:
--   16:11  three_d, two_d, acc, masked, sv, ve flags
--   10:9   in_size
--   8:7    out_size
--   6      signedness
--   5:0    opcode
--
-- To keep the state machine simple, SET_VL instructions also require 4 put
-- instructions even though the dest operand is never used.
--
-- To set the 1D vector length, use op_flags=SET_VL, and put the
-- vector length in operands a and b. The dest operand can contain any value.
--
-- To set the 2D instruction parameters, issue two vector instructions
-- (8 put instructions):
-- 1) op_flags=SET_VL | FLAG_2D, a=num_rows, b=id, dest=don't care;
-- 2) op_flags=SET_VL | FLAG_2D | FLAG_ACC, a=ia, b=ib, dest=don't care.
--
-- To set the 3D instruction parameters, issue another two vector instructions:
-- 1) op_flags=SET_VL | FLAG_2D | FLAG_3D,
--    a=num_matrices, b=id3d, dest=don't care;
-- 2) op_flags=SET_VL | FLAG_2D | FLAG_3D | FLAG_ACC,
--    a=ia3d, b=ib3d, dest=don't care.
--
-- NOTE: the core seems to require that both the two_d and three_d flags be
-- set for 3D operations.
--
-- op_test.c expects hardware to mask out the unused upper bits of id, ia, ib,
-- id3d, ia3d, ib3d (number of valid bits is the same as the number of
-- scratchpad address bits) and vl, num_rows, num_matrices (number of valid
-- bits is one more than the number of scratchpad address bits) when the
-- parameter RAM is updated.
--
-- The DMA_TO_HOST and DMA_TO_VECTOR instructions are encoded as regular
-- instructions with
--   a = external address
--   b = internal address
--   dest = length in bytes
--
-- The fsl_op_extension flag provides support for the GET_PARAM and SET_PARAM
-- instructions. A regular instruction has fsl_op_extension=0.  It is set when
-- all but the rightmost 2 bits of opcode are '0' and the acc flag is set.
--
-- A GET_PARAM instruction is encoded as fsl_op_extension=1, opcode[0]=0,
-- and the parameter address in bits 10:6 of the instruction word.
-- The "put" instruction that writes the GET_PARAM instruction to the FSL FIFO
-- must be followed by a "get" instruction that reads the parameter value.
-- e.g.
--   or r1, r<param_addr << 6>, 0x0020
--   put r1, FSL0
--   get r2, FSL0
--
-- A SET_PARAM instruction is encoded as fsl_op_extension=1, opcode[0]=1
-- and the parameter address in bits 10:6 of the instruction word. A second
-- "put" instruction provides the parameter value.
-- e.g.
--   or r1, r<param_addr << 6>, 0x0420
--   put r1, FSL0
--   put r<param_val>, FSL0
--
-- A SYNC operation is similar to a GET_PARAM instruction, but doesn't
-- respond with data until the instruction FIFO is empty and both
-- core_pipeline_empty and dma_pipeline_empty are asserted.
--
-- Note: the instruction FIFO is the full width of an instruction, but
-- the FSL interface writes at most 32 bits per cycle, so the
-- average throughput is still limited to 32 bits per cycle.
---------------------------------------------------------------------------

architecture rtl of fsl_handler is

  constant INSTR_FIFO_DEPTH : integer := 16;
  -- signdness + opcode + opsize*2 + 6 flags + a[31:0] + b[AW-1:0] + dest[AW:0]
  constant INSTR_FIFO_WIDTH : integer := 1+ opcode'length + 2*opsize'length + 6 +
                                         32 + ADDR_WIDTH + (ADDR_WIDTH+1);

  -- 32 words in parameter RAM.
  constant RAM_AW : integer := GET_BITS+1;
  constant RAM_DW : integer := 32;

  signal saved_param_addr     : std_logic_vector(RAM_AW-1 downto 0);
  signal nxt_saved_param_addr : std_logic_vector(RAM_AW-1 downto 0);

  signal param_addr : std_logic_vector(RAM_AW-1 downto 0);
  signal param_we   : std_logic;
  signal param_in   : std_logic_vector(RAM_DW-1 downto 0);
  signal param_out  : std_logic_vector(RAM_DW-1 downto 0);

  type state_type is (S_IDLE, S_GET_A, S_GET_B, S_GET_DEST,
                      S_READ_PARAM, S_READ_PARAM2, S_WRITE_PARAM,
                      S_SYNC, S_GET_MASK);
  signal state, nxt_state : state_type;

  signal instr, nxt_instr : instruction_type;

  constant FSL_OP_GET      : std_logic_vector(1 downto 0) := "00";
  constant FSL_OP_SET      : std_logic_vector(1 downto 0) := "01";
  constant FSL_OP_SYNC     : std_logic_vector(1 downto 0) := "10";
  constant FSL_OP_GET_MASK : std_logic_vector(1 downto 0) := "11";

  signal fifo_write, nxt_fifo_write : std_logic;
  signal fifo_read                  : std_logic;
  signal fifo_data_in               : std_logic_vector(INSTR_FIFO_WIDTH-1 downto 0);
  signal fifo_data_out              : std_logic_vector(INSTR_FIFO_WIDTH-1 downto 0);
  signal fifo_full                  : std_logic;
  signal fifo_empty                 : std_logic;

  signal all_done : std_logic;

  signal fsl_full : std_logic;

  constant TIME_LIMIT : boolean := false;
  -- eval_timeout
  signal   s_done     : std_logic;

  signal mask_status : std_logic_vector(31 downto 0);
  signal get_v       : std_logic;
  signal get_i       : std_logic;
begin

  ---------------------------------------------------------------------------
  process (FSL_Clk)
  begin
    if FSL_Clk'event and FSL_Clk = '1' then
      if reset = '1' then
        state            <= S_IDLE;
        instr            <= INSTRUCTION_NULL;
        saved_param_addr <= (others => '0');
        fifo_write       <= '0';
      else
        state            <= nxt_state;
        instr            <= nxt_instr;
        saved_param_addr <= nxt_saved_param_addr;
        fifo_write       <= nxt_fifo_write;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  process (state, FSL_M_Data, FSL_M_Write, FSL_S_Read, instr, fifo_full,
           saved_param_addr, all_done)
    variable data             : std_logic_vector(31 downto 0);
    variable instr_v          : instruction_type;
    variable fsl_op_extension : std_logic;
  begin
    -- re-index bits from 31 downto 0.
    data := FSL_M_Data(0 to 31);

    -- default variable assignments
    instr_v          := instr;
    fsl_op_extension := '0';

    nxt_state <= state;
    nxt_instr <= instr;

    nxt_saved_param_addr <= saved_param_addr;

    -- Note: if blocking put instruction is used, MicroBlaze will not assert
    -- FSL_M_Write if FSL_M_Full is asserted. As stated in DS449 fsl_v20 doc,
    -- "FSL_M_Write is not gated with FSL_M_Full. The state of the FIFO is
    -- undefined when writing to a full FIFO."
    fsl_full     <= fifo_full;
    FSL_S_Exists <= '0';

    param_addr <= saved_param_addr;
    param_we   <= '0';

    nxt_fifo_write <= '0';

    get_v <= '0';
    get_i <= '0';

    case state is
      when S_IDLE =>
        if FSL_M_Write = '1' then

          -- Decode fields from first instruction word.
          instr_v.three_d    := data(16);
          instr_v.two_d      := data(15);
          instr_v.acc        := data(14);
          instr_v.masked     := data(13);
          instr_v.sv         := data(12);
          instr_v.ve         := data(11);
          instr_v.in_size    := data(10 downto 9);
          instr_v.out_size   := data(8 downto 7);
          instr_v.signedness := data(6);
          instr_v.op         := data(5 downto 0);

          if instr_v.op(OPCODE_BITS-1 downto 2) = OP_SET_VL(OPCODE_BITS-1 downto 2) and instr_v.masked = '1' then
            fsl_op_extension   := '1';
          end if;

          if fsl_op_extension = '0' then
            -- regular instruction; get operand A next.
            nxt_state <= S_GET_A;
          else
            -- extended opcode.
            -- GET/SET/SYNC encoded in opcode bit 1:0.
            -- For GET/SET, bits 4:0 of the instruction word provide the
            -- parameter address.
            if instr_v.op(1 downto 0) = FSL_OP_GET then
              -- GET: read the requested param from param RAM then
              -- write the value into the outgoing FSL FIFO.
              nxt_state <= S_READ_PARAM;
            elsif instr_v.op(1 downto 0) = FSL_OP_SET then
              -- SET: fetch the next operand and write it into param RAM.
              nxt_state <= S_WRITE_PARAM;
            elsif instr_v.op(1 downto 0) = FSL_OP_SYNC then
              nxt_state <= S_SYNC;
            elsif instr_v.op(1 downto 0) = FSL_OP_GET_MASK then
              nxt_state <= S_GET_MASK;
            end if;
          end if;

          nxt_saved_param_addr <= data(RAM_AW+5 downto 6);
          nxt_instr            <= instr_v;

        end if;

      when S_GET_A =>
        if FSL_M_Write = '1' then
          -- operand A can contain an external DMA address, so need to
          -- preserve all 32 bits.
          nxt_instr.a <= data;
          nxt_state   <= S_GET_B;

          if instr.op = OP_SET_VL then
            -- Must update parameter RAM on SET_VL instructions.
            -- The two_d, three_d, and acc flags determine which parameter is
            -- being updated.
            param_we <= '1';
            if instr.three_d = '1' then
              if instr.acc = '0' then
                param_addr <= '0' & GET_VL3D;
                get_v      <= '1';
              else
                param_addr <= '0' & GET_IA3D;
                get_i      <= '1';
              end if;
            elsif instr.two_d = '1' then
              if instr.acc = '0' then
                param_addr <= '0' & GET_VL2D;
                get_v      <= '1';
              else
                param_addr <= '0' & GET_IA;
                get_i      <= '1';
              end if;
            else
              param_addr <= '0' & GET_VL;
              get_v      <= '1';
            end if;
          end if;
        end if;

      when S_GET_B =>
        if FSL_M_Write = '1' then
          -- operand B is always an internal scratchpad address or stride;
          -- only the lower ADDR_WIDTH bits are valid.
          nxt_instr.b                        <= (others => '0');
          nxt_instr.b(ADDR_WIDTH-1 downto 0) <= data(ADDR_WIDTH-1 downto 0);
          nxt_state                          <= S_GET_DEST;

          if instr.op = OP_SET_VL then
            if instr.three_d = '1' then
              param_we <= '1';
              if instr.acc = '0' then
                param_addr <= '0' & GET_ID3D;
                get_i      <= '1';
              else
                param_addr <= '0' & GET_IB3D;
                get_i      <= '1';
              end if;
            elsif instr.two_d = '1' then
              param_we <= '1';
              if instr.acc = '0' then
                param_addr <= '0' & GET_ID;
                get_i      <= '1';
              else
                param_addr <= '0' & GET_IB;
                get_i      <= '1';
              end if;
            else
              -- Note: do nothing for operand B of one-dimensional SET_VL;
              -- the vector length was already specified in operand A.
              param_we <= '0';
            end if;
          end if;
        end if;

      when S_GET_DEST =>
        if FSL_M_Write = '1' then
          -- dest operand can be a DMA length operand or a scratchpad address.
          -- A DMA operation can span the entire scratchpad, so ADDR_WIDTH
          -- bits are required to specify the length.
          nxt_instr.dest                      <= (others => '0');
          nxt_instr.dest(ADDR_WIDTH downto 0) <= data(ADDR_WIDTH downto 0);
          nxt_state                           <= S_IDLE;
          -- Write intruction to FIFO in next cycle.
          nxt_fifo_write                      <= '1';
        end if;

      when S_READ_PARAM =>
        -- Additional state for outputting read address. This removes the
        -- need for a combinational path from FSL_S_Data to the param RAM
        -- address pins (which would be necessary if the read were started in
        -- S_IDLE).
        param_addr <= saved_param_addr;
        -- prevent any new data from being written to DWFSL.
        fsl_full   <= '1';
        nxt_state  <= S_READ_PARAM2;

      when S_READ_PARAM2 =>
        -- Param value is on output of RAM, make it available to DRFSL.
        param_addr   <= saved_param_addr;
        fsl_full     <= '1';
        FSL_S_Exists <= '1';
        if FSL_S_Read = '1' then
          nxt_state <= S_IDLE;
        end if;

      when S_WRITE_PARAM =>
        -- Wait for value on FSL interface and write it to param RAM.
        param_addr <= saved_param_addr;
        if FSL_M_Write = '1' then
          param_we  <= '1';
          nxt_state <= S_IDLE;
        end if;

      when S_SYNC =>
        -- wait for core and dma pipelines to go empty before asserting
        -- FSL_S_Exists on DRFSL interface.
        fsl_full <= '1';
        if all_done = '1' then
          FSL_S_Exists <= '1';
          if FSL_S_Read = '1' then
            nxt_state <= S_IDLE;
          end if;
        end if;

      when S_GET_MASK =>
        fsl_full     <= '1';
        FSL_S_Exists <= '1';
        if FSL_S_Read = '1' then
          nxt_state <= S_IDLE;
        end if;

      when others => null;
    end case;
  end process;

  ---------------------------------------------------------------------------
  -- register this signal to prevent long combinational path through
  -- core_pipeline_empty and FSL_S_Exists.
  process (FSL_Clk)
  begin
    if FSL_Clk'event and FSL_Clk = '1' then
      if reset = '1' then
        all_done <= '0';
      else
        all_done <= core_pipeline_empty and dma_pipeline_empty and
                    fifo_empty;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Zero out the upper bits of the VL/ROWS/ID/IA/AB/MATS/ID3D/IA3D/IB3D
  -- parameters.
  --
  -- Note: there is a combinational path from FSL_M_Data to the
  -- param RAM input.
  process (FSL_M_Data, param_addr)
    variable data : std_logic_vector(31 downto 0);
  begin
    -- re-index bits from 31 downto 0.
    data     := FSL_M_Data;
    param_in <= data;
    if get_v = '1' then
      param_in(31 downto ADDR_WIDTH+1) <= (others => '0');
    end if;
    if get_i = '1' then
      param_in(31 downto ADDR_WIDTH) <= (others => '0');
    end if;
  end process;

  FSL_S_Data <= mask_status when state = S_GET_MASK else param_out;

  ---------------------------------------------------------------------------
  -- Parameter RAM
  -- This is logically a single-port 32x32 RAM, but XST maps the "natural"
  -- HDL description below to one of the read/write ports of a 512x32 true
  -- dual-port 18Kb RAMB16WER (in Spartan-6).
  --
  -- type ram_type is array (RAM_DEPTH-1 downto 0) of
  --   std_logic_vector(31 downto 0);
  --
  -- signal param_ram : ram_type;
  --
  -- process (clk)
  -- begin  -- process
  --   if clk'event and clk = '1' then
  --     if param_we = '1' then
  --       param_ram(conv_integer(param_addr)) <= param_in;
  --     end if;
  --     param_out <= param_ram(conv_integer(param_addr));
  --   end if;
  -- end process;

  -- The RAM can also fit into a smaller SIMPLE dual-port 256x32 9Kb RAMB8WER
  -- with separate read-only and write-only ports.
  -- Unfortunately XST (as of 14.3) won't infer a simple DP RAM from an HDL
  -- description of a RAM with separate read and write addresses if it
  -- realizes that the read and write address are the same. Instead it will
  -- map the read and write ports to the same read/write ports of a true
  -- dual-port RAM.
  --
  -- We can work around this by putting the RAM in a component with separate
  -- read and write ports.

  altera_gen : if CFG_FAM = CFG_FAM_ALTERA generate
    type   ram_type is array ((2**RAM_AW)-1 downto 0) of std_logic_vector(RAM_DW-1 downto 0);
    signal ram : ram_type;
  begin
    process (FSL_Clk)
    begin
      if FSL_Clk'event and FSL_Clk = '1' then
        if param_we = '1' then
          ram(conv_integer(param_addr)) <= param_in;
        end if;
        param_out <= ram(conv_integer(param_addr));
      end if;
    end process;
  end generate altera_gen;
  xilinx_gen : if CFG_FAM /= CFG_FAM_ALTERA generate
    param_ram_0 :  sdp_ram
      generic map (
        AW => RAM_AW,
        DW => RAM_DW
        )
      port map (
        clk   => FSL_Clk,
        we    => param_we,
        raddr => param_addr,
        waddr => param_addr,
        di    => param_in,
        do    => param_out
        );
  end generate xilinx_gen;

  ---------------------------------------------------------------------------
  -- Can use SRL FIFO since DEPTH=16.
  instr_fifo : fifo_sync
    generic map (
      CFG_FAM      => CFG_FAM,
      C_IMPL_STYLE => 0,  -- if 0, use SRL if DEPTH<=16, LUT-RAM if DEPTH > 16.
      -- if 1, use block RAM
      -- XSTXX block RAM empty signal timing is not yet supported.
      WIDTH        => INSTR_FIFO_WIDTH,
      DEPTH        => INSTR_FIFO_DEPTH)
    port map (
      reset   => reset,
      clk     => FSL_Clk,  -- FSL_Clk and clk must be the same in sync mode.
      we      => fifo_write,
      data_in => fifo_data_in,
      full    => fifo_full,

      rd       => fifo_read,
      data_out => fifo_data_out,
      empty    => fifo_empty
      );

  ---------------------------------------------------------------------------
  fifo_read <= instr_fifo_read;

  instr_fifo_empty <= fifo_empty;

  ---------------------------------------------------------------------------
  fifo_data_in <=
    instr.signedness &
    instr.op &
    instr.in_size &
    instr.out_size &
    instr.three_d &
    instr.two_d &
    instr.acc &
    instr.masked &
    instr.sv &
    instr.ve &
    instr.a &
    instr.b(ADDR_WIDTH-1 downto 0) &
    instr.dest(ADDR_WIDTH downto 0);

  ---------------------------------------------------------------------------
  -- Convert fifo_data_out to output instruction record.

  process (fifo_data_out)
    variable instr_v     : instruction_type;
    variable belowmin    : std_logic;
    variable min_size    : opsize;
    variable output_size : opsize;
    variable i           : integer;
  begin
    i                                 := 0;
    instr_v.dest                      := (others => '0');
    instr_v.dest(ADDR_WIDTH downto 0) := fifo_data_out(i+(ADDR_WIDTH+1)-1 downto i);
    i                                 := i + ADDR_WIDTH+1;
    instr_v.b                         := (others => '0');
    instr_v.b(ADDR_WIDTH-1 downto 0)  := fifo_data_out(i+ADDR_WIDTH-1 downto i);
    i                                 := i + ADDR_WIDTH;
    instr_v.a                         := fifo_data_out(i+32-1 downto i);
    i                                 := i + 32;
    instr_v.ve                        := fifo_data_out(i);
    instr_v.sv                        := fifo_data_out(i+1);
    instr_v.masked                    := fifo_data_out(i+2);
    instr_v.acc                       := fifo_data_out(i+3);
    instr_v.two_d                     := fifo_data_out(i+4);
    instr_v.three_d                   := fifo_data_out(i+5);
    i                                 := i + 6;
    instr_v.out_size                  := fifo_data_out(i+opsize'length-1 downto i);
    i                                 := i + opsize'length;
    instr_v.in_size                   := fifo_data_out(i+opsize'length-1 downto i);
    i                                 := i + opsize'length;
    instr_v.op                        := fifo_data_out(i+opcode'length-1 downto i);
    i                                 := i + opcode'length;
    instr_v.signedness                := fifo_data_out(i);

    -- Default assignments. Not really necessary, since all paths through
    -- this process assign values to these variables,
    belowmin    := '0';
    min_size    := OPSIZE_BYTE;
    output_size := OPSIZE_BYTE;

    -- Derive instr_v.size from in_size, out_size, op, acc, and
    -- MIN_MULTIPLIER_HW.
    if unsigned(instr_v.out_size) > unsigned(instr_v.in_size) then
      output_size := instr_v.out_size;
    else
      output_size := instr_v.in_size;
    end if;

    belowmin := '0';
    if MIN_MULTIPLIER_HW = BYTE then
      min_size := OPSIZE_BYTE;
    elsif MIN_MULTIPLIER_HW = HALF then
      min_size := OPSIZE_HALF;
      if output_size = OPSIZE_BYTE and op_uses_mul(instr_v.op) = '1' then
        belowmin := '1';
      end if;
    else
      min_size := OPSIZE_WORD;
      if output_size /= OPSIZE_WORD and op_uses_mul(instr_v.op) = '1' then
        belowmin := '1';
      end if;
    end if;

    if belowmin = '1' then
      instr_v.size := min_size;
    else
      if instr_v.acc = '1' then
        instr_v.size := instr_v.in_size;
      else
        instr_v.size := output_size;
      end if;
    end if;

    instr_fifo_readdata <= instr_v;

  end process;

  ---------------------------------------------------------------------------

  -- Counter for time-limited evaluation.
  -- Force FSL_M_Full high when counter expires.
  shift_gen : if TIME_LIMIT = true generate
    -- 41-bit counter allows 6h6m at 100MHz.
    -- 39-bit counter allows 1h31m at 100MHz
    -- constant N : integer := 41;
    constant N : integer := 39;
    -- Use LFSR with taps as specified in XAPP052.
    -- (In Spartan-6, 41-bit LFSR with registered done signal uses
    -- 42 flops and 10 LUTs, whereas equivalent 41-bit binary counter uses
    -- 42 flops and 50 LUTs.)
    --
    -- 41-bit LFSR has sequence length of 2**41-1 = 2,199,023,255,551
    -- (all ones value is never reached).
    -- 6 hours at 100 MHz: 6*60*60*100e6 = 2,160,000,000,000 cycles.
    -- 2,160,000,000,000-th value in the sequence (starting at 0) is
    -- 0x1ca36608803.
    -- However if the exact count doesn't matter, we can just use the fact
    -- that the final value in the sequence before wrap-around to 0 is
    -- 0x10000000000 (msb = 1, all other bits 0).
    --
    -- 39-bit LFSR has sequence length of 2**39-1 = 549,755,813,887,
    -- allowing 1h31m hours at 100MHz. Last value before wrap-around to 0
    -- is 0x4000000000.

    -- Converting a large number to a std_logic_vector is cumbersome...
    -- ...Can't specify integer literal larger than 31 bits...
    -- constant TIMEOUT_VAL : std_logic_vector(N downto 1) :=
    --   std_logic_vector(to_unsigned(16#1000#, N-28)) &
    --   std_logic_vector(to_unsigned(16#0000000#, 28));
    -- ...Hex string literal (VHDL-93) can be longer, but must be assigned to
    --    slv that is multiple of 4 bits in length:
    constant TIMEOUT_VAL_HEX : std_logic_vector(40 downto 1) := X"4000000000";
    constant TIMEOUT_VAL     : std_logic_vector(N downto 1)  := TIMEOUT_VAL_HEX(N downto 1);
    -- lfsr
    signal   s               : std_logic_vector(N downto 1);
    signal   done            : std_logic;
  begin
    process (FSL_Clk)
      variable s_in : std_logic;
    begin
      if FSL_Clk'event and FSL_Clk = '1' then
        if reset = '1' then
          s    <= (others => '0');
          done <= '0';
        else
          -- 41-bit LFSR taps:
          -- s_in := s(41) xnor s(38);
          -- 39-bit LFSR taps:
          s_in := s(39) xnor s(35);

          if s = TIMEOUT_VAL or done = '1' then
            done <= '1';
          end if;

          s <= s(N-1 downto 1) & s_in;
        end if;
      end if;
    end process;

    s_done <= done;
  end generate shift_gen;

  no_shift_gen : if TIME_LIMIT = false generate
  begin
    s_done <= '0';
  end generate no_shift_gen;

  FSL_M_Full <= fsl_full or s_done;

  --Track mask status for get mask status instruction
  process (FSL_Clk)
  begin  -- process
    if FSL_Clk'event and FSL_Clk = '1' then  -- rising clock edge
      if mask_status_update = '1' then
        mask_status(31) <= '0';
        mask_status(0)  <= mask_length_nonzero;
      elsif state = S_GET_MASK and FSL_S_Read = '1' then
        mask_status(31) <= '1';
      end if;

      if reset = '1' then               -- synchronous reset (active high)
        mask_status(31) <= '1';
        mask_status(0)  <= '0';
      end if;
    end if;
  end process;
  mask_status(30 downto 1) <= (others => '0');
  
end architecture rtl;
