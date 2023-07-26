--Javier Abadía / jabadiagm@gmail.com
--Structure based on Multicomputer by Grant Searle:
--           http://searle.x10host.com/Multicomp/index.html

library ieee;
use ieee.std_logic_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

entity MSX_Interceptor is
	port(

	   --74lvc245 buffer signals
	    --address bus
		ex_busAddress    : in std_logic_vector(15 downto 0);

		--data bus
		ex_busDataOut     : inout std_logic_vector(7 downto 0);
		
		--control bus
		ex_busMreq_n     : in std_logic;
		ex_busIorq_n     : in std_logic;
		ex_busRd_n       : in std_logic;
		ex_busWr_n       : in std_logic;
		ex_busReset_n    : in std_logic;
		ex_clk_3m6       : in std_logic;
        ex_bus_sltsl_n   : in std_logic;

        --bus direction
        ex_bus_data_reverse_n : out std_logic;
		
		--interrupt
		--ex_int_n         : out std_logic;

		--fpga signals
		ex_reset    : in  std_logic:='1';
        ex_clk_27m	  : in std_logic:='0';
        ex_btn0	      : in std_logic:='0';
		
        --hdmi out
        data_p    : out  STD_LOGIC_VECTOR(2 downto 0);
        data_n    : out  STD_LOGIC_VECTOR(2 downto 0);
        clk_p          : out    std_logic;
        clk_n          : out    std_logic;  

        -- Magic ports for SDRAM to be inferred
        O_sdram_clk : out std_logic;
        O_sdram_cke : out std_logic;
        O_sdram_cs_n : out std_logic; -- chip select
        O_sdram_cas_n : out std_logic; -- columns address select
        O_sdram_ras_n : out std_logic; -- row address select
        O_sdram_wen_n : out std_logic; -- write enable
        IO_sdram_dq : inout std_logic_vector(31 downto 0); -- 32 bit bidirectional data bus
        O_sdram_addr : out std_logic_vector (10 downto 0); -- 11 bit multiplexed address bus
        O_sdram_ba : out std_logic_vector(1 downto 0); -- two banks
        O_sdram_dqm  : out std_logic_vector(3 downto 0); -- 32/4	
        
        ex_led          : out  STD_LOGIC
        --ex_led          : out  STD_LOGIC_VECTOR (5 downto 0)

	);
end MSX_Interceptor;

architecture struct of MSX_Interceptor is

	signal busAddress	            : std_logic_vector(15 downto 0);
	signal busDataOut               : std_logic_vector(7 downto 0);
		
	signal busMreq_n                : std_logic;
	signal busIorq_n                : std_logic;
	signal busRd_n                  : std_logic;
	signal busWr_n                  : std_logic;
	signal busReset_n               : std_logic;
	signal clk_3m6                  : std_logic;
    signal bus_sltsl_n              : std_logic;

	signal memWr_n					: std_logic :='1';
	signal memRd_n 					: std_logic :='1';

	signal ioWr_n					: std_logic :='1';
	signal ioRd_n 					: std_logic :='1';
	
    signal clk_1m8                  : std_logic:='0'; --psg clock 3.57/2 = 1.8 MHz   

    signal reset : std_logic:='0';
    signal reset_n : std_logic;

	--YM2149 PSG signals
	signal psgBc1                        : std_logic:='0'; --psg chip select & mode 1/2
	signal psgBdir : std_logic:='0'; --psg chip select & mode 2/2
	signal psgDataOut : std_logic_vector (7 downto 0); --psg output
	signal psgSound1 : std_logic_vector (7 downto 0); --psg output sound channel 1
	signal psgSound2 : std_logic_vector (7 downto 0) := "10000000"; --psg output sound channel 2
	signal psgSound3 : std_logic_vector (7 downto 0); --psg output sound channel 3
	signal psgPA : std_logic_vector (7 downto 0); --psg port a
	signal psgPB : std_logic_vector (7 downto 0):=x"ff"; --psg port b
	signal psgDebug : std_logic_vector (7 downto 0);

    --V9958 signals
	signal v9958_csw_n : std_logic:='1'; --VDP write request
	signal v9958_csr_n : std_logic:='1'; --VDP read request	

    --opll signals
    signal opll_req          : std_logic; 
    signal opll_mo           : std_logic_vector (9 downto 0);
    signal opll_ro           : std_logic_vector (9 downto 0);
    signal opll_mix          : std_logic_vector(11 downto 0);
    signal opll_wav          : std_logic_vector (31 downto 0);
    signal opll_wav_filter   : std_logic_vector (31 downto 0);
	signal audio_sample : std_logic_vector (15 downto 0);
	signal audio_sample1 : std_logic_vector (15 downto 0);
	signal audio_sample2 : std_logic_vector (15 downto 0);
    signal clk_enable                   : std_logic := '0';
    signal clk_enable_counter           : std_logic_vector (2 downto 0):=(others=>'0');
    type type_state_4 is (state1, state2, state3, state4);
    signal interclock_state: type_state_4 := state1;
    signal interclock2_state: type_state_4 := state1;
    signal interclock3_state: type_state_4 := state1;
    signal clk_enable_state             : type_state_4:=state1;

    --fmrom signals
    signal fmrom_read       : std_logic;
    signal fmrom_dout       : std_logic_vector (7 downto 0);
    signal fmrom_counter    : std_logic_vector (4 downto 0);
    signal fmrom_state      : std_logic_vector (1 downto 0);
    signal bus_data_reverse : std_logic;

