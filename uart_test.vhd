library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_test is
  port(
    clk,rst : in std_logic;
	pin_tx : out std_logic
	LED0 : out std_logic
  );
end uart_test;

architecture arch of uart_test is

signal iniciar_tx, tx_ok, tick_baudio, bandera_sec : std_logic;
signal byte_tx : std_logic_vector(7 downto 0);
signal contador_tick_sec : integer range 0 to 12000000;
constant limite_sec : integer:=1200000;

type tipo_estado_uart is (idle,carga_byte,espera_tx);
signal estado_actual_uart, estado_sig_uart : tipo_estado_uart;

type tipo_registro_file is array(4 downto 0) of std_logic_vector(7 downto 0);
signal array_reg : tipo_registro_file;

--insertamos componente uart_tx
component uart_tx is
   generic(
      DBIT: integer:=8;     -- # data bits
      SB_TICK: integer:=16  -- # ticks for stop bits
   );
   port(
      clk, reset: in std_logic;
      tx_start: in std_logic;
      s_tick: in std_logic;
      din: in std_logic_vector(7 downto 0);
      tx_done_tick: out std_logic;
      tx_out: out std_logic
   );
end component;

component mod_m_counter is
   generic(
      N: integer := 8;     -- number of bits
      M: integer := 78     -- mod-M
  );
   port(
      clk, reset: in std_logic;
      max_tick: out std_logic;
      q: out std_logic_vector(N-1 downto 0)
   );
end component;

begin

  -- instancia a los componentes bajo test
  uut_1: uart_tx
    port map(
        din => byte_tx,
        tx_out => pin_tx,
        s_tick => tick_baudio,
        tx_done_tick => tx_ok,
        tx_start => iniciar_tx,
        clk => clk,
        reset => rst	    
	  );

   uut_2: mod_m_counter
     port map(
	   clk => clk,
	   reset => rst,
	   max_tick => tick_baudio
	 );   
 

LED0 <= rst; 
 
process(clk,rst)
begin
  if(rst='0')then
    estado_actual_uart <= idle;
    contador_tick_sec <= 0;
	bandera_sec<='0';
  elsif(clk'event and clk='1')then
    estado_actual_uart <= estado_sig_uart;
    if(contador_tick_sec < limite_sec)then
      contador_tick_sec <= contador_tick_sec + 1;
	  bandera_sec<='0';
	else 
	  contador_tick_sec <= 0;
	  bandera_sec<='1';
	end if;    
  end if;
end process;
  
--logica del estado siguiente
process(estado_actual_uart,tx_ok,bandera_sec)
begin
  estado_sig_uart <= estado_actual_uart;
  case estado_actual_uart is   
   
    when idle =>
      --contador <= "00110001001100100011001100110100";
      iniciar_tx <= '0';      	  
	  if(bandera_sec='1')then
	    estado_sig_uart <= carga_byte;
	  end if;
	  
	when carga_byte =>
	  byte_tx <= "00111001";
	  iniciar_tx <= '1';
	  if(tx_ok='0')then
	    estado_sig_uart <= espera_tx;
	  end if;
	  
	when espera_tx =>
	  if(tx_ok='1')then
	    estado_sig_uart <= idle;
	  end if;
	  
  end case;
end process;
  
end arch;
