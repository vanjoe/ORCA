library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
--use work.top_component_pkg.all;
--use work.top_util_pkg.all;


entity wb_cam is
  port (

    clk_i : in std_logic;
    rst_i : in std_logic;

    master_ADR_O   : out std_logic_vector(32-1 downto 0);
    master_DAT_O   : out std_logic_vector(32-1 downto 0);
    master_WE_O    : out std_logic;
    master_SEL_O   : out std_logic_vector(32/8 -1 downto 0);
    master_STB_O   : out std_logic;
    master_CYC_O   : out std_logic;
    master_CTI_O   : out std_logic_vector(2 downto 0);
    master_STALL_I : in  std_logic;

    --pio control signals
    cam_start : in  std_logic;
    cam_done  : out std_logic;

    --camera signals
    ovm_pclk  : in std_logic;
    ovm_vsync : in std_logic;
    ovm_href  : in std_logic;
    ovm_dat   : in std_logic_vector(7 downto 0);

    cam_aux_out : out std_logic_vector(7 downto 0)
    );
end entity wb_cam;

architecture rtl of wb_cam is


  constant CAM_NUM_COLS : integer := 640;
  constant CAM_NUM_ROWS : integer := 480;


  type row_buf_t is array (0 to 63) of std_logic_vector(29 downto 0);
  type pixel_state_t is (PIXEL_FIRST, PIXEL_SECOND);
  type ovm_state_t is (OVM_DONE, OVM_PREGAP, OVM_GAP, OVM_ROW, OVM_FLUSH);

  signal ovm_dat_ff: std_logic_vector(7 downto 0);

  signal ovm_state   : ovm_state_t;
  signal pixel_state : pixel_state_t;

  signal row_buf : row_buf_t;

  signal ovm_pixel_rgb   : std_logic_vector(15 downto 0);
  signal ovm_pixel_valid : std_logic;

  signal ovm_col_count  : integer range 0 to 640;
  signal ovm_col_vector : std_logic_vector(9 downto 0);

  signal h_tile_start : std_logic;
  signal h_load_pixel : std_logic;
  signal v_load_pixel : std_logic;
  signal h_tile_idx   : std_logic_vector(5 downto 0);
  signal h_tile_sidx  : std_logic_vector(3 downto 0);

  signal h_red_in        : unsigned(9 downto 0);
  signal h_grn_in        : unsigned(9 downto 0);
  signal h_blu_in        : unsigned(9 downto 0);
  signal h_red_mux       : unsigned(9 downto 0);
  signal h_grn_mux       : unsigned(9 downto 0);
  signal h_blu_mux       : unsigned(9 downto 0);
  signal h_red_out       : unsigned(9 downto 0);
  signal h_grn_out       : unsigned(9 downto 0);
  signal h_blu_out       : unsigned(9 downto 0);
  signal h_rgb_out_valid : std_logic;
  signal v_rgb_out_valid : std_logic;

  signal h_accum_red   : unsigned(9 downto 0);
  signal h_accum_grn   : unsigned(9 downto 0);
  signal h_accum_blu   : unsigned(9 downto 0);
  signal h_rgb_out_idx : std_logic_vector(5 downto 0);



  signal ovm_row_count  : integer range 0 to CAM_NUM_ROWS;
  signal ovm_row_vector : std_logic_vector(8 downto 0);

  signal v_tile_start  : std_logic;
  signal v_load_row    : std_logic;
  signal v_tile_idx    : std_logic_vector(4 downto 0);
  signal v_tile_sidx   : std_logic_vector(3 downto 0);
  signal v_rowbuf_row     :  std_logic_vector(4 downto 0);
  signal v_rowbuf_row_ff  : std_logic_vector(4 downto 0);
  signal v_rgb_out_col : std_logic_vector(5 downto 0);
  signal v_rgb_out_row : std_logic_vector(4 downto 0);

  signal v_red_mux : unsigned(9 downto 0);
  signal v_grn_mux : unsigned(9 downto 0);
  signal v_blu_mux : unsigned(9 downto 0);
  signal v_rgb_ff  : std_logic_vector(31 downto 0);
  signal v_rgb_out : std_logic_vector(31 downto 0);

  signal v_address  : std_logic_vector(5 downto 0);
  signal v_wdata_we : std_logic;
  signal v_wdata    : std_logic_vector(29 downto 0);
  signal v_rdata    : std_logic_vector(29 downto 0);

  -- clock-domain crossing start/done bits
  signal cam_start_ff   : std_logic;
  signal cam_start_sync : std_logic;
  signal cam_done_ff    : std_logic;

  -- clock-domain crossing wishbone fsm

  signal extra_href : std_logic;

  signal ff1, ff0, ff0_pclk : std_logic;