component denoise
    port (
		data_in		: IN STD_LOGIC;
		clock		: IN STD_LOGIC;
		data_out	: OUT STD_LOGIC 
    );
end component;

component denoise_8	
	PORT
	(
		data8_in	: IN STD_LOGIC_VECTOR(7 downto 0);
		clock		: IN STD_LOGIC  := '1';
		data8_out	: OUT STD_LOGIC_VECTOR(7 downto 0) 
	);
end component;

component denoise_low
    port (
		data_in		: IN STD_LOGIC;
		clock		: IN STD_LOGIC;
		data_out	: OUT STD_LOGIC 
    );
end component;

component denoise_low8	
	PORT
	(
		data8_in	: IN STD_LOGIC_VECTOR(7 downto 0);
		clock		: IN STD_LOGIC  := '1';
		data8_out	: OUT STD_LOGIC_VECTOR(7 downto 0) 
	);
end component;


component v9958_top
    port(

    clk     : in std_logic;
    s1   : in std_logic;

    reset_n : in std_logic;
    mode    : in std_logic_vector(1 downto 0);
    csw_n   : in std_logic;
    csr_n   : in std_logic;

    int_n   : out std_logic;
    gromclk : out std_logic;
    cpuclk  : out std_logic;
    cdi     : out std_logic_vector(7 downto 0);
    cdo     : in std_logic_vector(7 downto 0);

    audio_sample   : in std_logic_vector(15 downto 0);

    --led     : out std_logic_vector(1 downto 0);

    maxspr_n    : in std_logic;
    scanlin_n   : in std_logic;
    gromclk_ena_n   : in std_logic;
    cpuclk_ena_n    : in std_logic;

    tmds_clk_p    : out std_logic;
    tmds_clk_n    : out std_logic;
    tmds_data_p   : out std_logic_vector(2 downto 0);
    tmds_data_n   : out std_logic_vector(2 downto 0);

    O_sdram_clk : out std_logic;
    O_sdram_cke : out std_logic;
    O_sdram_cs_n : out std_logic; -- chip select
    O_sdram_cas_n : out std_logic; -- columns address select
    O_sdram_ras_n : out std_logic; -- row address select
    O_sdram_wen_n : out std_logic; -- write enable
    IO_sdram_dq : inout std_logic_vector(31 downto 0); -- 32 bit bidirectional data bus
    O_sdram_addr : out std_logic_vector (10 downto 0); -- 11 bit multiplexed address bus
    O_sdram_ba : out std_logic_vector(1 downto 0); -- two banks
    O_sdram_dqm  : out std_logic_vector(3 downto 0) -- 32/4	


    );
end component;

component YM2149 
      port (
      -- data bus
      I_DA                : in  std_logic_vector(7 downto 0);
      O_DA                : out std_logic_vector(7 downto 0);
      O_DA_OE_L           : out std_logic;
      -- control
      I_A9_L              : in  std_logic;
      I_A8                : in  std_logic;
      I_BDIR              : in  std_logic;
      I_BC2               : in  std_logic;
      I_BC1               : in  std_logic;
      I_SEL_L             : in  std_logic;
    
      O_AUDIO             : out std_logic_vector(7 downto 0);
      -- port a
      I_IOA               : in  std_logic_vector(7 downto 0);
      O_IOA               : out std_logic_vector(7 downto 0);
      O_IOA_OE_L          : out std_logic;
      -- port b
      I_IOB               : in  std_logic_vector(7 downto 0);
      O_IOB               : out std_logic_vector(7 downto 0);
      O_IOB_OE_L          : out std_logic;
    
      ENA                 : in  std_logic; -- clock enable for higher speed operation
      RESET_L             : in  std_logic;
      CLK                 : in  std_logic;  -- note 6 Mhz;
      clkHigh             : in std_logic;  --to avoid problems when cpu clk is slower than psg clk
      debug               : out std_logic_vector(7 downto 0)
      );
end component;  


