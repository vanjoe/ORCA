library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.top_component_pkg.all;
use work.top_util_pkg.all;


entity wb_flash_dma is
  generic (
    MAX_LENGTH : integer);
  port (

    clk_i : in std_logic;
    rst_i : in std_logic;

    master_ADR_O   : out std_logic_vector(32-1 downto 0);
    master_DAT_I   : in  std_logic_vector(32-1 downto 0);
    master_DAT_O   : out std_logic_vector(32-1 downto 0);
    master_WE_O    : out std_logic;
    master_SEL_O   : out std_logic_vector(32/8 -1 downto 0);
    master_STB_O   : out std_logic;
    master_ACK_I   : in  std_logic;
    master_CYC_O   : out std_logic;
    master_CTI_O   : out std_logic_vector(2 downto 0);
    master_STALL_I : in  std_logic;

    slave_ADR_I   : in  std_logic_vector(3 downto 0);
    slave_DAT_O   : out std_logic_vector(32-1 downto 0);
    slave_DAT_I   : in  std_logic_vector(32-1 downto 0);
    slave_WE_I    : in  std_logic;
    slave_SEL_I   : in  std_logic_vector(32/8 -1 downto 0);
    slave_STB_I   : in  std_logic;
    slave_ACK_O   : out std_logic;
    slave_CYC_I   : in  std_logic;
    slave_CTI_I   : in  std_logic_vector(2 downto 0);
    slave_STALL_O : out std_logic;

    --spi signals
    spi_mosi : out std_logic;
    spi_miso : in  std_logic;
    spi_ss   : out std_logic;
    spi_sclk : out std_logic

    );
end entity wb_flash_dma;

