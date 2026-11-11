library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_detector_start_done is
-- Entidade vazia
end tb_detector_start_done;

architecture Simulacao of tb_detector_start_done is

    -- Declaração do DUT (Device Under Test)
    component detector_start_done
        Port ( 
            clk    : in  STD_LOGIC;
            rst    : in  STD_LOGIC;
            start  : in  STD_LOGIC;
            din    : in  STD_LOGIC;
            detect : out STD_LOGIC;
            done   : out STD_LOGIC
        );
    end component;

    -- Sinais internos de simulação
    signal clk    : STD_LOGIC := '0';
    signal rst    : STD_LOGIC := '0';
    signal start  : STD_LOGIC := '0';
    signal din    : STD_LOGIC := '0';
    signal detect : STD_LOGIC;
    signal done   : STD_LOGIC;

    constant clk_period : time := 10 ns;
    constant sequencia_teste : std_logic_vector(0 to 10) := "10110101101";

begin

    -- Instanciação do módulo
    DUT: detector_start_done port map (
        clk    => clk,
        rst    => rst,
        start  => start,
        din    => din,
        detect => detect,
        done   => done
    );

    -- Processo de geração do clock
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Processo de injeção de estímulos
    stim_proc: process
    begin
        -- 1. Reset inicial
        rst <= '1';
        start <= '0';
        din <= '0';
        wait for clk_period * 2;
        
        rst <= '0';
        wait for clk_period * 2;

        -- 2. Ativa o START para iniciar a máquina
        start <= '1';
        wait for clk_period;

        -- 3. Injeta a sequência bit a bit
        -- Nota: A injeção continua, mas a FSM irá parar de processar 
        -- novos bits assim que chegar no estado DONE.
        for i in sequencia_teste'range loop
            wait until falling_edge(clk);
            din <= sequencia_teste(i);
            
            -- Se o sistema sinalizou 'done', paramos de injetar a sequência
            if done = '1' then
                exit; -- Sai do loop de injeção de bits
            end if;
        end loop;

        -- 4. Aguarda a FSM estabilizar no estado DONE caso ainda não tenha chegado
        if done = '0' then     
            wait until done = '1';
        end if;

        wait for clk_period * 2;

        -- 5. Finaliza o Handshake desativando o START
        -- O sistema deve voltar ao estado ESPERA_START
        start <= '0';
        wait for clk_period * 3;

        -- Simulação concluída
        report "Teste com Start/Done finalizado." severity note;
        assert false report "Fim da simulacao" severity failure;
        wait;
    end process;

end Simulacao;