component opll
    port(
        xin         : in    std_logic;
        xout        : out   std_logic;
        xena        : in    std_logic;
        d           : in    std_logic_vector( 7 downto 0 );
        a           : in    std_logic;
        cs_n        : in    std_logic;
        we_n        : in    std_logic;
        ic_n        : in    std_logic;
        mo          : out   std_logic_vector( 9 downto 0 );
        ro          : out   std_logic_vector( 9 downto 0 )
    );
end component;


component fm_filter
    generic (
        DATA_WIDTH : integer
    );
    port (
        clk_3m6 : in std_logic;
        clk_27m : in std_logic;
        reset : in std_logic;
        data_in : in std_logic_vector (DATA_WIDTH-1 downto 0);
        data_out : out std_logic_vector (DATA_WIDTH-1 downto 0)
    );
end component;

 component ram_16kb 
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END component;  

component  monostable
    port (
		pulse_in    : in std_logic;
		clock       : in std_logic;
		pulse_out_n : out std_logic
	);
end component;

begin

-- ____________________________________________________________________________________
-- clock signals


--generated clocks

process (clk_3m6)
begin
    if rising_edge(clk_3m6) then
        clk_1m8<=not clk_1m8;

    end if;
end process;



-- ____________________________________________________________________________________
-- MEMORY READ/WRITE LOGIC GOES HERE
ioWr_n <= busWr_n or busIorq_n;
memWr_n <= busWr_n or busMreq_n;
ioRd_n <= busRd_n or busIorq_n;
memRd_n <= busRd_n or busMreq_n;



-- ____________________________________________________________________________________
-- BUS ISOLATION GOES HERE
ex_bus_data_reverse_n <= not bus_data_reverse;
ex_busDataOut <= fmrom_dout when (bus_data_reverse = '1') else (others => 'Z');



reset <= not busReset_n;
reset_n <= busReset_n;


v9958_csw_n<= '0' when busAddress (7 downto 2) = "100110" and (ioWr_n='0') else '1'; -- I/O:98-9Bh   / VDP (V9938/V9958)
v9958_csr_n<= '0' when busAddress (7 downto 2) = "100110" and (ioRd_n='0') else '1'; -- I/O:98-9Bh   / VDP (V9938/V9958)

vdp4 : v9958_top
    port map(
    clk => ex_clk_27m,
    s1 => ex_reset,

    reset_n => busReset_n,
    mode    => busAddress(1 downto 0),
    csw_n   => v9958_csw_n,
    csr_n   => v9958_csr_n,

    int_n   => open,
    gromclk => open,
    cpuclk  => open,
    cdi     => open,
    cdo     => busDataOut,

    --audio_sample   => psgSound1 & "0000", 
    audio_sample   => audio_sample, 

    maxspr_n    => '1',
    scanlin_n   => '0',
    gromclk_ena_n   => '1',
    cpuclk_ena_n    => '1',

    O_sdram_clk => O_sdram_clk,
    O_sdram_cke => O_sdram_cke,
    O_sdram_cs_n => O_sdram_cs_n,
    O_sdram_cas_n => O_sdram_cas_n,
    O_sdram_ras_n => O_sdram_ras_n,
    O_sdram_wen_n => O_sdram_wen_n,
    IO_sdram_dq => IO_sdram_dq,
    O_sdram_addr => O_sdram_addr,
    O_sdram_ba => O_sdram_ba,
    O_sdram_dqm => O_sdram_dqm,


    tmds_clk_p    => clk_p,
    tmds_clk_n    => clk_n,
    tmds_data_p   => data_p,
    tmds_data_n   => data_n

    );


--YM219 PSG and signals
psgBdir <= '1' when busAddress (7 downto 3) = "10100" and (ioWr_n='0') and busAddress(1)='0' else '0'; -- I/O:A0-A2h / PSG(AY-3-8910) bdir = 1 when writing to &HA0-&Ha1
psgBc1 <= '1' when busAddress (7 downto 3) = "10100" and ((ioRd_n='0' and busAddress(1)='1') or (busAddress(1)='0' and ioWr_n='0' and busAddress(0)='0')) else '0'; -- I/O:A0-A2h / PSG(AY-3-8910) bc1 = 1 when writing A0 or reading A2
psgPA<=(others=>'0');

psg1: YM2149
    port map (
        -- data bus
        I_DA        => busDataOut,
        O_DA        => psgDataOut,
        O_DA_OE_L   => open,
        -- control
        I_A9_L      => '0',
        I_A8        => '1',
        I_BDIR      => psgBdir,
        I_BC2       => '1',
        I_BC1       => psgBc1,
        I_SEL_L     => '1',
        
        O_AUDIO     => psgSound1,
        -- port a
        I_IOA       => psgPA,
        O_IOA       => open,
        O_IOA_OE_L  => open,
        -- port b
        I_IOB       => psgPB,
        O_IOB       => psgPB,
        O_IOB_OE_L  => open,
        
        ENA         => '1', -- clock enable for higher speed operation
        RESET_L     => busReset_n,
        CLK         => clk_1m8,
        clkHigh     => ex_clk_27m,
        debug       => psgDebug
    );


