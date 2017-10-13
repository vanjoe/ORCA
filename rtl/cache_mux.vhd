library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

-- TODO Implement support for pipelined reads and writes through this mux.
-- One option would be to use a FIFO for the cache select values as well as the address
-- of the read, and complete all transactions while the FIFO is not empty. The mux should
-- be able to accept further transactions as long the FIFO is not full.
-- Another option would be to stop accepting transactions when we change from one bus to 
-- another, process all remaining transactions to the old bus, then start accepting new
-- transactions for the new bus.

entity cache_mux is
  generic (
    REGISTER_SIZE   : positive range 32 to 64       := 32;
    CACHE_SIZE      : natural                       := 0;
    CACHE_LINE_SIZE : integer range 16 to 256       := 32;
    UC_ADDR_BASE    : std_logic_vector(31 downto 0) := X"00000000";
    UC_ADDR_LAST    : std_logic_vector(31 downto 0) := X"00000000";
    AUX_ADDR_BASE   : std_logic_vector(31 downto 0) := X"00000000";
    AUX_ADDR_LAST   : std_logic_vector(31 downto 0) := X"00000000";
    MAX_BURST_BEATS : positive                      := 16;
    ADDR_WIDTH      : integer                       := 32;
    DATA_WIDTH      : integer                       := 32
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    --Orca-internal memory-mapped slave
    oimm_address       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    oimm_byteenable    : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    oimm_requestvalid  : in  std_logic;
    oimm_readnotwrite  : in  std_logic;
    oimm_writedata     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    oimm_readdata      : out std_logic_vector(DATA_WIDTH-1 downto 0);
    oimm_readdatavalid : out std_logic;
    oimm_waitrequest   : out std_logic;

    --Cache interface Orca-internal memory-mapped master
    cacheint_oimm_address       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    cacheint_oimm_byteenable    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    cacheint_oimm_requestvalid  : out std_logic;
    cacheint_oimm_readnotwrite  : out std_logic;
    cacheint_oimm_writedata     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    cacheint_oimm_readdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    cacheint_oimm_readdatavalid : in  std_logic;
    cacheint_oimm_waitrequest   : in  std_logic;

    --Uncached Orca-internal memory-mapped master
    uc_oimm_address       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    uc_oimm_byteenable    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    uc_oimm_requestvalid  : out std_logic;
    uc_oimm_readnotwrite  : out std_logic;
    uc_oimm_writedata     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    uc_oimm_readdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    uc_oimm_readdatavalid : in  std_logic;
    uc_oimm_waitrequest   : in  std_logic;

    --Tightly-coupled memory Orca-internal memory-mapped master
    aux_oimm_address       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    aux_oimm_byteenable    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    aux_oimm_requestvalid  : out std_logic;
    aux_oimm_readnotwrite  : out std_logic;
    aux_oimm_writedata     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    aux_oimm_readdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    aux_oimm_readdatavalid : in  std_logic;
    aux_oimm_waitrequest   : in  std_logic
    );
end entity cache_mux;

architecture rtl of cache_mux is
  signal oimm_readdatavalid_int : std_logic;
  signal oimm_waitrequest_int   : std_logic;
  signal c_select               : std_logic;
  signal uc_select              : std_logic;
  signal aux_select             : std_logic;
  signal reading                : std_logic;
  signal read_stall             : std_logic;
