-- masked_unit.vhd
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

entity masked_unit is
  generic (
    VECTOR_LANES     : integer                    := 1;
    MAX_MASKED_WAVES : positive range 128 to 8192 := 128;
    MASK_PARTITIONS  : natural                    := 1;

    ADDR_WIDTH : integer := 1
    );
  port(
    clk   : in std_logic;
    reset : in std_logic;

    mask_write             : in std_logic;
    mask_write_size        : in opsize;
    mask_write_last        : in std_logic;
    mask_writedata_enables : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    mask_writedata_offset  : in std_logic_vector(ADDR_WIDTH-1 downto 0);

    next_mask           : in  std_logic;
    mask_read_size      : in  opsize;
    mask_status_update  : out std_logic;
    mask_length_nonzero : out std_logic;
    masked_enables      : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    masked_offset       : out std_logic_vector(log2(MAX_MASKED_WAVES*VECTOR_LANES*4)+1 downto 0);
    masked_end          : out std_logic
    );
end entity masked_unit;

architecture whole_waves of masked_unit is
  constant VECTOR_BYTES            : positive                                            := VECTOR_LANES*4;
  constant MASKED_RAM_DEPTH        : positive                                            := MAX_MASKED_WAVES;
  constant MASKED_RAM_DATA_ADDRESS : std_logic_vector(log2(MASKED_RAM_DEPTH)-1 downto 0) := (others => '0');
  constant MASKED_RAM_DATA_ENABLES : std_logic_vector(MASKED_RAM_DATA_ADDRESS'left+(VECTOR_LANES*4) downto
                                                      MASKED_RAM_DATA_ADDRESS'left+1) := (others => '0');
  constant MASKED_RAM_WIDTH : positive := MASKED_RAM_DATA_ENABLES'left+1;

  type   masked_ram_type is array (natural range <>) of std_logic_vector(MASKED_RAM_WIDTH-1 downto 0);
  signal masked_ram : masked_ram_type(MASKED_RAM_DEPTH-1 downto 0);

  signal any_wrenables_valid_d0 : std_logic;

  signal write_address      : unsigned(log2(MASKED_RAM_DEPTH)-1 downto 0);
  signal prev_write_address : unsigned(log2(MASKED_RAM_DEPTH)-1 downto 0);
  signal mask_length        : unsigned(log2(MASKED_RAM_DEPTH)-1 downto 0);

  signal masked_end_s          : std_logic;
  signal mask_length_nonzero_s : std_logic;
  signal next_length_nonzero   : std_logic;

  signal masked_ram_writeenable   : std_logic;
  signal masked_ram_read_address  : std_logic_vector(log2(MASKED_RAM_DEPTH)-1 downto 0);
  signal masked_ram_write_address : std_logic_vector(log2(MASKED_RAM_DEPTH)-1 downto 0);
  signal masked_ram_writedata     : std_logic_vector(MASKED_RAM_WIDTH-1 downto 0);
  signal masked_ram_readdata      : std_logic_vector(MASKED_RAM_WIDTH-1 downto 0);

  signal read_address    : unsigned(log2(MASKED_RAM_DEPTH)-1 downto 0);
  signal read_address_p1 : unsigned(log2(MASKED_RAM_DEPTH)-1 downto 0);
  signal read_selector   : std_logic_vector(1 downto 0);

  signal first_write               : std_logic;
  signal mask_write_last_d0        : std_logic;
  signal mask_write_last_d1        : std_logic;
  signal mask_writedata_enables_d0 : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal mask_writedata_wave_d0    : std_logic_vector(MASKED_RAM_DATA_ADDRESS'length-1 downto 0);

  signal mask_writedata_wave         : std_logic_vector(MASKED_RAM_DATA_ADDRESS'length-1 downto 0);
  signal new_offset                  : std_logic;
  signal mask_writedata_enables_word : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mask_writedata_enables_half : std_logic_vector((VECTOR_LANES*2)-1 downto 0);
  signal write_word_alignment        : std_logic_vector(1 downto 0);
  signal write_half_alignment        : std_logic;

  signal mask_read_wave           : std_logic_vector(MASKED_RAM_DATA_ADDRESS'length-1 downto 0);
  signal mask_read_enables        : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal read_part_last           : std_logic;
  signal read_word_alignment      : std_logic_vector(1 downto 0);
  signal read_word_available      : std_logic_vector(3 downto 0);
  signal read_word_next_available : std_logic_vector(3 downto 0);
  signal read_word_last           : std_logic;
  signal mask_read_word_enables   : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal read_half_alignment      : std_logic_vector(0 downto 0);
  signal read_half_available      : std_logic_vector(1 downto 0);
  signal read_half_next_available : std_logic_vector(1 downto 0);
  signal read_half_last           : std_logic;
  signal mask_read_half_enables   : std_logic_vector((VECTOR_LANES*4)-1 downto 0);

  signal writedata_offset_resized : std_logic_vector(log2(MAX_MASKED_WAVES)+1 downto 0);
begin
  writedata_offset_resized <=
    std_logic_vector(resize(unsigned(mask_writedata_offset(ADDR_WIDTH-1 downto log2(VECTOR_BYTES))),
                            writedata_offset_resized'length));

  --For conversion between halfword or word and elements/bytes
  with mask_write_size select
    mask_writedata_wave <=
    writedata_offset_resized(log2(MAX_MASKED_WAVES)+1 downto 2) when OPSIZE_WORD,
    writedata_offset_resized(log2(MAX_MASKED_WAVES)+0 downto 1) when OPSIZE_HALF,
    writedata_offset_resized(log2(MAX_MASKED_WAVES)-1 downto 0) when others;
  write_word_gen : for gword in VECTOR_LANES-1 downto 0 generate
    mask_writedata_enables_word(gword) <= mask_writedata_enables(gword*4);
  end generate write_word_gen;
  write_word_alignment <= writedata_offset_resized(1 downto 0);
  write_half_gen : for ghalf in (VECTOR_LANES*2)-1 downto 0 generate
    mask_writedata_enables_half(ghalf) <= mask_writedata_enables(ghalf*2);
  end generate write_half_gen;
  write_half_alignment <= writedata_offset_resized(0);

  --Register inputs for timing
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if mask_write_last_d0 = '1' then
        first_write               <= '1';
        mask_writedata_enables_d0 <= (others => '0');
      end if;

      if new_offset = '1' then
        mask_writedata_enables_d0 <= (others => '0');
      end if;

      --Everything is stored as elements/bytes, so adjust words/halfwords
      if mask_write = '1' then
        first_write            <= '0';
        mask_writedata_wave_d0 <= mask_writedata_wave;

        case mask_write_size is
          when OPSIZE_WORD =>
            case write_word_alignment is
              when "11" =>
                mask_writedata_enables_d0((4*VECTOR_LANES)-1 downto 3*VECTOR_LANES) <= mask_writedata_enables_word;
              when "10" =>
                mask_writedata_enables_d0((3*VECTOR_LANES)-1 downto 2*VECTOR_LANES) <= mask_writedata_enables_word;
              when "01" =>
                mask_writedata_enables_d0((2*VECTOR_LANES)-1 downto VECTOR_LANES) <= mask_writedata_enables_word;
              when others =>
                mask_writedata_enables_d0(VECTOR_LANES-1 downto 0) <= mask_writedata_enables_word;
            end case;
          when OPSIZE_HALF =>
            case write_half_alignment is
              when '1' =>
                mask_writedata_enables_d0((4*VECTOR_LANES)-1 downto 2*VECTOR_LANES) <= mask_writedata_enables_half;
              when others =>
                mask_writedata_enables_d0((2*VECTOR_LANES)-1 downto 0) <= mask_writedata_enables_half;
            end case;
          when others =>
            mask_writedata_enables_d0 <= mask_writedata_enables;
        end case;
      end if;

      mask_write_last_d0 <= mask_write_last;
      mask_write_last_d1 <= mask_write_last_d0;

      if reset = '1' then
        first_write               <= '1';
        mask_writedata_enables_d0 <= (others => '0');
      end if;
    end if;
  end process;
  new_offset <= mask_write when mask_writedata_wave /= mask_writedata_wave_d0 else '0';

  any_wrenables_valid_d0 <=
    '1' when mask_writedata_enables_d0 /= std_logic_vector(to_unsigned(0, mask_writedata_enables_d0'length)) else '0';

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if first_write = '0' and any_wrenables_valid_d0 = '1' and new_offset = '1' then
        write_address       <= write_address + to_unsigned(1, write_address'length);
        prev_write_address  <= write_address;
        next_length_nonzero <= '1';
      end if;

      if mask_write_last_d0 = '1' then
        write_address       <= to_unsigned(0, write_address'length);
        prev_write_address  <= to_unsigned(0, prev_write_address'length);
        next_length_nonzero <= '0';
        if any_wrenables_valid_d0 = '1' then
          mask_length           <= write_address + to_unsigned(1, write_address'length);
          mask_length_nonzero_s <= '1';
        else
          mask_length           <= write_address;
          mask_length_nonzero_s <= next_length_nonzero;
        end if;
        
      end if;

      if reset = '1' then               -- synchronous reset (active high)
        write_address         <= to_unsigned(0, write_address'length);
        prev_write_address    <= to_unsigned(0, prev_write_address'length);
        mask_length           <= to_unsigned(0, mask_length'length);
        next_length_nonzero   <= '0';
        mask_length_nonzero_s <= '0';
      end if;
    end if;
  end process;

  mask_status_update  <= mask_write_last_d1;
  mask_length_nonzero <= mask_length_nonzero_s;

  --Write when switching offsets, or at the end of the vector
  masked_ram_writeenable <=
    (new_offset and (not first_write) and (any_wrenables_valid_d0 or (not next_length_nonzero))) or mask_write_last_d0;
  masked_ram_writedata(MASKED_RAM_DATA_ADDRESS'range) <= mask_writedata_wave_d0;
  masked_ram_writedata(MASKED_RAM_DATA_ENABLES'range) <= mask_writedata_enables_d0;
  masked_ram_write_address                            <= std_logic_vector(write_address);

  --Actual masked RAM inferred from this process
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if masked_ram_writeenable = '1' then
        masked_ram(to_integer(unsigned(masked_ram_write_address))) <= masked_ram_writedata;
      end if;
      masked_ram_readdata <= masked_ram(to_integer(unsigned(masked_ram_read_address)));
    end if;
  end process;
  mask_read_enables <= masked_ram_readdata(MASKED_RAM_DATA_ENABLES'range);
  mask_read_wave    <= masked_ram_readdata(MASKED_RAM_DATA_ADDRESS'range);

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      read_address <= unsigned(masked_ram_read_address);

      if reset = '1' then               -- synchronous reset (active high)
        read_address <= to_unsigned(0, read_address'length);
      end if;
    end if;
  end process;

  read_address_p1 <= read_address + to_unsigned(1, read_address'length);

  with mask_read_size select
    read_part_last <=
    read_word_last when OPSIZE_WORD,
    read_half_last when OPSIZE_HALF,
    '1'            when others;
  masked_end_s <= read_part_last when read_address_p1 = mask_length else (not mask_length_nonzero_s);

  read_selector <= (read_part_last and next_mask) & masked_end_s;
  with read_selector select
    masked_ram_read_address <=
    std_logic_vector(read_address_p1) when "10",
    (others => '0')                   when "11",
    std_logic_vector(read_address)    when others;

  --Halfword/word masks need to be expanded; unused partial waves skipped, the
  --next available partial wave selected, and select enables expanded
  word_expander : wave_expander
    generic map (
      VECTOR_LANES => VECTOR_LANES,
      PARTS        => 4
      )
    port map (
      enables_in => mask_read_enables,
      available  => read_word_available,

      alignment      => read_word_alignment,
      next_available => read_word_next_available,
      last           => read_word_last,
      enables_out    => mask_read_word_enables
      );
  half_expander : wave_expander
    generic map (
      VECTOR_LANES => VECTOR_LANES,
      PARTS        => 2
      )
    port map (
      enables_in => mask_read_enables,
      available  => read_half_available,

      alignment      => read_half_alignment,
      next_available => read_half_next_available,
      last           => read_half_last,
      enables_out    => mask_read_half_enables
      );
  --Keep track of which partial waves still need to be read out
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if next_mask = '1' then
        if read_half_last = '1' or mask_read_size /= OPSIZE_HALF then
          read_half_available <= (others => '1');
        else
          read_half_available <= read_half_next_available;
        end if;
        if read_word_last = '1' or mask_read_size /= OPSIZE_WORD then
          read_word_available <= (others => '1');
        else
          read_word_available <= read_word_next_available;
        end if;
      end if;

      if reset = '1' then               -- synchronous reset (active high)
        read_half_available <= (others => '1');
        read_word_available <= (others => '1');
      end if;
    end if;
  end process;

  masked_end <= masked_end_s;
  with mask_read_size select
    masked_enables <=
    mask_read_word_enables when OPSIZE_WORD,
    mask_read_half_enables when OPSIZE_HALF,
    mask_read_enables      when others;
  with mask_read_size select
    masked_offset(masked_offset'left downto log2(VECTOR_BYTES)) <=
    mask_read_wave & read_word_alignment       when OPSIZE_WORD,
    '0' & mask_read_wave & read_half_alignment when OPSIZE_HALF,
    "00" & mask_read_wave                      when others;

  masked_offset(log2(VECTOR_BYTES)-1 downto 0) <= (others => '0');

end architecture whole_waves;
