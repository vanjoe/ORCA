// ********************************************************************
//  Microsemi Corporation Proprietary and Confidential
//  Copyright 2017 Microsemi Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE MICROSEMI LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description: This file states the parameters needed to change the
//              behaviour of the core during testing.
//
// Revision Information:
// Date     Description:
// Feb17    Revision 1.0
//
// Notes:
// best viewed with tabstops set to "4"
// ********************************************************************

  //=====================================================================
  // Global parameters
  //=====================================================================

  parameter integer FAMILY           = 19;
    
  parameter integer NUM_MASTERS      = 4;        // defines number of master ports 
  parameter integer NUM_SLAVES       = 4;        // defines number of slaves

  parameter integer ID_WIDTH         = 3;        // number of bits for ID (ie AID, WID, BID) - valid 1-8 
  parameter integer ADDR_WIDTH       = 32;        // valid values - 16 - 64


  //====================================================================
  // Crossbar parameters
  //====================================================================
  parameter integer DATA_WIDTH       = 64;        // valid widths - 32, 64, 128

  parameter NUM_THREADS           = 4;        // defined number of indpendent threads per master supported - valid range 1-8
  parameter OPEN_TRANS_MAX        = 2;        // max number of outstanding transactions per thread - valid range 1-8

  parameter OPEN_WRTRANS_MAX        = OPEN_TRANS_MAX*2;    // max number of outstanding write transactions - valid range 2-8 - 2**OPEN_WRTRANS_MAX
  parameter OPEN_RDTRANS_MAX        = OPEN_TRANS_MAX*2;    // max number of outstanding read transactions - valid range  2-8 - 2**OPEN_RDTRANS_MAX


  `define DECWIDTH  4           // Defines width of address decode for each slave slot
                                // Allow space for undefined memory spaces - to allow for testing
                                // decode errors.

  parameter UPPER_COMPARE_BIT     = ADDR_WIDTH- `DECWIDTH;      // Defines the upper bit of range to compare
  parameter LOWER_COMPARE_BIT     = UPPER_COMPARE_BIT - 4;      // Defines lower bound of compare - bits below are dont care

  parameter [63:0]  SLOT0_BASE_VEC  = 'h0;          // Defines the base address for Slave 0 decode
  parameter [63:0]  SLOT1_BASE_VEC  = 'h1;          // Defines the base address for Slave 1 decode
  parameter [63:0]  SLOT2_BASE_VEC  = 'h2;          // Defines the base address for Slave 2 decode
  parameter [63:0]  SLOT3_BASE_VEC  = 'h3;          // Defines the base address for Slave 3 decode
  parameter [63:0]  SLOT4_BASE_VEC  = 'h4;          // Defines the base address for Slave 4 decode
  parameter [63:0]  SLOT5_BASE_VEC  = 'h5;          // Defines the base address for Slave 5 decode
  parameter [63:0]  SLOT6_BASE_VEC  = 'h6;          // Defines the base address for Slave 6 decode
  parameter [63:0]  SLOT7_BASE_VEC  = 'h7;          // Defines the base address for Slave 7 decode
  parameter [63:0]  SLOT8_BASE_VEC  = 'h8;          // Defines the base address for Slave 8 decode
  parameter [63:0]  SLOT9_BASE_VEC  = 'h9;          // Defines the base address for Slave 9 decode
  parameter [63:0]  SLOT10_BASE_VEC = 'ha;          // Defines the base address for Slave 10 decode
  parameter [63:0]  SLOT11_BASE_VEC = 'hb;          // Defines the base address for Slave 11 decode
  parameter [63:0]  SLOT12_BASE_VEC = 'hc;          // Defines the base address for Slave 12 decode
  parameter [63:0]  SLOT13_BASE_VEC = 'hd;          // Defines the base address for Slave 13 decode
  parameter [63:0]  SLOT14_BASE_VEC = 'he;          // Defines the base address for Slave 14 decode
  parameter [63:0]  SLOT15_BASE_VEC = 'hf;          // Defines the base address for Slave 15 decode
  parameter [63:0]  SLOT16_BASE_VEC = 'h10;          // Defines the base address for Slave 16 decode
  parameter [63:0]  SLOT17_BASE_VEC = 'h11;          // Defines the base address for Slave 17 decode
  parameter [63:0]  SLOT18_BASE_VEC = 'h12;          // Defines the base address for Slave 18 decode
  parameter [63:0]  SLOT19_BASE_VEC = 'h13;          // Defines the base address for Slave 19 decode
  parameter [63:0]  SLOT20_BASE_VEC = 'h14;          // Defines the base address for Slave 20 decode
  parameter [63:0]  SLOT21_BASE_VEC = 'h15;          // Defines the base address for Slave 21 decode
  parameter [63:0]  SLOT22_BASE_VEC = 'h16;          // Defines the base address for Slave 22 decode
  parameter [63:0]  SLOT23_BASE_VEC = 'h17;          // Defines the base address for Slave 23 decode
  parameter [63:0]  SLOT24_BASE_VEC = 'h18;          // Defines the base address for Slave 24 decode
  parameter [63:0]  SLOT25_BASE_VEC = 'h19;          // Defines the base address for Slave 25 decode
  parameter [63:0]  SLOT26_BASE_VEC = 'h1a;          // Defines the base address for Slave 26 decode
  parameter [63:0]  SLOT27_BASE_VEC = 'h1b;          // Defines the base address for Slave 27 decode
  parameter [63:0]  SLOT28_BASE_VEC = 'h1c;          // Defines the base address for Slave 28 decode
  parameter [63:0]  SLOT29_BASE_VEC = 'h1d;          // Defines the base address for Slave 29 decode
  parameter [63:0]  SLOT30_BASE_VEC = 'h1e;          // Defines the base address for Slave 30 decode
  parameter [63:0]  SLOT31_BASE_VEC = 'h1f;          // Defines the base address for Slave 31 decode

  parameter [63:0]  SLOT0_MIN_VEC  = 'h0;          // Defines the Min address for Slave 0 decode
  parameter [63:0]  SLOT1_MIN_VEC  = 'h0;          // Defines the Min address for Slave 1 decode
  parameter [63:0]  SLOT2_MIN_VEC  = 'h0;          // Defines the Min address for Slave 2 decode
  parameter [63:0]  SLOT3_MIN_VEC  = 'h0;          // Defines the Min address for Slave 3 decode
  parameter [63:0]  SLOT4_MIN_VEC  = 'h0;          // Defines the Min address for Slave 4 decode
  parameter [63:0]  SLOT5_MIN_VEC  = 'h0;          // Defines the Min address for Slave 5 decode
  parameter [63:0]  SLOT6_MIN_VEC  = 'h0;          // Defines the Min address for Slave 6 decode
  parameter [63:0]  SLOT7_MIN_VEC  = 'h0;          // Defines the Min address for Slave 7 decode
  parameter [63:0]  SLOT8_MIN_VEC  = 'h0;          // Defines the Min address for Slave 8 decode
  parameter [63:0]  SLOT9_MIN_VEC  = 'h0;          // Defines the Min address for Slave 9 decode
  parameter [63:0]  SLOT10_MIN_VEC = 'h0;          // Defines the Min address for Slave 10 decode
  parameter [63:0]  SLOT11_MIN_VEC = 'h0;          // Defines the Min address for Slave 11 decode
  parameter [63:0]  SLOT12_MIN_VEC = 'h0;          // Defines the Min address for Slave 12 decode
  parameter [63:0]  SLOT13_MIN_VEC = 'h0;          // Defines the Min address for Slave 13 decode
  parameter [63:0]  SLOT14_MIN_VEC = 'h0;          // Defines the Min address for Slave 14 decode
  parameter [63:0]  SLOT15_MIN_VEC = 'h0;          // Defines the Min address for Slave 15 decode
  parameter [63:0]  SLOT16_MIN_VEC = 'h0;          // Defines the Min address for Slave 16 decode
  parameter [63:0]  SLOT17_MIN_VEC = 'h0;          // Defines the Min address for Slave 17 decode
  parameter [63:0]  SLOT18_MIN_VEC = 'h0;          // Defines the Min address for Slave 18 decode
  parameter [63:0]  SLOT19_MIN_VEC = 'h0;          // Defines the Min address for Slave 19 decode
  parameter [63:0]  SLOT20_MIN_VEC = 'h0;          // Defines the Min address for Slave 20 decode
  parameter [63:0]  SLOT21_MIN_VEC = 'h0;          // Defines the Min address for Slave 21 decode
  parameter [63:0]  SLOT22_MIN_VEC = 'h0;          // Defines the Min address for Slave 22 decode
  parameter [63:0]  SLOT23_MIN_VEC = 'h0;          // Defines the Min address for Slave 23 decode
  parameter [63:0]  SLOT24_MIN_VEC = 'h0;          // Defines the Min address for Slave 24 decode
  parameter [63:0]  SLOT25_MIN_VEC = 'h0;          // Defines the Min address for Slave 25 decode
  parameter [63:0]  SLOT26_MIN_VEC = 'h0;          // Defines the Min address for Slave 26 decode
  parameter [63:0]  SLOT27_MIN_VEC = 'h0;          // Defines the Min address for Slave 27 decode
  parameter [63:0]  SLOT28_MIN_VEC = 'h0;          // Defines the Min address for Slave 28 decode
  parameter [63:0]  SLOT29_MIN_VEC = 'h0;          // Defines the Min address for Slave 29 decode
  parameter [63:0]  SLOT30_MIN_VEC = 'h0;          // Defines the Min address for Slave 30 decode
  parameter [63:0]  SLOT31_MIN_VEC = 'h0;          // Defines the Min address for Slave 31 decode

  parameter [63:0]  SLOT0_MAX_VEC  = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT0 Max address
  parameter [63:0]  SLOT1_MAX_VEC  = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT1 Max address
  parameter [63:0]  SLOT2_MAX_VEC  = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT2 Max address
  parameter [63:0]  SLOT3_MAX_VEC  = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT3 Max address
  parameter [63:0]  SLOT4_MAX_VEC  = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT4 Max address
  parameter [63:0]  SLOT5_MAX_VEC  = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT5 Max address
  parameter [63:0]  SLOT6_MAX_VEC  = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT6 Max address
  parameter [63:0]  SLOT7_MAX_VEC  = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT7 Max address
  parameter [63:0]  SLOT8_MAX_VEC  = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT8 Max address
  parameter [63:0]  SLOT9_MAX_VEC  = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT9 Max address
  parameter [63:0]  SLOT10_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT10 Max address
  parameter [63:0]  SLOT11_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT11 Max address
  parameter [63:0]  SLOT12_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT12 Max address
  parameter [63:0]  SLOT13_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT13 Max address
  parameter [63:0]  SLOT14_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT14 Max address
  parameter [63:0]  SLOT15_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT15 Max address
  parameter [63:0]  SLOT16_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT16 Max address
  parameter [63:0]  SLOT17_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT17 Max address
  parameter [63:0]  SLOT18_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT18 Max address
  parameter [63:0]  SLOT19_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT19 Max address
  parameter [63:0]  SLOT20_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT20 Max address
  parameter [63:0]  SLOT21_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT21 Max address
  parameter [63:0]  SLOT22_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT22 Max address
  parameter [63:0]  SLOT23_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT23 Max address
  parameter [63:0]  SLOT24_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT24 Max address
  parameter [63:0]  SLOT25_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT25 Max address
  parameter [63:0]  SLOT26_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT26 Max address
  parameter [63:0]  SLOT27_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT27 Max address
  parameter [63:0]  SLOT28_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT28 Max address
  parameter [63:0]  SLOT29_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT29 Max address
  parameter [63:0]  SLOT30_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT30 Max address
  parameter [63:0]  SLOT31_MAX_VEC = 64'hFFFF_FFFF_FFFF_FFFF;      // SLOT31 Max address


  parameter integer SUPPORT_USER_SIGNALS   = 0;        // indicates where user signals upport - 0 mean no, 1 means yes
  parameter integer USER_WIDTH         = 4;        // defines the number of bits for USER signals RUSER and WUSER
  parameter integer CROSSBAR_MODE      = 1;        // defines whether non-blocking (ie set 1) or shared access data path

  parameter [0:0]    MASTER0_WRITE_SLAVE0  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE1  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE2  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE3  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE4  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE5  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE6  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE7  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE8  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE9  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE10 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE11 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE12 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE13 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE14 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE15 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE16 = 1'b1;     // bit for slave indicating if a master can write to that port  
  parameter [0:0]    MASTER0_WRITE_SLAVE17 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE18 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE19 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE20 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE21 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE22 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE23 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE24 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE25 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE26 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE27 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE28 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE29 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE30 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER0_WRITE_SLAVE31 = 1'b1;     // bit for slave indicating if a master can write to that port
            
  parameter [0:0]    MASTER1_WRITE_SLAVE0  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE1  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE2  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE3  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE4  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE5  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE6  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE7  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE8  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE9  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE10 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE11 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE12 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE13 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE14 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE15 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE16 = 1'b1;     // bit for slave indicating if a master can write to that port  
  parameter [0:0]    MASTER1_WRITE_SLAVE17 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE18 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE19 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE20 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE21 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE22 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE23 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE24 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE25 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE26 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE27 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE28 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE29 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE30 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER1_WRITE_SLAVE31 = 1'b1;     // bit for slave indicating if a master can write to that port

  parameter [0:0]    MASTER2_WRITE_SLAVE0  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE1  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE2  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE3  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE4  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE5  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE6  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE7  = 1'b1;     // bit for slave indicating if a master can write to that port  
  parameter [0:0]    MASTER2_WRITE_SLAVE8  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE9  = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE10 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE11 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE12 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE13 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE14 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE15 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE16 = 1'b1;     // bit for slave indicating if a master can write to that port  
  parameter [0:0]    MASTER2_WRITE_SLAVE17 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE18 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE19 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE20 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE21 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE22 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE23 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE24 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE25 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE26 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE27 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE28 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE29 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE30 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER2_WRITE_SLAVE31 = 1'b1;     // bit for slave indicating if a master can write to that port
            
  parameter [0:0]    MASTER3_WRITE_SLAVE0 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE1 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE2 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE3 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE4 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE5 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE6 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE7 = 1'b1;      // bit for slave indicating if a master can write to that port  
  parameter [0:0]    MASTER3_WRITE_SLAVE8 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE9 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE10 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE11 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE12 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE13 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE14 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE15 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE16 = 1'b1;     // bit for slave indicating if a master can write to that port  
  parameter [0:0]    MASTER3_WRITE_SLAVE17 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE18 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE19 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE20 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE21 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE22 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE23 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE24 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE25 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE26 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE27 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE28 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE29 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE30 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER3_WRITE_SLAVE31 = 1'b1;     // bit for slave indicating if a master can write to that port
            
  parameter [0:0]    MASTER4_WRITE_SLAVE0 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE1 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE2 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE3 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE4 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE5 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE6 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE7 = 1'b1;      // bit for slave indicating if a master can write to that port  
  parameter [0:0]    MASTER4_WRITE_SLAVE8 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE9 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE10 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE11 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE12 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE13 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE14 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE15 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE16 = 1'b1;     // bit for slave indicating if a master can write to that port  
  parameter [0:0]    MASTER4_WRITE_SLAVE17 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE18 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE19 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE20 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE21 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE22 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE23 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE24 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE25 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE26 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE27 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE28 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE29 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE30 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER4_WRITE_SLAVE31 = 1'b1;     // bit for slave indicating if a master can write to that port
            
  parameter [0:0]    MASTER5_WRITE_SLAVE0 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE1 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE2 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE3 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE4 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE5 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE6 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE7 = 1'b1;      // bit for slave indicating if a master can write to that port  
  parameter [0:0]    MASTER5_WRITE_SLAVE8 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE9 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE10 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE11 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE12 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE13 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE14 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE15 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE16 = 1'b1;     // bit for slave indicating if a master can write to that port  
  parameter [0:0]    MASTER5_WRITE_SLAVE17 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE18 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE19 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE20 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE21 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE22 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE23 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE24 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE25 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE26 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE27 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE28 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE29 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE30 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER5_WRITE_SLAVE31 = 1'b1;     // bit for slave indicating if a master can write to that port
            
  parameter [0:0]    MASTER6_WRITE_SLAVE0 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE1 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE2 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE3 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE4 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE5 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE6 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE7 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE8 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE9 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE10 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE11 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE12 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE13 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE14 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE15 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE16 = 1'b1;     // bit for slave indicating if a master can write to that port  
  parameter [0:0]    MASTER6_WRITE_SLAVE17 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE18 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE19 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE20 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE21 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE22 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE23 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE24 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE25 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE26 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE27 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE28 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE29 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE30 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER6_WRITE_SLAVE31 = 1'b1;     // bit for slave indicating if a master can write to that port
              
  parameter [0:0]    MASTER7_WRITE_SLAVE0 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE1 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE2 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE3 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE4 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE5 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE6 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE7 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE8 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE9 = 1'b1;      // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE10 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE11 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE12 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE13 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE14 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE15 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE16 = 1'b1;     // bit for slave indicating if a master can write to that port  
  parameter [0:0]    MASTER7_WRITE_SLAVE17 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE18 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE19 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE20 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE21 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE22 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE23 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE24 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE25 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE26 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE27 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE28 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE29 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE30 = 1'b1;     // bit for slave indicating if a master can write to that port
  parameter [0:0]    MASTER7_WRITE_SLAVE31 = 1'b1;     // bit for slave indicating if a master can write to that port

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////              

  parameter [0:0]    MASTER0_READ_SLAVE0 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE1 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE2 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE3 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE4 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE5 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE6 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE7 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE8 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE9 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE10 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE11 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE12 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE13 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE14 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE15 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE16 = 1'b1;     // bit for slave indicating if a master can read to that port  
  parameter [0:0]    MASTER0_READ_SLAVE17 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE18 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE19 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE20 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE21 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE22 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE23 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE24 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE25 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE26 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE27 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE28 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE29 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE30 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER0_READ_SLAVE31 = 1'b1;     // bit for slave indicating if a master can read to that port

  
  parameter [0:0]    MASTER1_READ_SLAVE0 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE1 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE2 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE3 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE4 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE5 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE6 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE7 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE8 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE9 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE10 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE11 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE12 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE13 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE14 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE15 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE16 = 1'b1;     // bit for slave indicating if a master can read to that port  
  parameter [0:0]    MASTER1_READ_SLAVE17 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE18 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE19 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE20 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE21 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE22 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE23 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE24 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE25 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE26 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE27 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE28 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE29 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE30 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER1_READ_SLAVE31 = 1'b1;     // bit for slave indicating if a master can read to that port

  
  parameter [0:0]    MASTER2_READ_SLAVE0 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE1 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE2 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE3 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE4 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE5 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE6 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE7 = 1'b1;      // bit for slave indicating if a master can read to that port  
  parameter [0:0]    MASTER2_READ_SLAVE8 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE9 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE10 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE11 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE12 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE13 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE14 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE15 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE16 = 1'b1;     // bit for slave indicating if a master can read to that port  
  parameter [0:0]    MASTER2_READ_SLAVE17 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE18 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE19 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE20 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE21 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE22 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE23 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE24 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE25 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE26 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE27 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE28 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE29 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE30 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER2_READ_SLAVE31 = 1'b1;     // bit for slave indicating if a master can read to that port     

  
  parameter [0:0]    MASTER3_READ_SLAVE0 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE1 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE2 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE3 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE4 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE5 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE6 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE7 = 1'b1;      // bit for slave indicating if a master can read to that port  
  parameter [0:0]    MASTER3_READ_SLAVE8 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE9 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE10 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE11 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE12 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE13 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE14 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE15 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE16 = 1'b1;     // bit for slave indicating if a master can read to that port  
  parameter [0:0]    MASTER3_READ_SLAVE17 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE18 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE19 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE20 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE21 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE22 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE23 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE24 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE25 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE26 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE27 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE28 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE29 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE30 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER3_READ_SLAVE31 = 1'b1;     // bit for slave indicating if a master can read to that port 

  
  parameter [0:0]    MASTER4_READ_SLAVE0 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE1 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE2 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE3 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE4 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE5 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE6 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE7 = 1'b1;      // bit for slave indicating if a master can read to that port  
  parameter [0:0]    MASTER4_READ_SLAVE8 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE9 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE10 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE11 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE12 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE13 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE14 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE15 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE16 = 1'b1;     // bit for slave indicating if a master can read to that port  
  parameter [0:0]    MASTER4_READ_SLAVE17 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE18 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE19 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE20 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE21 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE22 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE23 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE24 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE25 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE26 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE27 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE28 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE29 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE30 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER4_READ_SLAVE31 = 1'b1;     // bit for slave indicating if a master can read to that port 

  
  parameter [0:0]    MASTER5_READ_SLAVE0 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE1 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE2 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE3 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE4 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE5 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE6 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE7 = 1'b1;      // bit for slave indicating if a master can read to that port  
  parameter [0:0]    MASTER5_READ_SLAVE8 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE9 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE10 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE11 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE12 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE13 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE14 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE15 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE16 = 1'b1;     // bit for slave indicating if a master can read to that port  
  parameter [0:0]    MASTER5_READ_SLAVE17 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE18 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE19 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE20 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE21 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE22 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE23 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE24 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE25 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE26 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE27 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE28 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE29 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE30 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER5_READ_SLAVE31 = 1'b1;     // bit for slave indicating if a master can read to that port 

  
  parameter [0:0]    MASTER6_READ_SLAVE0 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE1 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE2 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE3 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE4 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE5 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE6 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE7 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE8 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE9 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE10 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE11 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE12 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE13 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE14 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE15 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE16 = 1'b1;     // bit for slave indicating if a master can read to that port  
  parameter [0:0]    MASTER6_READ_SLAVE17 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE18 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE19 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE20 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE21 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE22 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE23 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE24 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE25 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE26 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE27 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE28 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE29 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE30 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER6_READ_SLAVE31 = 1'b1;     // bit for slave indicating if a master can read to that port 

  
  parameter [0:0]    MASTER7_READ_SLAVE0 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE1 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE2 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE3 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE4 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE5 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE6 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE7 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE8 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE9 = 1'b1;      // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE10 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE11 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE12 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE13 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE14 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE15 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE16 = 1'b1;     // bit for slave indicating if a master can read to that port  
  parameter [0:0]    MASTER7_READ_SLAVE17 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE18 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE19 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE20 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE21 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE22 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE23 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE24 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE25 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE26 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE27 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE28 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE29 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE30 = 1'b1;     // bit for slave indicating if a master can read to that port
  parameter [0:0]    MASTER7_READ_SLAVE31 = 1'b1;     // bit for slave indicating if a master can read to that port 

  parameter  OPT_HIFREQ          = 0;        // increases freq of operation at cost of added latency
  parameter  RD_ARB_EN           = 1;        // select arb or ordered rdata

  //====================================================================
  // Port Protocol Convertor / Data Width Convertor parameters
  //====================================================================
  parameter [1:0] MASTER0_TYPE  = 2'b10;           // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3, 10 = AHB
  parameter [1:0] MASTER1_TYPE  = 2'b01;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3, 10 = AHB
  parameter [1:0] MASTER2_TYPE  = 2'b11;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3, 10 = AHB
  parameter [1:0] MASTER3_TYPE  = 2'b00;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3, 10 = AHB
  parameter [1:0] MASTER4_TYPE  = MASTER0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3, 10 = AHB
  parameter [1:0] MASTER5_TYPE  = MASTER0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3, 10 = AHB
  parameter [1:0] MASTER6_TYPE  = MASTER0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3, 10 = AHB
  parameter [1:0] MASTER7_TYPE  = MASTER0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3, 10 = AHB
  
  parameter [1:0] SLAVE0_TYPE  = 2'b11;          // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE1_TYPE  = 2'b00;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE2_TYPE  = 2'b01;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE3_TYPE  = 2'b00;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE4_TYPE  = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE5_TYPE  = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE6_TYPE  = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE7_TYPE  = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE8_TYPE  = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE9_TYPE  = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE10_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE11_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE12_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE13_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE14_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE15_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE16_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE17_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE18_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE19_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE20_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE21_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE22_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE23_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE24_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE25_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE26_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE27_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE28_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE29_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE30_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3
  parameter [1:0] SLAVE31_TYPE = SLAVE0_TYPE;    // Valid Values - 00 = AXI4, 01=AXI4-Lite, 11 = AXI3

  parameter  [31:0] MASTER0_DATA_WIDTH  =  512;                       // Defines data width of Master0
  parameter  [31:0] MASTER1_DATA_WIDTH  =  32;                       // Defines data width of Master1
  parameter  [31:0] MASTER2_DATA_WIDTH  =  64;                       // Defines data width of Master2
  parameter  [31:0] MASTER3_DATA_WIDTH  =  256;                       // Defines data width of Master3
  parameter  [31:0] MASTER4_DATA_WIDTH  =  MASTER0_DATA_WIDTH;                       // Defines data width of Master4
  parameter  [31:0] MASTER5_DATA_WIDTH  =  MASTER0_DATA_WIDTH;                       // Defines data width of Master5
  parameter  [31:0] MASTER6_DATA_WIDTH  =  MASTER0_DATA_WIDTH;     // Defines data width of Master6
  parameter  [31:0] MASTER7_DATA_WIDTH  =  MASTER0_DATA_WIDTH;     // Defines data width of Master7
  
  parameter  [31:0] SLAVE0_DATA_WIDTH  =  32;                     // Defines data width of Slave0
  parameter  [31:0] SLAVE1_DATA_WIDTH  =  64;      // Defines data width of Slave1
  parameter  [31:0] SLAVE2_DATA_WIDTH  =  128;      // Defines data width of Slave2
  parameter  [31:0] SLAVE3_DATA_WIDTH  =  256;      // Defines data width of Slave3
  parameter  [31:0] SLAVE4_DATA_WIDTH  =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave4
  parameter  [31:0] SLAVE5_DATA_WIDTH  =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave5
  parameter  [31:0] SLAVE6_DATA_WIDTH  =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave6
  parameter  [31:0] SLAVE7_DATA_WIDTH  =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave7
  parameter  [31:0] SLAVE8_DATA_WIDTH  =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave8
  parameter  [31:0] SLAVE9_DATA_WIDTH  =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave9
  parameter  [31:0] SLAVE10_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave10
  parameter  [31:0] SLAVE11_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave11
  parameter  [31:0] SLAVE12_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave12
  parameter  [31:0] SLAVE13_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave13
  parameter  [31:0] SLAVE14_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave14
  parameter  [31:0] SLAVE15_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave15
  parameter  [31:0] SLAVE16_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave16
  parameter  [31:0] SLAVE17_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave17
  parameter  [31:0] SLAVE18_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave18
  parameter  [31:0] SLAVE19_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave19
  parameter  [31:0] SLAVE20_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave20
  parameter  [31:0] SLAVE21_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave21
  parameter  [31:0] SLAVE22_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave22
  parameter  [31:0] SLAVE23_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave23
  parameter  [31:0] SLAVE24_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave24
  parameter  [31:0] SLAVE25_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave25
  parameter  [31:0] SLAVE26_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave26
  parameter  [31:0] SLAVE27_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave27
  parameter  [31:0] SLAVE28_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave28
  parameter  [31:0] SLAVE29_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave29
  parameter  [31:0] SLAVE30_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave30
  parameter  [31:0] SLAVE31_DATA_WIDTH =  SLAVE0_DATA_WIDTH;      // Defines data width of Slave31
  
  
  parameter integer  SLV_AXI4PRT_ADDRDEPTH = 3;          // valid 2-6 , Number transactions 2^SLV_AXI4PRT_ADDRDEPTH
  parameter integer  SLV_AXI4PRT_DATADEPTH = 3;          // valid 2-6 , Number transactions 2^SLV_AXI4PRT_DATADEPTH
  
  parameter integer MAX_TX_MST_SLV = 1;

  //====================================================================
  // Register Slice parameters
  //====================================================================
  parameter     MASTER0_AWCHAN_RS = 1'b1;        // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter     MASTER1_AWCHAN_RS = MASTER0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter     MASTER2_AWCHAN_RS = MASTER0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter     MASTER3_AWCHAN_RS = MASTER0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter     MASTER4_AWCHAN_RS = MASTER0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter     MASTER5_AWCHAN_RS = MASTER0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter     MASTER6_AWCHAN_RS = MASTER0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter     MASTER7_AWCHAN_RS = MASTER0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted

  parameter     MASTER0_ARCHAN_RS = 1'b1;        // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter     MASTER1_ARCHAN_RS = MASTER0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter     MASTER2_ARCHAN_RS = MASTER0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter     MASTER3_ARCHAN_RS = MASTER0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter     MASTER4_ARCHAN_RS = MASTER0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter     MASTER5_ARCHAN_RS = MASTER0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter     MASTER6_ARCHAN_RS = MASTER0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter     MASTER7_ARCHAN_RS = MASTER0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted

  parameter     MASTER0_WCHAN_RS = 1'b1;        // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter     MASTER1_WCHAN_RS = MASTER0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter     MASTER2_WCHAN_RS = MASTER0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter     MASTER3_WCHAN_RS = MASTER0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter     MASTER4_WCHAN_RS = MASTER0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter     MASTER5_WCHAN_RS = MASTER0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter     MASTER6_WCHAN_RS = MASTER0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter     MASTER7_WCHAN_RS = MASTER0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted

  parameter     MASTER0_RCHAN_RS = 1'b1;        // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter     MASTER1_RCHAN_RS = MASTER0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter     MASTER2_RCHAN_RS = MASTER0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter     MASTER3_RCHAN_RS = MASTER0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter     MASTER4_RCHAN_RS = MASTER0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter     MASTER5_RCHAN_RS = MASTER0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter     MASTER6_RCHAN_RS = MASTER0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter     MASTER7_RCHAN_RS = MASTER0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted

  parameter     MASTER0_BCHAN_RS = 1'b1;        // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter     MASTER1_BCHAN_RS = MASTER0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter     MASTER2_BCHAN_RS = MASTER0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter     MASTER3_BCHAN_RS = MASTER0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter     MASTER4_BCHAN_RS = MASTER0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter     MASTER5_BCHAN_RS = MASTER0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter     MASTER6_BCHAN_RS = MASTER0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter     MASTER7_BCHAN_RS = MASTER0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted

  parameter [0:0]  SLAVE0_AWCHAN_RS  = 1'b1;              // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE1_AWCHAN_RS  = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE2_AWCHAN_RS  = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE3_AWCHAN_RS  = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE4_AWCHAN_RS  = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE5_AWCHAN_RS  = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE6_AWCHAN_RS  = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE7_AWCHAN_RS  = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE8_AWCHAN_RS  = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE9_AWCHAN_RS  = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE10_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE11_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE12_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE13_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE14_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE15_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE16_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE17_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE18_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE19_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE20_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE21_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE22_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE23_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE24_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE25_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE26_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE27_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE28_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE29_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE30_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  parameter [0:0]  SLAVE31_AWCHAN_RS = SLAVE0_AWCHAN_RS;  // 0 - no AWCHAN register slice, 1 - AWCHAN register slice inserted
  
  parameter [0:0]  SLAVE0_ARCHAN_RS  = 1'b1;              // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE1_ARCHAN_RS  = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE2_ARCHAN_RS  = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE3_ARCHAN_RS  = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE4_ARCHAN_RS  = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE5_ARCHAN_RS  = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE6_ARCHAN_RS  = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE7_ARCHAN_RS  = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE8_ARCHAN_RS  = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE9_ARCHAN_RS  = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE10_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE11_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE12_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE13_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE14_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE15_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE16_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE17_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE18_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE19_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE20_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE21_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE22_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE23_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE24_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE25_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE26_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE27_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE28_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE29_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE30_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  parameter [0:0]  SLAVE31_ARCHAN_RS = SLAVE0_ARCHAN_RS;  // 0 - no ARCHAN register slice, 1 - ARCHAN register slice inserted
  
  parameter [0:0]  SLAVE0_WCHAN_RS  = 1'b1;             // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE1_WCHAN_RS  = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE2_WCHAN_RS  = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE3_WCHAN_RS  = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE4_WCHAN_RS  = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE5_WCHAN_RS  = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE6_WCHAN_RS  = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE7_WCHAN_RS  = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE8_WCHAN_RS  = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE9_WCHAN_RS  = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE10_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE11_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE12_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE13_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE14_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE15_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE16_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE17_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE18_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE19_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE20_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE21_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE22_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE23_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE24_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE25_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE26_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE27_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE28_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE29_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE30_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  parameter [0:0]  SLAVE31_WCHAN_RS = SLAVE0_WCHAN_RS;  // 0 - no WCHAN register slice, 1 - WCHAN register slice inserted
  
  parameter [0:0]  SLAVE0_RCHAN_RS  = 1'b1;             // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE1_RCHAN_RS  = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE2_RCHAN_RS  = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE3_RCHAN_RS  = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE4_RCHAN_RS  = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE5_RCHAN_RS  = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE6_RCHAN_RS  = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE7_RCHAN_RS  = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE8_RCHAN_RS  = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE9_RCHAN_RS  = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE10_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE11_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE12_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE13_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE14_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE15_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE16_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE17_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE18_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE19_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE20_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE21_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE22_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE23_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE24_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE25_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE26_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE27_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE28_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE29_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE30_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  parameter [0:0]  SLAVE31_RCHAN_RS = SLAVE0_RCHAN_RS;  // 0 - no RCHAN register slice, 1 - RCHAN register slice inserted
  
  parameter [0:0]  SLAVE0_BCHAN_RS  = 1'b1;             // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE1_BCHAN_RS  = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE2_BCHAN_RS  = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE3_BCHAN_RS  = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE4_BCHAN_RS  = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE5_BCHAN_RS  = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE6_BCHAN_RS  = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE7_BCHAN_RS  = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE8_BCHAN_RS  = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE9_BCHAN_RS  = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE10_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE11_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE12_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE13_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE14_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE15_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE16_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE17_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE18_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE19_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE20_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE21_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE22_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE23_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE24_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE25_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE26_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE27_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE28_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE29_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE30_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted
  parameter [0:0]  SLAVE31_BCHAN_RS = SLAVE0_BCHAN_RS;  // 0 - no BCHAN register slice, 1 - BCHAN register slice inserted

  parameter  [7:0] MASTER0_DEF_BURST_LEN  =  8'hf;      // Defines the default burst length if the AHB interface of Master0
  parameter  [7:0] MASTER1_DEF_BURST_LEN  =  8'h1;      // Defines the default burst length if the AHB interface of Master1
  parameter  [7:0] MASTER2_DEF_BURST_LEN  =  8'h00;      // Defines the default burst length if the AHB interface of Master2
  parameter  [7:0] MASTER3_DEF_BURST_LEN  =  8'h0a;      // Defines the default burst length if the AHB interface of Master3
  parameter  [7:0] MASTER4_DEF_BURST_LEN  =  8'h11;      // Defines the default burst length if the AHB interface of Master4
  parameter  [7:0] MASTER5_DEF_BURST_LEN  =  8'h0f;      // Defines the default burst length if the AHB interface of Master5
  parameter  [7:0] MASTER6_DEF_BURST_LEN  =  8'hf;      // Defines the default burst length if the AHB interface of Master6
  parameter  [7:0] MASTER7_DEF_BURST_LEN  =  8'h1;      // Defines the default burst length if the AHB interface of Master7

  parameter  [13:0] SLAVE0_DWC_DATA_FIFO_DEPTH   =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave0
  parameter  [13:0] SLAVE1_DWC_DATA_FIFO_DEPTH   =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave1
  parameter  [13:0] SLAVE2_DWC_DATA_FIFO_DEPTH   =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave2
  parameter  [13:0] SLAVE3_DWC_DATA_FIFO_DEPTH   =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave3
  parameter  [13:0] SLAVE4_DWC_DATA_FIFO_DEPTH   =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave4
  parameter  [13:0] SLAVE5_DWC_DATA_FIFO_DEPTH   =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave5
  parameter  [13:0] SLAVE6_DWC_DATA_FIFO_DEPTH   =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave6
  parameter  [13:0] SLAVE7_DWC_DATA_FIFO_DEPTH   =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave7
  parameter  [13:0] SLAVE8_DWC_DATA_FIFO_DEPTH   =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave8
  parameter  [13:0] SLAVE9_DWC_DATA_FIFO_DEPTH   =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave9
  parameter  [13:0] SLAVE10_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave10
  parameter  [13:0] SLAVE11_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave11
  parameter  [13:0] SLAVE12_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave12
  parameter  [13:0] SLAVE13_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave13
  parameter  [13:0] SLAVE14_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave14
  parameter  [13:0] SLAVE15_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave15
  parameter  [13:0] SLAVE16_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave16
  parameter  [13:0] SLAVE17_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave17
  parameter  [13:0] SLAVE18_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave18
  parameter  [13:0] SLAVE19_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave19
  parameter  [13:0] SLAVE20_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave20
  parameter  [13:0] SLAVE21_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave21
  parameter  [13:0] SLAVE22_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave22
  parameter  [13:0] SLAVE23_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave23
  parameter  [13:0] SLAVE24_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave24
  parameter  [13:0] SLAVE25_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave25
  parameter  [13:0] SLAVE26_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave26
  parameter  [13:0] SLAVE27_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave27
  parameter  [13:0] SLAVE28_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave28
  parameter  [13:0] SLAVE29_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave29
  parameter  [13:0] SLAVE30_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave30
  parameter  [13:0] SLAVE31_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Slave31

  parameter  [13:0] MASTER0_DWC_DATA_FIFO_DEPTH  =  14'hc;      // Defines the depth of the data FIFO in the datawidth converter of Master0
  parameter  [13:0] MASTER1_DWC_DATA_FIFO_DEPTH  =  14'h3;      // Defines the depth of the data FIFO in the datawidth converter of Master1
  parameter  [13:0] MASTER2_DWC_DATA_FIFO_DEPTH  =  14'hb;      // Defines the depth of the data FIFO in the datawidth converter of Master2
  parameter  [13:0] MASTER3_DWC_DATA_FIFO_DEPTH  =  14'h5;      // Defines the depth of the data FIFO in the datawidth converter of Master3
  parameter  [13:0] MASTER4_DWC_DATA_FIFO_DEPTH  =  14'h11;      // Defines the depth of the data FIFO in the datawidth converter of Master4
  parameter  [13:0] MASTER5_DWC_DATA_FIFO_DEPTH  =  14'h10;      // Defines the depth of the data FIFO in the datawidth converter of Master5
  parameter  [13:0] MASTER6_DWC_DATA_FIFO_DEPTH  =  14'h4;      // Defines the depth of the data FIFO in the datawidth converter of Master6
  parameter  [13:0] MASTER7_DWC_DATA_FIFO_DEPTH  =  14'h8;      // Defines the depth of the data FIFO in the datawidth converter of Master7

  parameter [31:0] XBAR_CLK_PERIOD = 10;

  parameter [31:0] MASTER0_CLK_PERIOD  = 6;
  parameter [31:0] MASTER1_CLK_PERIOD  = 7;
  parameter [31:0] MASTER2_CLK_PERIOD  = 7;
  parameter [31:0] MASTER3_CLK_PERIOD  = 9;
  parameter [31:0] MASTER4_CLK_PERIOD  = MASTER0_CLK_PERIOD;
  parameter [31:0] MASTER5_CLK_PERIOD  = MASTER0_CLK_PERIOD;
  parameter [31:0] MASTER6_CLK_PERIOD  = MASTER0_CLK_PERIOD;
  parameter [31:0] MASTER7_CLK_PERIOD  = MASTER0_CLK_PERIOD;
  
  parameter [31:0] SLAVE0_CLK_PERIOD    = XBAR_CLK_PERIOD;
  parameter [31:0] SLAVE1_CLK_PERIOD    = 5;
  parameter [31:0] SLAVE2_CLK_PERIOD    = 11;
  parameter [31:0] SLAVE3_CLK_PERIOD    = 20;
  parameter [31:0] SLAVE4_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE5_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE6_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE7_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE8_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE9_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE10_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE11_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE12_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE13_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE14_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE15_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE16_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE17_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE18_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE19_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE20_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE21_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE22_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE23_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE24_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE25_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE26_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE27_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE28_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE29_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE30_CLK_PERIOD    = SLAVE0_CLK_PERIOD;
  parameter [31:0] SLAVE31_CLK_PERIOD    = SLAVE0_CLK_PERIOD;



  parameter integer XBAR_PHASE = 0;

  parameter integer MASTER0_PHASE  = XBAR_PHASE;  
  parameter integer MASTER1_PHASE  = MASTER0_PHASE;  
  parameter integer MASTER2_PHASE  = MASTER0_PHASE;  
  parameter integer MASTER3_PHASE  = MASTER0_PHASE;  
  parameter integer MASTER4_PHASE  = MASTER0_PHASE;  
  parameter integer MASTER5_PHASE  = MASTER0_PHASE;  
  parameter integer MASTER6_PHASE  = MASTER0_PHASE;  
  parameter integer MASTER7_PHASE  = MASTER0_PHASE;    
  
  parameter integer SLAVE0_PHASE    = XBAR_PHASE;
  parameter integer SLAVE1_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE2_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE3_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE4_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE5_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE6_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE7_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE8_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE9_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE10_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE11_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE12_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE13_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE14_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE15_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE16_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE17_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE18_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE19_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE20_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE21_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE22_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE23_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE24_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE25_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE26_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE27_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE28_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE29_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE30_PHASE    = SLAVE0_PHASE;
  parameter integer SLAVE31_PHASE    = SLAVE0_PHASE;


  //====================================================================
  // AXI4Master /Slave  parameters
  //====================================================================

  parameter OPEN_MTTRANS_MAX         = OPEN_WRTRANS_MAX;      // max. number of outstanding transaction in MasterGen
  parameter OPEN_SLTRANS_MAX         = OPEN_WRTRANS_MAX;      // max. number of outstanding transaction in SlaveGen

  parameter integer   NUM_AXISLAVE_BITS     = 'd23;    // Defines lower bound of compare - bits below are dont care
  parameter integer  RNDEN         = 0;    // Enables (1) or Disables (0) randomising in the tests - if RREADY/WREADY idles cycles

  parameter [31:0] CNT_INIT = 0;

  //====================================================================
  // AHB Master parameters
  //====================================================================
  parameter AHB_AWIDTH = 32;
  parameter [7:0] UNDEF_BURST_MASTER0 = 8'hf;
  parameter [7:0] UNDEF_BURST_MASTER1 = 8'h1;
  parameter [7:0] UNDEF_BURST_MASTER2 = 8'h00;
  parameter [7:0] UNDEF_BURST_MASTER3 = 8'h0a;
  parameter [7:0] UNDEF_BURST_MASTER4 = 8'h11;
  parameter [7:0] UNDEF_BURST_MASTER5 = 8'h0f;
  parameter [7:0] UNDEF_BURST_MASTER6 = 8'hf;
  parameter [7:0] UNDEF_BURST_MASTER7 = 8'h1;
  