architecture rtl of wb_flash_dma is
  -----------------------------------------------------------------------------
  -- REGISTER MAP
  -- 0x0  (write only)  ADDRESS TO READ FROM (FLASH)
  -- 0x4  (write only)  ADDRESS TO WRITE TO  (scratchpad)
  -- 0x8  (write only)  LENGTH TO READ
  -- 0xC  (read only)   STATUS  (bit 31 = initializing, other bits = transfer bytes left)
  -- Transfers are started by writing to the LENGTH register
  -----------------------------------------------------------------------------
  constant REG_RADDRESS : std_logic_vector(slave_ADR_I'range) := x"0";
  constant REG_WADDRESS : std_logic_vector(slave_ADR_I'range) := x"4";
  constant REG_LENGTH   : std_logic_vector(slave_ADR_I'range) := x"8";
  constant REG_STATUS   : std_logic_vector(slave_ADR_I'range) := x"C";



  signal spi_adr   : std_logic_vector(7 downto 0);
  signal spi_rdat  : std_logic_vector(7 downto 0);
  signal spi_wdat  : std_logic_vector(7 downto 0);
  signal spi_cyc   : std_logic;
  signal spi_sel   : std_logic;
  signal spi_we    : std_logic;
  signal spi_ack   : std_logic;
  signal spi_stall : std_logic;
  signal spi_stb   : std_logic;


  signal done_transfer : std_logic;
  signal spi_data_out  : std_logic_vector(7 downto 0);
  signal initializing  : std_logic;

  type state_t is (RESET, WAKE_0, WAKE_1, IDLE, ADDR_0, ADDR_1, ADDR_2,
                   READ_SPI, WRITE_MASTER_0, WRITE_MASTER_1, TRANSITION);

  signal cur_state       : state_t;
  signal next_state      : state_t;
  signal xferlen_count   : unsigned(log2(MAX_LENGTH/4)-1 downto 0);
  signal word_count      : unsigned(1 downto 0);
  signal init_loop_count : integer range 0 to 10;
  signal start_xfer      : std_logic;

  signal raddress_register : std_logic_vector(23 downto 0);
  signal waddress_register : std_logic_vector(31 downto 0);
  signal waddress_counter  : unsigned(31 downto 0);
  signal length_register   : std_logic_vector(log2(MAX_LENGTH)-1 downto 0);

  signal data_register : std_logic_vector(master_dat_o'range);

  constant CMD_WAKEUP : std_logic_vector(7 downto 0) := x"AB";
  constant CMD_READ   : std_logic_vector(7 downto 0) := x"03";

  signal ss_vec       : std_logic_vector(0 downto 0);
  signal first_byte   : std_logic;
  signal slave_select : std_logic;

--  alias init_loop_count is xferlen_count;
begin  -- architecture rtl

  spi_control : component wb_spimaster
    port map(
      clk_i => clk_i,
      rst_i => rst_i,

      adr_i => spi_adr,
      dat_i => spi_wdat,
      dat_o => spi_rdat,
      cyc_i => spi_cyc,
      sel_i => spi_sel,
      we_i  => spi_we,
      ack_o => spi_ack,
      stb_i => spi_stb,

      done_transfer => done_transfer,
      data_out      => spi_data_out,

      spi_miso => spi_miso,
      spi_mosi => spi_mosi,
      spi_sclk => spi_sclk,
      spi_ss   => ss_vec

      );
  spi_ss <= '0' when ss_vec(0) = '0' or slave_select = '0' else '1';

  spi_sel <= '1';
  spi_we  <= '1';
  spi_stb <= spi_cyc;
  spi_adr <= (others => '0');

  state_machine : process(clk_i)
  begin
    if rising_edge(clk_i) then
      spi_cyc  <= '0';
      spi_wdat <= (others => '0');


      --------------------------------------------------------------------------
      -- There is a weirdness to this statemachine, there is a do-nothing
      -- tate called "TRANSIIION", this allows us to insert a pause while
      -- the writes take hold in the spi registers
      --------------------------------------------------------------------------

      case cur_state is
        when RESET =>
          cur_state    <= WAKE_0;
          slave_select <= '1';
          initializing <= '1';
        when WAKE_0 =>
          --read 5 bytes before checking if woken up
          init_loop_count <= 5;
          spi_wdat        <= CMD_WAKEUP;
          spi_cyc         <= '1';
          next_state      <= WAKE_1;
          cur_state       <= TRANSITION;
          slave_select    <= '0';
        when WAKE_1 =>
          --if done transfer, and done all reads, check output,and retry if not
          --correct, go to idle if correct
          -- if done transfer and not done all reads, send another dummy byte,
          -- and read another.
          -- if not done transfer do nothing
          if done_transfer = '1' then
            if init_loop_count = 0 then
              if spi_data_out = x"13" or spi_data_out = x"15" or true then
                next_state   <= IDLE;
                cur_state    <= TRANSITION;
                initializing <= '0';
              else
                next_state <= RESET;
                cur_state  <= TRANSITION;
              end if;
            else
              init_loop_count <= init_loop_count -1;
              next_state      <= WAKE_1;
              cur_state       <= TRANSITION;
              spi_cyc         <= '1';
            end if;
          end if;
        when IDLE =>
          --wait for signal to start next transfer
          slave_select <= '1';
          word_count   <= "00";
          if start_xfer = '1' then
            xferlen_count    <= unsigned(length_register(length_register'left downto 2));
            waddress_counter <= unsigned(waddress_register);
            spi_wdat         <= CMD_READ;
            spi_cyc          <= '1';
            cur_state        <= TRANSITION;
            next_state       <= ADDR_0;
            slave_select     <= '0';
          end if;
        when ADDR_0 =>
          if done_transfer = '1' then
            spi_wdat   <= raddress_register(23 downto 16);
            spi_cyc    <= '1';
            next_state <= ADDR_1;
            cur_state  <= TRANSITION;
          end if;
        when ADDR_1 =>
          if done_transfer = '1' then
            spi_wdat   <= raddress_register(15 downto 8);
            spi_cyc    <= '1';
            next_state <= ADDR_2;
            cur_state  <= TRANSITION;
          end if;

        when ADDR_2 =>
          if done_transfer = '1' then
            spi_wdat   <= raddress_register(7 downto 0);
            spi_cyc    <= '1';
            next_state <= READ_SPI;
            cur_state  <= TRANSITION;
            first_byte <= '1';

          end if;
        when READ_SPI =>
          if done_transfer = '1' then

            data_register <= data_register(data_register'left-8 downto 0) & spi_data_out;
            word_count    <= word_count -1;
            --DUMMY BYTE
            spi_cyc       <= '1';
            next_state    <= cur_state;
            cur_state     <= TRANSITION;
            if first_byte = '0' then
              --every 4 bytes, write via master
              if word_count = "00" then
                next_state <= WRITE_MASTER_0;
                --dont start another read on next xfer
                if xferlen_count = 1 then
                  spi_cyc <= '0';
                end if;
              end if;

            else
              first_byte <= '0';
            end if;

          end if;
        when WRITE_MASTER_0 =>
          if master_stall_i = '0' then
            cur_state        <= READ_SPI;
            waddress_counter <= waddress_counter + 4;
            xferlen_count    <= xferlen_count -1;
            if xferlen_count = 1 then
              cur_state <= IDLE;
            end if;
          end if;
        when TRANSITION =>
          cur_state <= next_state;
        when others =>
          cur_state <= RESET;
      end case;

      if rst_i = '1' then
        cur_state     <= RESET;
        xferlen_count <= (others => '0');
        data_register <= (others => '0');
      end if;
    end if;
  end process;

  master_adr_o  <= std_logic_vector(waddress_counter);
  master_stb_o  <= '1' when cur_state = WRITE_MASTER_0 else '0';
  master_cyc_o  <= '1' when cur_state = WRITE_MASTER_0 else '0';
  master_we_o   <= '1' when cur_state = WRITE_MASTER_0 else '0';
  master_sel_o  <= (others => '1');
  --endian madness
  master_dat_o  <= data_register(7 downto 0) & data_register(15 downto 8) & data_register(23 downto 16) & data_register(31 downto 24);
  slave_STALL_O <= '0';

  slave_dat_o <= initializing & std_logic_vector(resize(xferlen_count, slave_dat_o'length-1));
  wishbone_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      start_xfer  <= '0';
      slave_ack_o <= '0';

      --write
      if (slave_stb_i and slave_cyc_i) = '1' then
        if slave_adr_i = REG_RADDRESS then
          if slave_we_i = '1'then
            raddress_register <= slave_dat_i(raddress_register'range);
          end if;
        elsif slave_adr_i = REG_WADDRESS then
          if slave_we_i = '1'then
            waddress_register <= slave_dat_i;
          end if;
        elsif slave_adr_i = REG_LENGTH then
          if slave_we_i = '1'then
            --force to multiple of 4
            length_register <= slave_dat_i(length_register'left downto 2)&"00";
            start_xfer      <= '1';
          end if;
        elsif slave_adr_i = REG_STATUS then
        end if;
        slave_ack_o <= '1';
      end if;
    end if;
  end process;

end architecture rtl;
