-- Controller for the one-shot I2C master.
-- This is mostly a state machine used to control
-- the various muxes and registers used for the I2C
-- device.
-- Author: Kevin Johnson.  Last modified: 2023

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity i2c_oneshot_ctrl is

	port(
		resetn          : in  std_logic;
		clk             : in  std_logic;
		i2c_busy        : in  std_logic;
		tx_addr         : out std_logic_vector(7 downto 0);
		tx_byte         : out std_logic_vector(7 downto 0);
		comm_en         : out std_logic
	);
	
end entity;

architecture main of i2c_oneshot_ctrl is

	-- Build an enumerated type for the state machine
	type state_type is (delay, idle, Tx2, Tx1);
	-- Register used to hold the current state
	signal state   : state_type;
	
	type	register_array	is array(8 downto 0) of std_logic_vector(15 downto 0);
	signal	commands : register_array;
	signal	cmd_num	: integer range 0 to 9;	
	
	signal go      : std_logic;  -- tells state machine when to leave idle
	signal prev_busy : std_logic;  -- previous value of i2c_busy
	
begin

	tx_addr <= x"34";  -- set the I2C controller's address
	commands(0) <= 
		std_logic_vector(to_unsigned(2#0001111_000000000#, 16));  -- full reset
	commands(1) <= 
		std_logic_vector(to_unsigned(2#0000111_001010011#, 16));  -- dsp master, 16-bit, data on 2nd clock
	commands(2) <= 
		std_logic_vector(to_unsigned(2#0001000_000000001#, 16));  -- usb mode, 48khz sampling
	commands(3) <= 
		std_logic_vector(to_unsigned(2#0001001_000000001#, 16));  -- activate digital interface
	commands(4) <= 
		std_logic_vector(to_unsigned(2#0000010_100000000#, 16));  -- headphone mute
	commands(5) <= 
		std_logic_vector(to_unsigned(2#0000100_000000100#, 16));  -- enable mic to adc, unmute mic, no boost
	commands(6) <= 
		std_logic_vector(to_unsigned(2#0000000_100000011#, 16));  -- unmute line-in, high attenuation
	commands(7) <= 
		std_logic_vector(to_unsigned(2#0000110_001111001#, 16));  -- power up adc and mic, powerdown everything else

	
	-- The main state machine
	state_machine : process (clk, resetn)
	begin
		if resetn = '0' then
			state <= delay;
			comm_en <= '0';
			cmd_num <= 9;

		elsif (rising_edge(clk)) then
			prev_busy <= i2c_busy;  -- used to detect transitions
			case state is
			
				when delay => -- necessary for the controller to initialize
					if cmd_num = 0 then
						state <= idle;
					else
						cmd_num <= cmd_num - 1;
					end if;
					
				when idle =>
					if cmd_num <= 7 then -- Send this many commands
						state <= Tx2;
						tx_byte <= commands(cmd_num)(15 downto 8);
					else -- not starting
						state <= idle;
					end if;
						
				
				when Tx2 => 
					comm_en <= '1'; -- safe to start transaction
					if (prev_busy = '0') and (i2c_busy = '1') then -- busy just went high
						tx_byte <= commands(cmd_num)(7 downto 0); -- prepare next byte
					elsif (prev_busy = '1') and (i2c_busy = '0') then -- just went low
						state <= Tx1;
					end if;
					
				when Tx1 => 
					if (prev_busy = '0') and (i2c_busy = '1') then -- busy just went high
						comm_en <= '0'; -- end communication
					elsif (prev_busy = '1') and (i2c_busy = '0') then -- just went low
						state <= idle;
						cmd_num <= cmd_num + 1;
					end if;
										
					
				when others =>
					state <= idle;
					
			end case;
		end if;
	end process;

			
end main;
