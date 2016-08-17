library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity read_pipeline is
  generic (REGISTER_SIZE : integer := 32;
           MAX_PIPELINE  : integer := 7);
  
  port (clk : in std_logic;
        reset : in std_logic;
        pipeline_count : in std_logic_vector(2 downto 0);
        -- master port
        m_address : in std_logic_vector(7 downto 0);
        m_byteenable : in std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
        m_read : in std_logic;
        m_readdata : out std_logic_vector(REGISTER_SIZE-1 downto 0); -- pipelined
        m_response : out std_logic_vector(1 downto 0); -- pipelined
        m_write : in std_logic; 
        m_writedata : in std_logic_vector(REGISTER_SIZE-1 downto 0);
        m_lock : in std_logic;
        m_waitrequest : out std_logic; 
        m_readdatavalid : out std_logic; -- pipelined
        -- slave port
        s_address : out std_logic_vector(7 downto 0);
        s_byteenable : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
        s_read : out std_logic;
        s_readdata : in std_logic_vector(REGISTER_SIZE-1 downto 0);
        s_response : in std_logic_vector(1 downto 0);
        s_write : out std_logic;
        s_writedata : out std_logic_vector(REGISTER_SIZE-1 downto 0);
        s_lock : out std_logic;
        s_waitrequest : in std_logic;
        s_readdatavalid : in std_logic);
         
end entity read_pipeline;

architecture rtl of read_pipeline is

  type readdata_pipeline_t is array(MAX_PIPELINE downto 0) of std_logic_vector(REGISTER_SIZE-1 downto 0);
  type response_pipeline_t is array(MAX_PIPELINE downto 0) of std_logic_vector(1 downto 0);
  type readdatavalid_pipeline_t is array(MAX_PIPELINE downto 0) of std_logic;

  signal readdata_pipeline : readdata_pipeline_t;
  signal response_pipeline : response_pipeline_t;
  signal readdatavalid_pipeline : readdatavalid_pipeline_t;

begin
  -- pass-through signals
  s_address <= m_address;
  s_byteenable <= m_byteenable;
  s_read <= m_read;
  m_readdata <= readdata_pipeline(to_integer(unsigned(pipeline_count)));
  m_response <= response_pipeline(to_integer(unsigned(pipeline_count)));
  s_write <= m_write;
  s_writedata <= m_writedata;
  s_lock <= m_lock;
  m_waitrequest <= s_waitrequest;
  m_readdatavalid <= readdatavalid_pipeline(to_integer(unsigned(pipeline_count)));

  -- pipelined signals
  process (clk)
  begin
    if rising_edge(clk) then
      readdata_pipeline(0) <= s_readdata;
      response_pipeline(0) <= s_response;
      readdatavalid_pipeline(0) <= s_readdatavalid;
      for i in 0 to (MAX_PIPELINE-1) loop
        readdata_pipeline(i+1) <= readdata_pipeline(i);
        response_pipeline(i+1) <= response_pipeline(i);
        readdatavalid_pipeline(i+1) <= readdatavalid_pipeline(i);  
      end loop; 
    end if;
  end process;  


end architecture rtl;
