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

    -- Conta os ciclos de clock com detect = '1' (ver processo monitor_proc)
    signal cnt_detect : integer := 0;

    constant clk_period : time := 10 ns;

    -- O DUT procura a sub-sequência "101101".

    -- Sequência apenas com um prefixo do padrão (esperado: done = '0')
    constant sequencia_teste    : std_logic_vector(0 to 3)  := "1011"; 

    -- Sequências que contêm "101101" (esperado: done = '1' e 1 pulso de detect)
    constant sequencia_teste_2  : std_logic_vector(0 to 5)  := "101101";
    constant sequencia_teste_3  : std_logic_vector(0 to 8)  := "000101101";
    constant sequencia_teste_4  : std_logic_vector(0 to 11) := "101100101101";  -- 1ª tentativa falha ("101100")
    constant sequencia_teste_5  : std_logic_vector(0 to 9)  := "1011101101";  -- "10111": S4 -> S1; padrão só no último bit
    constant sequencia_teste_6  : std_logic_vector(0 to 16) := "10110010100101101";  -- falhas em cadeia (S5->S0, S3->S2, S2->S0); padrão só no último bit
    constant sequencia_teste_7  : std_logic_vector(0 to 11) := "111010110111";

    -- Sequências SEM "101101" (esperado: done = '0' e nenhum pulso de detect)
    constant sequencia_teste_8  : std_logic_vector(0 to 4)  := "10110";  -- falta 1 bit para completar o padrão
    constant sequencia_teste_9  : std_logic_vector(0 to 14) := "111000110100111";
    constant sequencia_teste_10 : std_logic_vector(0 to 19) := "10101010101010101010";

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
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Monitor do sinal detect: conta um ciclo por borda de subida com detect = '1'.
    -- Um pulso de 1 ciclo conta 1; um pulso mais longo contaria mais.
    monitor_proc : process(clk)
    begin
        if rising_edge(clk) and detect = '1' then
            cnt_detect <= cnt_detect + 1;
        end if;
    end process;

    -- Processo de injeção de estímulos
    stim_proc: process

        -- Executa um teste completo (passos 1 a 5) para a sequência recebida.
        --   seq      : sequência a injetar bit a bit
        --   num      : número do teste (apenas para as mensagens)
        --   esperado : TRUE se a sequência deve levar a done = '1'
        procedure executa_teste (
            constant seq      : in std_logic_vector;
            constant num      : in integer;
            constant esperado : in boolean
        ) is
            variable cnt_ini : integer;
            variable pulsos  : integer;
        begin
            report "Teste " & integer'image(num) & ": a iniciar." severity note;
            cnt_ini := cnt_detect;  -- pulsos de detect contados antes deste teste

            -- 1. Reset inicial (também deixa o DUT limpo entre testes)
            rst   <= '1';
            start <= '0';
            din   <= '0';
            wait for clk_period * 2;
            rst   <= '0';
            wait for clk_period * 2;

            -- 2. Ativa o START para iniciar a máquina
            -- São precisos 2 flancos de subida até a FSM chegar a S0:
            -- ESPERA_START -> INICIALIZACAO -> S0. Se o primeiro bit fosse
            -- injetado antes disso, seria ignorado pelo estado INICIALIZACAO.
            start <= '1';
            wait for clk_period * 2;

            -- 3. Injeta a sequência bit a bit
            -- Nota: A injeção continua, mas a FSM irá parar de processar 
            -- novos bits assim que chegar no estado DONE.
            for i in seq'range loop
                wait until falling_edge(clk);
                din <= seq(i);
                -- Se o sistema sinalizou 'done', paramos de injetar a sequência
                if done = '1' then
                    exit; -- Sai do loop de injeção de bits
                end if;
            end loop;

            -- 4. Aguarda a FSM estabilizar no estado DONE caso ainda não tenha chegado.
            -- Com timeout: nas sequências sem detecção o done nunca sobe,
            -- e sem o timeout a simulação ficaria bloqueada aqui.
            if done = '0' then     
                wait until done = '1' for clk_period * 4;
            end if;

            wait for clk_period * 2;

            -- Verificação do resultado (done e nº de pulsos de detect)
            pulsos := cnt_detect - cnt_ini;
            if (done = '1') /= esperado then
                report "Teste " & integer'image(num) & ": FALHOU (done = '" &
                       std_logic'image(done) & "' ; esperado = " &
                       boolean'image(esperado) & ")" severity error;
            elsif (esperado and pulsos /= 1) or ((not esperado) and pulsos /= 0) then
                report "Teste " & integer'image(num) & ": FALHOU (detect gerou " &
                       integer'image(pulsos) & " pulso(s))" severity error;
            else
                report "Teste " & integer'image(num) & ": OK." severity note;
            end if;

            -- 5. Finaliza o Handshake desativando o START
            -- O sistema deve voltar ao estado ESPERA_START
            start <= '0';
            wait for clk_period * 3;
        end procedure;

    begin

        -- Apenas prefixo do padrão
        executa_teste(sequencia_teste,    1,  false);

        -- Sequências que contêm "101101"
        executa_teste(sequencia_teste_2,  2,  true);
        executa_teste(sequencia_teste_3,  3,  true);
        executa_teste(sequencia_teste_4,  4,  true);
        executa_teste(sequencia_teste_5,  5,  true);
        executa_teste(sequencia_teste_6,  6,  true);
        executa_teste(sequencia_teste_7,  7,  true);

        -- Sequências que NÃO contêm "101101"
        executa_teste(sequencia_teste_8,  8,  false);
        executa_teste(sequencia_teste_9,  9,  false);
        executa_teste(sequencia_teste_10, 10, false);

        -- Simulação concluída
        report "Teste com Start/Done finalizado." &
        assert false report "Fim da simulacao" severity failure;
        wait;
    end process;

end Simulacao;