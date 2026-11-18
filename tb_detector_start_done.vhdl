library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_detector_start_done is
-- Entidade vazia
end tb_detector_start_done;

architecture Simulacao of tb_detector_start_done is

    component detector_start_done
        Port (
            clk    : in  STD_LOGIC;
            rst    : in  STD_LOGIC;
            start  : in  STD_LOGIC;
            din    : in  STD_LOGIC;
            fim    : in  STD_LOGIC;
            detect : out STD_LOGIC;
            done   : out STD_LOGIC
        );
    end component;

    signal clk    : STD_LOGIC := '0';
    signal rst    : STD_LOGIC := '0';
    signal start  : STD_LOGIC := '0';
    signal din    : STD_LOGIC := '0';
    signal fim    : STD_LOGIC := '0';
    signal detect : STD_LOGIC;
    signal done   : STD_LOGIC;

    constant clk_period : time := 10 ns;

    constant sequencia_teste_1  : std_logic_vector(0 to 5)  := "101101";
    constant sequencia_teste_2  : std_logic_vector(0 to 8)  := "000101101";
    constant sequencia_teste_3  : std_logic_vector(0 to 11) := "101100101101";  -- 1a tentativa falha (101100)
    constant sequencia_teste_4  : std_logic_vector(0 to 9)  := "1011101101";    -- 10111 volta para S1
    constant sequencia_teste_5  : std_logic_vector(0 to 16) := "10110010100101101";  -- varias tentativas falhas
    constant sequencia_teste_6  : std_logic_vector(0 to 11) := "111010110111";  -- sequencia no meio do fluxo
    constant sequencia_teste_7  : std_logic_vector(0 to 6)  := "1101101";       -- 11 antes da sequencia

    constant sequencia_teste_13 : std_logic_vector(0 to 15) := "1011010000000000";  -- cauda longa
    constant sequencia_teste_14 : std_logic_vector(0 to 11) := "101101101101";      -- 3 ocorrencias sobrepostas

    -- Fluxos sem 101101 (esperado: detect = '0')
    constant sequencia_teste_8  : std_logic_vector(0 to 3)  := "1011";          -- so o comeco
    constant sequencia_teste_9  : std_logic_vector(0 to 4)  := "10110";         -- falta 1 bit
    constant sequencia_teste_10 : std_logic_vector(0 to 14) := "111000110100111";
    constant sequencia_teste_11 : std_logic_vector(0 to 19) := "10101010101010101010";
    constant sequencia_teste_12 : std_logic_vector(0 to 9)  := "1011001101";    -- 101100 e depois 1101

begin

    DUT: detector_start_done port map (
        clk    => clk,
        rst    => rst,
        start  => start,
        din    => din,
        fim    => fim,
        detect => detect,
        done   => done
    );
    -- Clock
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Estimulos
    stim_proc : process

        procedure testa (seq : in std_logic_vector; nome : in string;
                         esperado : in std_logic; cedo : in boolean := false) is
            variable done_cedo : boolean := false;
        begin
            start <= '1';
            wait for clk_period * 2;

            -- Um bit por clock. Muda no flanco de descida, o DUT le no de subida.
            for i in seq'range loop
                wait until falling_edge(clk);
                if done = '1' then
                    done_cedo := true;     -- DUT ja encerrou a leitura
                end if;
                din <= seq(i);
                if i = seq'right then
                    fim <= '1';        -- ultimo bit do fluxo
                end if;
            end loop;
            wait until falling_edge(clk);
            fim <= '0';
            din <= '0';

            if done /= '1' then
                wait until done = '1' for clk_period * 10;
            end if;
            wait for clk_period * 2;

            -- Verifica o resultado
            if done /= '1' then
                report nome & ": FALHOU (done nao subiu)" severity error;
            elsif detect /= esperado then
                report nome & ": FALHOU (detect incorreto)" severity error;
            elsif done_cedo /= cedo then
                report nome & ": FALHOU (encerramento precoce: esperado "
                       & boolean'image(cedo) & ", obtido " & boolean'image(done_cedo) & ")"
                       severity error;
            else
                report nome & ": OK" severity note;
            end if;

            -- Desativa o start: o DUT volta para ESPERA_START
            start <= '0';
            wait for clk_period * 3;
        end procedure;

    begin
        rst <= '1';
        wait for clk_period * 2;
        rst <= '0';
        wait for clk_period * 2;

        -- Com 101101
        testa(sequencia_teste_1,  "Teste 1",  '1');
        testa(sequencia_teste_2,  "Teste 2",  '1');
        testa(sequencia_teste_3,  "Teste 3",  '1');
        testa(sequencia_teste_4,  "Teste 4",  '1');
        testa(sequencia_teste_5,  "Teste 5",  '1');
        testa(sequencia_teste_6,  "Teste 6",  '1', cedo => true);
        testa(sequencia_teste_7,  "Teste 7",  '1');

        -- Com 101101 no comeco e cauda: leitura encerrada antes do fim do fluxo
        testa(sequencia_teste_13, "Teste 13", '1', cedo => true);
        testa(sequencia_teste_14, "Teste 14", '1', cedo => true);

        -- Sem 101101
        testa(sequencia_teste_8,  "Teste 8",  '0');
        testa(sequencia_teste_9,  "Teste 9",  '0');
        testa(sequencia_teste_10, "Teste 10", '0');
        testa(sequencia_teste_11, "Teste 11", '0');
        testa(sequencia_teste_12, "Teste 12", '0');

        report "Fim dos testes" severity note;
        assert false report "Fim da simulacao" severity failure;
        wait;
    end process;

end Simulacao;