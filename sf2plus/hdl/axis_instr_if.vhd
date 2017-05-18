-- axis_instr_if.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.
--
-- AXI4-Stream to FSL instruction Port interface.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
library work;
use work.util_pkg.all;
use work.architecture_pkg.all;

entity axis_instr_if is
  port (
    clk          : in std_logic;
    reset        : in std_logic;

    m_tdata      : out std_logic_vector(31 downto 0);
    m_tlast      : out std_logic;
    m_tvalid     : out std_logic;
    m_tready     : in  std_logic;

    s_tdata      : in  std_logic_vector(31 downto 0);
    s_tlast      : in  std_logic;
    s_tvalid     : in  std_logic;
    s_tready     : out std_logic;

    fsl_s_read   : out std_logic;
    fsl_s_data   : in  std_logic_vector(0 to 31);
    fsl_s_exists : in  std_logic;

    fsl_m_write  : out std_logic;
    fsl_m_data   : out std_logic_vector(0 to 31);
    fsl_m_full   : in  std_logic
    );
end entity axis_instr_if;

architecture rtl of axis_instr_if is
begin
  ---------------------------------------------------------------------------
  -- UG761 AXI Reference Guide,
  -- section "Migrating a Fast Simplex Link to AXI4-Stream":

  -- "An AXI4-Stream master cannot use the status of AXI_S_TREADY unless a
  -- transfer is started."

  -- "The MicroBlaze processor has an FSL test instruction that checks the
  -- current status of the FSL interface. For this instruction to function
  -- on the AXI4-Stream, MicroBlaze has an additional 32-bit D Flip-Flop for
  -- each AXI4-Stream master interface to act as an output holding register.
  --
  -- When MicroBlaze executes a put fsl instruction, it writes to this DFF.
  -- The AXI4-Stream logic inside MicroBlaze moves the value out from the
  -- DFF to the external AXI4-Stream slave device as soon as the AXI4-Stream
  -- allows. Instead of checking the AXI4-Stream TREADY/TVALID signals,
  -- the FSL test instruction checks if the DFF contains valid data instead
  -- because the AXI_S_TREADY signal cannot be directly used for this purpose.
  --
  -- The additional 32-bit DFFs ensure that all current FSL instructions to
  -- work seamlessly on AXI4-Stream. There is no change needed in the software
  -- when converting from FSL to AXI4 stream."

  ----------------------------------------------------------------------------
  -- For blocking put instruction, MicroBlaze with old FSL would not assert
  -- fsl_m_write if fsl_m_full=1. The fsl_handler does not gate fsl_m_write
  -- with fsl_m_full and expects writer to check full status.
  --
  -- However, AXI4-Stream master can assert tvalid if tready=0. Therefore this
  -- module is responsible for not asserting fsl_m_write if fsl_m_full is
  -- asserted.
  --
  -- AXI4-Stream spec:
  -- "A slave is permitted to wait for TVALID to be asserted before asserting
  -- the corresponding TREADY."
  --
  fsl_m_data <= s_tdata;
  fsl_m_write <= s_tvalid and (not fsl_m_full);
  s_tready <= not fsl_m_full;
  -- s_tlast not used (reflects fsl control bit).

  ----------------------------------------------------------------------------
  -- AXI4-Stream spec:
  -- "A master is not permitted to wait until TREADY is asserted before
  -- asserting TVALID. Once TVALID is asserted it must remain asserted until
  -- the handshake occurs."

  m_tdata <= fsl_s_data;
  m_tlast <= '0'; -- fsl control bit
  m_tvalid <= fsl_s_exists;
  fsl_s_read <= m_tready;

end architecture rtl;