--opll and signals
opll_req  <=  '0' when( busIorq_n = '0' and busAddress(7 downto 1) = "0111110"  and ( busWr_n = '0') )else '1';    -- I/O:7C-7Dh   / OPLL (YM2413)
opll_mix <= ("00" & opll_mo) + ("00" & opll_ro) - "001000000000";
opll_wav <= opll_mix(9 downto 0) & "000000" & "0000000000000000";
audio_sample1 <= "000" & psgSound1 & "00000";
audio_sample2 <= '0' & opll_wav_filter(31) & opll_wav_filter(29 downto 16);
audio_sample <= audio_sample1 + audio_sample2;


opll1: opll
    port map(
        xin         => clk_3m6,
        xout        => open,
        xena        => '1',
        d           => busDataOut,
        a           => busAddress(0),
        cs_n        => opll_req,
        we_n        => '0',
        ic_n        => reset_n,
        mo          => opll_mo,
        ro          => opll_ro
    );


filtro_fm : fm_filter
    generic map (
        DATA_WIDTH => opll_wav'high + 1
    )
    port map(
        clk_3m6 => ex_clk_3m6,
        clk_27m => ex_clk_27m,
        reset => reset,
        data_in => opll_wav,
        data_out => opll_wav_filter
    );


--fm rom and signals
fmrom_read <= '1' when (busMreq_n='0' and bus_sltsl_n = '0' and busRd_n = '0' and busReset_n = '1') else '0';

process (ex_clk_27m, reset)
begin
    if reset = '1' then
        fmrom_counter <= (others => '0');
        fmrom_state <= "00";

    elsif rising_edge(ex_clk_27m) then
        case fmrom_state is
            when "00" =>
                if fmrom_read = '1' then
                    fmrom_state <= "01";
                end if;
            when "01" =>
                fmrom_counter <= fmrom_counter + 1;
                if fmrom_counter > 2 then
                    bus_data_reverse <= '1';
                    fmrom_state <= "10";
                end if;
            when "10" =>
                fmrom_counter <= (others => '0');
                if fmrom_read = '0' then
                    bus_data_reverse <= '0';
                    fmrom_state <= "00";
                end if;
            when others =>
                fmrom_state <= "00"; 
        
        end case;

    end if;
end process;

fmrom: ram_16kb
    port map
    (
        address => busAddress(13 downto 0),
        clock => clk_3m6,
        data => busDataOut,
        wren => '0',
        q => fmrom_dout
    );


denoise1: denoise_low
	port map (
		data_in => ex_busMreq_n,
		clock => ex_clk_27m,
		data_out => busMreq_n
	);

denoise2: denoise_low
	port map (
		data_in => ex_busIorq_n,
		clock => ex_clk_27m,
		data_out => busIorq_n
	);

denoise3: denoise_low
	port map (
		data_in => ex_busRd_n,
		clock => ex_clk_27m,
		data_out => busRd_n
	);

denoise4: denoise_low
	port map (
		data_in => ex_busWr_n,
		clock => ex_clk_27m,
		data_out => busWr_n
	);

denoise5: denoise_low
	port map (
		data_in => ex_busReset_n,
		clock => ex_clk_27m,
		data_out => busReset_n
	);

denoise6: denoise
	port map (
		data_in => ex_clk_3m6,
		clock => ex_clk_27m,
		data_out => clk_3m6
	);

denoise7: denoise_low
	port map (
		data_in => ex_bus_sltsl_n,
		clock => ex_clk_27m,
		data_out => bus_sltsl_n
	);

denoise8: denoise_8
    port map (
		data8_in    => ex_busAddress(7 downto 0),
		clock		=> ex_clk_27m,
		data8_out	=> busAddress(7 downto 0)
    );

denoise9: denoise_8
    port map (
		data8_in    => ex_busAddress(15 downto 8),
		clock		=> ex_clk_27m,
		data8_out	=> busAddress(15 downto 8)
    );

denoise10: denoise_8
    port map (
		data8_in    => ex_busDataOut,
		clock		=> ex_clk_27m,
		data8_out	=> busDataOut
    );

-- mono1 : monostable 
--    port map (
--		pulse_in    => fmrom_read,
--		clock       => ex_clk_27m,
--		pulse_out_n => ex_led
--	);

--ex_led <= not psgDebug(5 downto 0);
ex_led <= '0';


end;