begin
  oimm_readdatavalid <= oimm_readdatavalid_int;
  oimm_waitrequest   <= oimm_waitrequest_int;

  cacheint_oimm_address    <= oimm_address;
  cacheint_oimm_byteenable <= oimm_byteenable;
  cacheint_oimm_writedata  <= oimm_writedata;

  uc_oimm_address    <= oimm_address;
  uc_oimm_byteenable <= oimm_byteenable;
  uc_oimm_writedata  <= oimm_writedata;

  aux_oimm_address    <= oimm_address;
  aux_oimm_byteenable <= oimm_byteenable;
  aux_oimm_writedata  <= oimm_writedata;

  --Generate control signals depending on which interfaces are enabled and if
  --the address ranges overalp.  Cache has all unspecified addresses.  If AUX
  --and UC overlap use AUX.
  no_aux_gen : if AUX_ADDR_BASE = AUX_ADDR_LAST generate
    aux_select <= '0';
    no_uc_gen : if UC_ADDR_BASE = UC_ADDR_LAST generate
      uc_select <= '0';
      no_c_gen : if CACHE_SIZE = 0 generate
        c_select               <= '0';
        oimm_readdata          <= (others => '-');
        oimm_readdatavalid_int <= '0';
        assert true report
          "Error; Cache is disabled (CACHE_SIZE = 0), UC interface is disabled (UC_ADDR_BASE = UC_ADDR_LAST), and AUX interface is disabled (AUX_ADDR_BASE = AUX_ADDR_LAST).  At least one interface must be enabled."
          severity failure;
      end generate no_c_gen;
      has_c_gen : if CACHE_SIZE /= 0 generate
        c_select               <= '1';
        oimm_readdata          <= cacheint_oimm_readdata;
        oimm_readdatavalid_int <= cacheint_oimm_readdatavalid;
      end generate has_c_gen;
    end generate no_uc_gen;
    has_uc_gen : if UC_ADDR_BASE /= UC_ADDR_LAST generate
      no_c_gen : if CACHE_SIZE = 0 generate
        uc_select              <= '1';
        oimm_readdata          <= uc_oimm_readdata;
        oimm_readdatavalid_int <= uc_oimm_readdatavalid;
        assert not ((unsigned(UC_ADDR_BASE) /= to_unsigned(0, UC_ADDR_BASE'length)) or
                    (signed(UC_ADDR_LAST) /= to_signed(-1, UC_ADDR_LAST'length))) report
          "Warning; Cache is disabled (CACHE_SIZE = 0) and AUX interface is disabled (AUX_ADDR_BASE = AUX_ADDR_LAST) but UC address range does not encompass the full address range.  All accesses will go to UC interface, even those not in the UC address range.  Please set UC address range to the full address range."
          severity warning;
      end generate no_c_gen;
      has_c_gen : if CACHE_SIZE /= 0 generate
        uc_select <=
          '1' when ((unsigned(oimm_address) >= unsigned(UC_ADDR_BASE(ADDR_WIDTH-1 downto 0))) and
                    (unsigned(oimm_address) <= unsigned(UC_ADDR_LAST(ADDR_WIDTH-1 downto 0)))) else
          '0';

        oimm_readdata <= cacheint_oimm_readdata when cacheint_oimm_readdatavalid = '1' else
                         uc_oimm_readdata;
        oimm_readdatavalid_int <= cacheint_oimm_readdatavalid or uc_oimm_readdatavalid;
        assert not ((unsigned(UC_ADDR_BASE) = to_unsigned(0, UC_ADDR_BASE'length)) and
                    (signed(UC_ADDR_LAST) = to_signed(-1, UC_ADDR_LAST'length))) report
          "Error; Cache is enabled (CACHE_SIZE /= 0) but UC address range encompasses the full address range so no accesses will go to the cache.  Please disable the cache or set the UC address range to not encompass the full address range."
          severity failure;
      end generate has_c_gen;
    end generate has_uc_gen;
  end generate no_aux_gen;
  has_aux_gen : if AUX_ADDR_BASE /= AUX_ADDR_LAST generate
    aux_select <=
      '1' when ((unsigned(oimm_address) >= unsigned(AUX_ADDR_BASE(ADDR_WIDTH-1 downto 0))) and
                (unsigned(oimm_address) <= unsigned(AUX_ADDR_LAST(ADDR_WIDTH-1 downto 0)))) else
      '0';
    no_uc_gen : if UC_ADDR_BASE = UC_ADDR_LAST generate
      uc_select <= '0';
      no_c_gen : if CACHE_SIZE = 0 generate
        c_select               <= '0';
        oimm_readdata          <= aux_oimm_readdata;
        oimm_readdatavalid_int <= aux_oimm_readdatavalid;
        assert not ((unsigned(AUX_ADDR_BASE) /= to_unsigned(0, AUX_ADDR_BASE'length)) or
                    (signed(AUX_ADDR_LAST) /= to_signed(-1, AUX_ADDR_LAST'length))) report
          "Warning; Cache is disabled (CACHE_SIZE = 0) and UC interface is disabled (UC_ADDR_BASE = UC_ADDR_LAST) but AUX address range does not encompass the full address range.  All accesses will go to AUX interface, even those not in the AUX address range.  Please set AUX address range to the full address range."
          severity warning;
      end generate no_c_gen;
      has_c_gen : if CACHE_SIZE /= 0 generate
        c_select      <= not aux_select;
        oimm_readdata <= cacheint_oimm_readdata when cacheint_oimm_readdatavalid = '1' else
                         aux_oimm_readdata;
        oimm_readdatavalid_int <= cacheint_oimm_readdatavalid or aux_oimm_readdatavalid;
        assert not ((unsigned(AUX_ADDR_BASE) <= to_unsigned(0, AUX_ADDR_BASE'length)) and
                    (signed(AUX_ADDR_LAST) = to_signed(-1, AUX_ADDR_LAST'length))) report
          "Error; Cache is enabled (CACHE_SIZE /= 0) but AUX address range encompasses the full address range so no accesses will go to the cache.  Please disable the cache or set the AUX address range to not encompass the full address range."
          severity failure;
      end generate has_c_gen;
    end generate no_uc_gen;
    has_uc_gen : if UC_ADDR_BASE /= UC_ADDR_LAST generate
      no_c_gen : if CACHE_SIZE = 0 generate
        uc_select     <= not aux_select;
        c_select      <= '0';
        oimm_readdata <= uc_oimm_readdata when uc_oimm_readdatavalid = '1' else
                         aux_oimm_readdata;
        oimm_readdatavalid_int <= uc_oimm_readdatavalid or aux_oimm_readdatavalid;

        assert not ((unsigned(UC_ADDR_BASE) /= to_unsigned(0, UC_ADDR_BASE'length)) or
                    (signed(UC_ADDR_LAST) /= to_signed(-1, UC_ADDR_LAST'length))) report
          "Warning; Cache is disabled (CACHE_SIZE = 0) and UC interface is enabled (UC_ADDR_BASE /= UC_ADDR_LAST) but UC address range does not encompass the full address range.  Any accesses outside the AUX address range will go to the UC interface, even those not in the UC address range.  Please set UC address range to the full address range."
          severity warning;
      end generate no_c_gen;
      has_c_gen : if CACHE_SIZE /= 0 generate
        overlap_gen : if ((unsigned(AUX_ADDR_BASE(ADDR_WIDTH-1 downto 0)) <=
                           unsigned(UC_ADDR_LAST(ADDR_WIDTH-1 downto 0))) and
                          (unsigned(AUX_ADDR_LAST(ADDR_WIDTH-1 downto 0)) >=
                           unsigned(UC_ADDR_BASE(ADDR_WIDTH-1 downto 0)))) generate
          uc_select <=
            (not aux_select) when ((unsigned(oimm_address) >= unsigned(UC_ADDR_BASE(ADDR_WIDTH-1 downto 0))) and
                                   (unsigned(oimm_address) <= unsigned(UC_ADDR_LAST(ADDR_WIDTH-1 downto 0)))) else
            '0';
          assert true report
            "AUX and UC port addresses overlap; AUX will be used for overlapping addresses."
            severity note;
        end generate overlap_gen;
        no_overlap_gen : if ((unsigned(AUX_ADDR_BASE(ADDR_WIDTH-1 downto 0)) >
                              unsigned(UC_ADDR_LAST(ADDR_WIDTH-1 downto 0))) or
                             (unsigned(AUX_ADDR_LAST(ADDR_WIDTH-1 downto 0)) <
                              unsigned(UC_ADDR_BASE(ADDR_WIDTH-1 downto 0)))) generate
          uc_select <=
            '1' when ((unsigned(oimm_address) >= unsigned(UC_ADDR_BASE(ADDR_WIDTH-1 downto 0))) and
                      (unsigned(oimm_address) <= unsigned(UC_ADDR_LAST(ADDR_WIDTH-1 downto 0)))) else
            '0';
          assert true report
            "AUX and UC port addresses do not overlap"
            severity note;
        end generate no_overlap_gen;
        c_select      <= (not uc_select) and (not aux_select);
        oimm_readdata <= cacheint_oimm_readdata when cacheint_oimm_readdatavalid = '1' else
                         uc_oimm_readdata when uc_oimm_readdatavalid = '1' else
                         aux_oimm_readdata;
        oimm_readdatavalid_int <= cacheint_oimm_readdatavalid or uc_oimm_readdatavalid or aux_oimm_readdatavalid;

        assert not (((unsigned(UC_ADDR_BASE) = to_unsigned(0, UC_ADDR_BASE'length)) and
                     ((signed(UC_ADDR_LAST) = to_signed(-1, UC_ADDR_LAST'length)) or
                      ((signed(AUX_ADDR_LAST) = to_signed(-1, AUX_ADDR_LAST'length)) and
                       (unsigned(AUX_ADDR_BASE) <= (unsigned(UC_ADDR_LAST) + to_unsigned(1, UC_ADDR_LAST'length)))))) or
                    ((unsigned(AUX_ADDR_BASE) = to_unsigned(0, AUX_ADDR_BASE'length)) and
                     ((signed(AUX_ADDR_LAST) = to_signed(-1, AUX_ADDR_LAST'length)) or
                      ((signed(UC_ADDR_LAST) = to_signed(-1, UC_ADDR_LAST'length)) and
                       (unsigned(UC_ADDR_BASE) <= (unsigned(AUX_ADDR_LAST) + to_unsigned(1, AUX_ADDR_LAST'length)))))))
          report
          "Error; Cache is enabled (CACHE_SIZE /= 0) but UC and AUX interfaces cover the entire address range so no accesses will go to cache.  Please disable cache or set the UC and AUX address ranges to not encompass the entire address range."
          severity failure;
      end generate has_c_gen;
      assert not ((unsigned(AUX_ADDR_BASE) <= unsigned(UC_ADDR_BASE)) and
                  (unsigned(AUX_ADDR_LAST) >= unsigned(UC_ADDR_LAST))) report
        "Error; UC interface is enabled (UC_ADDR_BASE /= UC_ADDR_LAST) but AUX address range encompasses the UC address range so no accesses will go to UC.  Please disable UC or set the AUX address range to not encompass the UC address range."
        severity failure;
    end generate has_uc_gen;
  end generate has_aux_gen;

  --Assumes only one read request in flight and no extraneous responses coming in.
  read_stall           <= reading and (not oimm_readdatavalid_int);
  oimm_waitrequest_int <= read_stall or
                          ((cacheint_oimm_waitrequest and c_select) or
                           (uc_oimm_waitrequest and uc_select) or
                           (aux_oimm_waitrequest and aux_select));

  cacheint_oimm_requestvalid <= oimm_requestvalid and (not read_stall) and c_select;
  cacheint_oimm_readnotwrite <= oimm_readnotwrite;

  uc_oimm_requestvalid <= oimm_requestvalid and (not read_stall) and uc_select;
  uc_oimm_readnotwrite <= oimm_readnotwrite;

  aux_oimm_requestvalid <= oimm_requestvalid and (not read_stall) and aux_select;
  aux_oimm_readnotwrite <= oimm_readnotwrite;

  process(clk)
  begin
    if rising_edge(clk) then
      if oimm_readdatavalid_int = '1' then
        reading <= '0';
      end if;
      if oimm_requestvalid = '1' and oimm_readnotwrite = '1' and oimm_waitrequest_int = '0' then
        reading <= '1';
      end if;

      if reset = '1' then
        reading <= '0';
      end if;
    end if;
  end process;

  assert not (unsigned(AUX_ADDR_BASE) > unsigned(AUX_ADDR_LAST)) report
    "Error; AUX_ADDR_BASE (" &
    natural'image(to_integer(unsigned(AUX_ADDR_BASE))) &
    ") is greater than AUX_ADDR_LAST (" &
    natural'image(to_integer(unsigned(AUX_ADDR_LAST))) &
    ")."
    severity failure;

  assert not ((AUX_ADDR_BASE /= AUX_ADDR_LAST) and
              (CACHE_SIZE /= 0) and
              ((to_integer(unsigned(AUX_ADDR_BASE)) mod CACHE_LINE_SIZE) /= 0)) report
    "Error; AUX_ADDR_BASE (" &
    natural'image(to_integer(unsigned(AUX_ADDR_BASE))) &
    ") must be aligned to CACHE_LINE_SIZE (" &
    positive'image(CACHE_LINE_SIZE) &
    ") when cache is enabled."
    severity failure;

  assert not ((AUX_ADDR_BASE /= AUX_ADDR_LAST) and
              (CACHE_SIZE = 0) and
              ((to_integer(unsigned(AUX_ADDR_BASE)) mod (REGISTER_SIZE/8)) /= 0)) report
    "Error; AUX_ADDR_BASE (" &
    natural'image(to_integer(unsigned(AUX_ADDR_BASE))) &
    ") must be aligned to REGISTER_SIZE/8 (" &
    positive'image(REGISTER_SIZE/8) &
    ") when cache is disabled."
    severity failure;

  assert not ((AUX_ADDR_BASE /= AUX_ADDR_LAST) and
              (CACHE_SIZE /= 0) and
              ((to_integer(unsigned(AUX_ADDR_LAST)) mod CACHE_LINE_SIZE) /= (CACHE_LINE_SIZE-1))) report
    "Error; AUX_ADDR_LAST (" &
    natural'image(to_integer(unsigned(AUX_ADDR_LAST))) &
    ") mod CACHE_LINE_SIZE (" &
    positive'image(CACHE_LINE_SIZE) &
    ") must be CACHE_LINE_SIZE-1 when cache is enabled."
    severity failure;

  assert not ((AUX_ADDR_BASE /= AUX_ADDR_LAST) and
              (CACHE_SIZE = 0) and
              ((to_integer(unsigned(AUX_ADDR_LAST)) mod (REGISTER_SIZE/8)) /= ((REGISTER_SIZE/8)-1))) report
    "Error; AUX_ADDR_LAST (" &
    natural'image(to_integer(unsigned(AUX_ADDR_LAST))) &
    ") mod REGISTER_SIZE/8 (" &
    positive'image(REGISTER_SIZE/8) &
    ") must be (REGISTER_SIZE/8)-1 when cache is disabled."
    severity failure;

  assert not (unsigned(UC_ADDR_BASE) > unsigned(UC_ADDR_LAST)) report
    "Error; UC_ADDR_BASE (" &
    natural'image(to_integer(unsigned(UC_ADDR_BASE))) &
    ") is greater than UC_ADDR_LAST (" &
    natural'image(to_integer(unsigned(UC_ADDR_LAST))) &
    ")."
    severity failure;

  assert not ((UC_ADDR_BASE /= UC_ADDR_LAST) and
              (CACHE_SIZE /= 0) and
              ((to_integer(unsigned(UC_ADDR_BASE)) mod CACHE_LINE_SIZE) /= 0)) report
    "Error; UC_ADDR_BASE (" &
    natural'image(to_integer(unsigned(UC_ADDR_BASE))) &
    ") must be aligned to CACHE_LINE_SIZE (" &
    positive'image(CACHE_LINE_SIZE) &
    ") when cache is enabled."
    severity failure;

  assert not ((UC_ADDR_BASE /= UC_ADDR_LAST) and
              (CACHE_SIZE = 0) and
              ((to_integer(unsigned(UC_ADDR_BASE)) mod (REGISTER_SIZE/8)) /= 0)) report
    "Error; UC_ADDR_BASE (" &
    natural'image(to_integer(unsigned(UC_ADDR_BASE))) &
    ") must be aligned to REGISTER_SIZE/8 (" &
    positive'image(REGISTER_SIZE/8) &
    ") when cache is disabled."
    severity failure;

  assert not ((UC_ADDR_BASE /= UC_ADDR_LAST) and
              (CACHE_SIZE /= 0) and
              ((to_integer(unsigned(UC_ADDR_LAST)) mod CACHE_LINE_SIZE) /= (CACHE_LINE_SIZE-1))) report
    "Error; UC_ADDR_LAST (" &
    natural'image(to_integer(unsigned(UC_ADDR_LAST))) &
    ") mod CACHE_LINE_SIZE (" &
    positive'image(CACHE_LINE_SIZE) &
    ") must be CACHE_LINE_SIZE-1 when cache is enabled."
    severity failure;

  assert not ((UC_ADDR_BASE /= UC_ADDR_LAST) and
              (CACHE_SIZE = 0) and
              ((to_integer(unsigned(UC_ADDR_LAST)) mod (REGISTER_SIZE/8)) /= ((REGISTER_SIZE/8)-1))) report
    "Error; UC_ADDR_LAST (" &
    natural'image(to_integer(unsigned(UC_ADDR_LAST))) &
    ") mod REGISTER_SIZE/8 (" &
    positive'image(REGISTER_SIZE/8) &
    ") must be (REGISTER_SIZE/8)-1 when cache is disabled."
    severity failure;

end architecture;
