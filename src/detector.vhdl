library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity detector is
    Port (
        clk     : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        start   : in  STD_LOGIC;               -- Sinal para iniciar o algoritmo
        
        entrada : in  STD_LOGIC_VECTOR(5 downto 0);
        detectou: out STD_LOGIC;
        
        ready   : out STD_LOGIC                -- Sinaliza que o resultado está pronto
    );
end detector;

architecture comportamental of detector is
begin
end