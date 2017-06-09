
/* Based on code sent by Omnivision with the following header:
 *
 * ;OmniVision Technologies Inc.
 * ;Sensor Setting Release Log
 * ;=============================================================
 * ;
 * ;Sensor 		: OV7692
 * ;Sensor Rev	: Rev1a
 * ;
 * ;01/09/2009	R1.4
 * ;			Reg0x4c=0x7d
 *
 */


#define AUTO_WHITE_BALANCE 1
#define IN_SENSOR_SCALE 4

static const regval_t regval_list[] = {

// pairs of values below are <reg, value>
// value in comments in (parentheses) are camera defaults listed in datasheet
// actual camera defaults may be different than values listed below

 {0x12, 0x80}, // enable RESET
 {0x0e, 0x08}, // enable SLEEP

 {0x69, 0x52}, // (0x12) BLC9 b6:3=blc_window_selection, b2=bypass_blc, b1:0=blc_enable

 {0x1e, 0xb3}, // (0xb1) b7=reserved, b6=CLK_CHG, b5=ph1_arr_en, b4=BdcAEC, b3:2=reserved, b1=AddLT1F, b0=EXPNG

 {0x48, 0x42}, // (----) reserved

 {0xff, 0x01}, // enable MIPI registers
 {0xb5, 0x30}, // (0x70) R_MIPI0 b76=pgm_lptx (drive strength), b5=power down MIPI, b4=power down MIPI lp xmit
 {0xff, 0x00}, // disable MIPI registers

 {0x16, 0x03}, // (0x03) b21=reserved
 {0x62, 0x10}, // (0x10) (BLC/AGC) b4=reserved
 {0x12, 0x00}, // disable RESET

 {0x12, 0x06}, // enable RGB565 mode

 {0x17, 0x65}, // (0x69) HSTART
 {0x18, 0xa4}, // (0xa4) HSIZE/2 (& LSB from 0x16[6])
 {0x19, 0x0a}, // (0x0c) VSTART
 {0x1a, 0xf6}, // (0xf6) VSIZE/2

 {0x3e, 0x20}, // (0x30) b5=get_1/2_or_1/4_pclk, b4=mipi_clock_selection_rgb

 {0x64, 0x11}, // (0x11) VFIFO0: b73=ratio_of_sclk_to_pclk, b10=reserved (001=2*SCLK,010=SCLK,100=SCLK/2)
 {0x67, 0x20}, // (0x20) VFIFO3: b7654=reserved, b3210=offset_on_start_size

 {0x81, 0x3f}, // (0x3f) b76=reserved, b5=sde_en, b4=uv_adj_en, b3=scale_v_en, b2=scale_h_en, b1=uv_avg_en, b0=cmx_en

 {0xcc, (640/IN_SENSOR_SCALE)>>8}, // (0x02) b1:0=oh[9:8] MSB of horiz output size \ 40 pixels output size
 {0xcd, (640/IN_SENSOR_SCALE)&0xFF}, // (0x80) b7:0=oh[7:0] LSB of horiz output size /
 {0xce, (480/IN_SENSOR_SCALE)>>8}, // (0x01)   b0=ov[8]   MSB of vert output size  \ 30 pixels output size
 {0xcf, (480/IN_SENSOR_SCALE)&0xFF}, // (0xe0) b7:0=ov[7:0] LSB of vert output size  /

 // INPUT SIZE FOR SCALING
 {0xc8, 0x02}, // (0x02) b1:0=ih[9:8] MSB of horiz input size \ 640 pixels input size
 {0xc9, 0x80}, // (0x80) b7:0=ih[7:0] LSB of horiz input size /
 {0xca, 0x01}, // (0x01)   b0=iv[8]   MSB of vert input size \ 480 pixels input size
 {0xcb, 0xe0}, // (0xe0) b1:0=iv[7:0] LSB of vert input size /

 {0xd0, 0x48}, // (0x48) boundary_offset <win_hoff3:0,win_voff7:4>

 {0x82, 0x03}, // (0x03) b1:0=ISP_out_sel_YUV422
 {0x0e, 0x00}, // disable SLEEP

#if 1
 {0x70, 0x00}, // (0x00) 5060_0 50/60, low_light, etc
 {0x71, 0x34}, // (0x00) 5060_1 b5=calc_sum_auto, b4=band_counter_ena, b3210=band_counter
 {0x74, 0x28}, // (0x20) 5060_4 threshold for low sum value
 {0x75, 0x98}, // (0x70) 5060_5 threshold for high sum value
 {0x76, 0x00}, // (0x00) 5060_6 low threshold of light meter[15:8]
 {0x77, 0x64}, // (0x00) 5060_7 low threshold of light meter[7:0]
 {0x78, 0x01}, // (0x01) 5060_8 high threshold of light meter[15:8]
 {0x79, 0xc2}, // (0x2c) 5060_9 high threshold of light meter[7:0]
 {0x7a, 0x4e}, // (0x4e) 5060_a clock_period_for_sample_num[15:8]
 {0x7b, 0x1f}, // (0x1f) 5060_b clock_period_for_sample_num[7:0]
 {0x7c, 0x00}, // (0x00) 5060_c indirect_register_address

 {0x11, 0x01}, // (0x00) DPLL b5:0=internal_pre-scaler_amount
 {0x20, 0x00}, // (0x00) banding MSBs=0, extra banding info
 {0x21, 0x57}, // (0x00) b7:4=banding_filt_max_step_for_50Hz, b3:0=banding_filt_max_step_for_60Hz

 {0x50, 0x4d}, // (0x9a) BD50ST 50Hz_banding_aec_8b
 {0x51, 0x40}, // (0x80) BD60ST 60Hz_banding_aec_8b
#endif

 {0x4c, 0x7d}, // (----) reserved
 {0x0e, 0x00}, // disable SLEEP

#if 1
 {0x80, 0x7f}, // (0x7e) b6=cip_en, b5=bc_en, b4=wc_en, b3=gamma_en, b2=awb_gain_en, b1=awb_en, b0=lenc_en
 {0x85, 0x00}, // (0x10) b4=LENC_bias_enable
 {0x86, 0x00}, // (0x20) lc_radius
 {0x87, 0x00}, // (0x20) lc_xoffset
 {0x88, 0x00}, // (0x10) lc_yoffset
 {0x89, 0x2a}, // (0x80) lc_rgain
 {0x8a, 0x22}, // (0x80) lc_ggain
 {0x8b, 0x20}, // (0x80) lc_bgain

 {0xbb, 0xab}, // (0x63) m1
 {0xbc, 0x84}, // (0x45) m2
 {0xbd, 0x27}, // (0x20) m3
 {0xbe, 0x0e}, // (0x1f) m4
 {0xbf, 0xb8}, // (0x1e) m5
 {0xc0, 0xc5}, // (0x84) m6
 {0xc1, 0x1e}, // (0x13) b7=cmx_bias, b6=m_db, m5:0=m_sign

 {0xb7, 0x05}, // (0x10) offset
 {0xb8, 0x09}, // (0x0c) b7:5=base1, b4:0=base1
 {0xb9, 0x00}, // (0x02) b7:5=base2, b4:0=base2
 {0xba, 0x18}, // (0x09) b54=gain_sel_00=8:>01=16<:10=32:11=64, b32=dns_th_sel, b10=edge_mt_range

 {0x5a, 0x1f}, // (0x01) slope_of_uv_curve
 {0x5b, 0x9f}, // (0xff) b7:6=uv_adj_gain_high_thresh_ctrl_2LSBs, b5:0=y_intercept_point_of_uv_curve
 {0x5c, 0x69}, // (0x1f) b7:5=uv_adj_gain_high_thresh_ctrl_3MSBs, b4:0=reserved
//0x5d, 0x62 SONY
 {0x5d, 0x42}, // (0x00) b7:4=uv_adj_gain_low_thresh_ctrl, b3=awb_bias_set_by_reg_e5, b2=reserved, b1=choose_1/4_avg_Value, b0=reserved

 {0x24, 0x78}, // (0x78) WPT agc/aec stable operating region (upper limit)
 {0x25, 0x68}, // (0x68) BPT agc/aec stable operating region (lower limit)
 {0x26, 0xb3}, // (0xd4) VPT agc/aec fast mode operating region b7:4=upper_limit, b3:0=lower_limit
#endif

#if 1
 {0xa3, 0x0b}, // (0x10) YST1
 {0xa4, 0x15}, // (0x12) YST2
 {0xa5, 0x29}, // (0x35) YST3
 {0xa6, 0x4a}, // (0x5a) YST4
 {0xa7, 0x58}, // (0x69) YST5
 {0xa8, 0x65}, // (0x76) YST6
 {0xa9, 0x70}, // (0x80) YST7
 {0xaa, 0x7b}, // (0x88) YST8
 {0xab, 0x85}, // (0x8f) YST9
 {0xac, 0x8e}, // (0x96) YST10
 {0xad, 0xa0}, // (0xa3) YST11
 {0xae, 0xb0}, // (0xaf) YST12
 {0xaf, 0xcb}, // (0xc4) YST13
 {0xb0, 0xe1}, // (0xd7) YST14
 {0xb1, 0xf1}, // (0xe8) YST15
 {0xb2, 0x14}, // (0x18) YSLP15
#endif

#if 1
 {0x8e, 0x92}, // (0x12) 1001.0010, b7=*awb_simple, b654=stable_range, b3=awb_bias_stat, b210=local_limit
 {0x96, 0xff}, // (0xf0) b[]=value_top_limit
 {0x97, 0x00}, // (0x10) b[]=value_bot_limit
 {0x14, 0x3b}, // (0x12) 0011.1011, b654=maxAGC_of_16x, b3=reserved, b1=manual_50/60_mode, b0=50Hz
#endif

 ////////////////////////////
 // VectorBlox code
 ////////////////////////////

 //{0x14, 0x3a},  // 60Hz
 {0x5e, 0x00},   // restore divided PCLK
 {0x0c, 0x96},   //              vertical mirror  9=8+1
 {0x0c, 0xd6},   // horizontal & vertical mirror  d=8+4+1=13
#if 0
// test pattern
// {0x61, 0x60}, // 8b pattern
// {0x61, 0x70}, // 8b pattern (model 2)
 {0x61, 0x00}, // default
#endif

// PCLK DIVIDER: METHOD 1
// {0x30, 0x07},   // PCLK divide by 3
// {0x30, 0x06},   // PCLK divide by 2
// {0x30, 0x04},   // PCLK divide by 1 (default)

// PCLK DIVIDER: METHOD 2, recomnmended by Omnivision, used by Sony N ∈ [0,31]
// {0x11, 0x00},   // PCLK divider, data=N=0, divide by (N+1)=1
// {0x11, 0x02},   // PCLK divider, data=N=1, divide by (N+1)=3
// {0x11, 0x01},   // PCLK divider, data=N=1, divide by (N+1)=2
 {0x11, 0x07},   // PCLK divider, data=N=1, divide by (N+1)=8


 ////////////////////////////
 // Finish up Omnivision code
 ////////////////////////////

 {0x0e, 0x00}, // (0x00) disable SLEEP

};