begin  -- architecture rtl

  -- CAMERA START synchronizer
  cam_start_process : process(ovm_pclk)
  begin
    if rising_edge(ovm_pclk) then
      cam_start_ff   <= cam_start;      -- two-FF synchronizer
      cam_start_sync <= cam_start_ff and ovm_vsync;
    end if;
  end process;

  -- CAMERA DONE synchronizer
  cam_done_process : process(clk_i)
  begin
    if rising_edge(clk_i) then
      cam_done <= cam_done_ff;
      if ovm_state = OVM_DONE then
        cam_done_ff <= '1';
      else
        cam_done_ff <= '0';
      end if;
    end if;
  end process;





  -- PIXEL_FSM: Camera column-wise FSM
  -- purpose: (1) read every two bytes, assembling 16b into ovm_pixel_rgb()
  --          (2) assert ovm_pixel_valid when ovm_pixel_rgb() is valid
  --          (3) count pixel columns
  --          (4) count subpixel and pixel index (column position)
  --          (5) assert h_tile_start during PIXEL SECOND when col%16 == 0
  --
  -- inputs:  ovm_href, extra_href
  -- outputs: ovm_pixel_rgb(), ovm_pixel_valid, ovm_col_count,
  --          h_tile_start, h_tile_sidx(), s_tile_idx()

  ovm_col_vector <= std_logic_vector(to_unsigned(ovm_col_count, 10));
  h_tile_sidx    <= ovm_col_vector(3 downto 0);  -- LSB 4 bits (0..15)
  h_tile_idx     <= ovm_col_vector(9 downto 4);  -- MSB 6 bits (0..63)

  pixel_fsm : process(ovm_pclk)
  begin
    if falling_edge(ovm_pclk) then
      ovm_dat_ff <= ovm_dat;
    end if;
    if rising_edge(ovm_pclk) then

      h_tile_start <= '0';
      h_load_pixel <= h_tile_start;  -- asserted during FIRST half-pixel of col after (col%16)==0
      v_load_pixel <= h_tile_start and v_tile_start;  -- asserted during FIRST half-pixel of col after (col%16)==0

      ovm_pixel_valid <= '0';

      if (ovm_href = '1' or extra_href = '1') and ovm_state /= ovm_done then

        if pixel_state = PIXEL_FIRST then
          pixel_state                <= PIXEL_SECOND;
          ovm_pixel_rgb(15 downto 8) <= ovm_dat;
          -- assert 'tile start' only during SECOND half-pixel
          if h_tile_sidx = "0000" then
            h_tile_start <= '1';
          end if;

        elsif pixel_state = PIXEL_SECOND then
          pixel_state               <= PIXEL_FIRST;
          ovm_pixel_rgb(7 downto 0) <= ovm_dat;
          ovm_col_count             <= ovm_col_count + 1;
          ovm_pixel_valid           <= '1';  -- valid signal comes next FIRST half-pixel
        end if;
      else
        pixel_state   <= PIXEL_FIRST;
        ovm_col_count <= 0;
      end if;

      --if rst_i = '1' then
      --  pixel_state   <= PIXEL_FIRST;
      --  ovm_col_count <= 0;
      --end if;
    end if;
  end process;

  -- HORIZONTAL RGB ACCUMULATOR

  -- combinational logic: input bit width extension
  h_red_in <= resize(unsigned(ovm_pixel_rgb(15 downto 11)&"0"), h_red_in'length);  --  5 bits
  h_grn_in <= resize(unsigned(ovm_pixel_rgb(10 downto  5)    ), h_grn_in'length);  --  6 bits
  h_blu_in <= resize(unsigned(ovm_pixel_rgb( 4 downto  0)&"0"), h_blu_in'length);  --  5 bits

  -- combinational logic: mux to initialize accumulator
  h_pixel_mux : process(h_load_pixel, h_accum_red, h_accum_grn, h_accum_blu)
  begin
    if h_load_pixel = '1' then
      h_red_mux <= "0000000000";
      h_grn_mux <= "0000000000";
      h_blu_mux <= "0000000000";
    else
      h_red_mux <= h_accum_red;
      h_grn_mux <= h_accum_grn;
      h_blu_mux <= h_accum_blu;
    end if;
  end process;

  -- simple accumulator to add 16 pixels of rgb data
  h_accum : process(ovm_pclk)
  begin
    if rising_edge(ovm_pclk) then
      if ovm_pixel_valid = '1' then  -- asserted during FIRST half-pixel after sidx0
        h_accum_red <= h_red_in + h_red_mux;
        h_accum_grn <= h_grn_in + h_grn_mux;
        h_accum_blu <= h_blu_in + h_blu_mux;
      end if;
      if h_load_pixel = '1' then
        h_rgb_out_idx <= h_tile_idx;
      end if;
      --if rst_i = '1' then
      --  h_accum_red   <= (others => '0');
      --  h_accum_grn   <= (others => '0');
      --  h_accum_blu   <= (others => '0');
      --  h_rgb_out_idx <= (others => '0');
      --end if;
    end if;
  end process;

  -- combinational logic: output width truncation and resizing
  h_red_out       <= "0000" & h_accum_red(9 downto 4);  --  truncated to 6 bits
  h_grn_out       <= "0000" & h_accum_grn(9 downto 4);  --  truncated to 6 bits
  h_blu_out       <= "0000" & h_accum_blu(9 downto 4);  --  truncated to 6 bits
  h_rgb_out_valid <= h_load_pixel;  -- when loading new pixel, read out old tile average


  -- OVM_FSM Camera Row-wise FSM
  -- purpose: (1) count rows
  --          (2) produce extra_href after 480 ovm_hrefs received
  -- inputs: cam_start_sync, ovm_href, ovm_col_count
  -- outputs: extra_href, v_load_row, ovm_row_count

  ovm_row_vector <= std_logic_vector(to_unsigned(ovm_row_count, 9));
  v_tile_idx     <= ovm_row_vector(8 downto 4);    -- MSB 5 bits (0..31)
  v_tile_sidx    <= ovm_row_vector(3 downto 0);    -- LSB 4 bits (0..15)
  v_tile_start   <= '1' when v_tile_sidx = "0000"  -- this can be slow logic
                    else '0';

  ovm_fsm : process(ovm_pclk)
  begin
    if rising_edge(ovm_pclk) then

      extra_href <= '0';
      v_load_row <= '0';
      v_rowbuf_row     <= v_rowbuf_row_ff;
      case ovm_state is

        when OVM_DONE =>
          -- row0 is written twice (first: dummy values, then: valid values)
          v_rowbuf_row_ff  <= (others => '0');
          ovm_row_count <= 0;
          if cam_start_sync = '1' then
            ovm_state <= OVM_PREGAP;
          end if;

        when OVM_PREGAP =>
          ovm_state <= OVM_GAP;
          if ovm_row_count = CAM_NUM_ROWS then
            ovm_state <= OVM_FLUSH;
          end if;

        when OVM_GAP =>
          if ovm_href = '1' then
            ovm_state <= OVM_ROW;
          end if;

        when OVM_ROW =>
          v_load_row <= v_tile_start;
          if ovm_href = '0' then
            v_rowbuf_row_ff  <= v_tile_idx;  -- update row# that we just accumulated
            ovm_row_count <= ovm_row_count + 1;  -- data is rows 0 to 479
            ovm_state     <= OVM_PREGAP;
          end if;

        when OVM_FLUSH =>
        -- one extra row of pixels to flush the last set of averaged rows
          extra_href <= '1';
          v_load_row <= '1';
          if ovm_col_count = CAM_NUM_COLS then
            ovm_state <= OVM_DONE;
          end if;

      end case;

      if rst_i = '1' then
        ovm_state    <= OVM_DONE;
        v_rowbuf_row_ff <= (others => '0');  -- update row# that we just accumulated
      end if;
    end if;

  end process;


  -- VERTICAL RGB ROW-WISE ACCUMULATOR

  -- combinational logic: initialization mux
  v_pixel_mux : process(v_load_row, v_rdata)
  begin
    if v_load_row = '1' then
      v_red_mux <= "0000000000";        -- zero to produce RGB image
      v_grn_mux <= "0000000000";
      v_blu_mux <= "0000000000";
      --v_red_mux <= "1000000000"; -- preload with neg bias for NN
      --v_grn_mux <= "1000000000";
      --v_blu_mux <= "1000000000";
    else
      v_red_mux <= unsigned(v_rdata(29 downto 20));
      v_grn_mux <= unsigned(v_rdata(19 downto 10));
      v_blu_mux <= unsigned(v_rdata( 9 downto  0));
    end if;
  end process;

                                        -- combinational logic: row buffer address & data generation
  v_wdata(29 downto 20) <= std_logic_vector(h_red_out + v_red_mux);
  v_wdata(19 downto 10) <= std_logic_vector(h_grn_out + v_grn_mux);
  v_wdata(9 downto 0)   <= std_logic_vector(h_blu_out + v_blu_mux);
  -- FIXME: due to simple logic of v_wdata_we, the last (40th) pixel column won't be written.
  -- we don't use that pixel column, and this keeps logic simpler
  v_wdata_we            <= h_rgb_out_valid;
  v_address             <= h_rgb_out_idx;

  -- row buffer itself (inferred 30b wide RAM)
  row_buffer : process(ovm_pclk)
  begin
    if rising_edge(ovm_pclk) then
      v_rdata <= row_buf(to_integer(unsigned(v_address)));
      if v_wdata_we = '1' then
        row_buf(to_integer(unsigned(v_address))) <= v_wdata;
      end if;
    end if;
  end process;

  v_rgb_ff(31 downto 16) <= (others=>'0');

  output_latch_cam : process(ovm_pclk)
  begin
    if rising_edge(ovm_pclk) then
      ff0_pclk <= ff0;

      v_rgb_ff(15 downto 0) <= ovm_pixel_rgb;

      if v_load_pixel = '1' then
        v_rgb_out_valid <= '1';
      elsif ff0_pclk = '1' then
        v_rgb_out_valid <= '0';
      end if;
      --v_rgb_out_valid <= v_load_pixel AND (NOT ff0_pclk);

      if v_load_pixel = '1' then
        v_rgb_out_row           <= v_rowbuf_row;           -- 5 bits (0..31)
        v_rgb_out_col           <= v_address;              -- 6 bits (0..63)
	v_rgb_out(31 downto 24) <= (others => '0');
        v_rgb_out(23 downto 16) <= v_rdata(29 downto 22);  -- extract red 8 MSB
        v_rgb_out(15 downto  8) <= v_rdata(19 downto 12);  -- extract grn 8 MSB
        v_rgb_out( 7 downto  0) <= v_rdata( 9 downto  2);  -- extract blu 8 MSB
        --v_rgb_out <= v_rgb_ff; -- UNCOMMENT THIS LINE TO DO RGB565 SUBSAMPLING INSTEAD OF AVERAGING
      end if;
      --if rst_i = '1' then
      --  v_rgb_out_valid <= '0';
      --end if;
    end if;
  end process;


  cam_aux_out(0) <= v_load_pixel;
  cam_aux_out(1) <= h_load_pixel;
  cam_aux_out(2) <= ovm_pclk;
  cam_aux_out(3) <= ovm_pixel_valid;
  cam_aux_out(4) <= v_load_row;
  cam_aux_out(5) <= extra_href;
  cam_aux_out(6) <= ff0;
  cam_aux_out(7) <= v_rgb_out_valid;


  output_latch_lve : process(clk_i)
  begin
    if rising_edge(clk_i) then
      -- synchronizer
      ff1 <= ff0;
      ff0 <= v_rgb_out_valid;

      master_STB_O <= ff1;
      master_CYC_O <= ff1;
      master_WE_O  <= ff1;
      if ff1 = '1' then
        master_dat_O <= v_rgb_out;
        master_ADR_O(12 downto 0) <= v_rgb_out_row & v_rgb_out_col & "00";
      end if;

    end if;
  end process;
  master_ADR_O(master_ADR_O'left downto 13) <= (others => '0');
  master_SEL_O <= (others => '1');

end architecture rtl;
