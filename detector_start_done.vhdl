library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity detector_start_done is
    Port (
        clk    : in  STD_LOGIC;
        rst    : in  STD_LOGIC;
        start  : in  STD_LOGIC;  -- inicia o algoritmo
        din    : in  STD_LOGIC;  -- fluxo de entrada, 1 bit por clock
        fim    : in  STD_LOGIC;  -- '1' junto com o ultimo bit do fluxo
        detect : out STD_LOGIC;  -- '1' se a sequencia 101101 apareceu
        done   : out STD_LOGIC   -- '1' quando terminou de processar o fluxo
    );
end detector_start_done;

architecture RTL of detector_start_done is
    type state_type is (
        ESPERA_START,
        INICIALIZACAO,
        S0, S1, S2, S3, S4, S5,   -- processamento: procura 101101
        RESULTADO,
        ESTADO_DONE
    );
    signal estado_atual, proximo_estado : state_type;
    signal achou : STD_LOGIC;     -- guarda se a sequencia ja apareceu

begin

    -- Registradores: estado da FSM e flag achou
    process(clk, rst)
    begin
        if rst = '1' then
            estado_atual <= ESPERA_START;
            achou <= '0';
        elsif rising_edge(clk) then
            estado_atual <= proximo_estado;
            if estado_atual = INICIALIZACAO then
                achou <= '0';                  -- nova busca, zera o flag
            elsif estado_atual = S5 and din = '1' then
                achou <= '1';                  -- completou 101101
            end if;
        end if;
    end process;

    detect <= achou;

    -- Proximo estado e saida done
    process(estado_atual, start, din, fim)
    begin
        proximo_estado <= estado_atual;
        done <= '0';

        case estado_atual is

            when ESPERA_START =>
                if start = '1' then
                    proximo_estado <= INICIALIZACAO;
                end if;

            when INICIALIZACAO =>
                proximo_estado <= S0;

            when S0 =>
                if din = '1' then proximo_estado <= S1; else proximo_estado <= S0; end if;
            when S1 =>
                if din = '0' then proximo_estado <= S2; else proximo_estado <= S1; end if;
            when S2 =>
                if din = '1' then proximo_estado <= S3; else proximo_estado <= S0; end if;
            when S3 =>
                if din = '1' then proximo_estado <= S4; else proximo_estado <= S2; end if;
            when S4 =>
                if din = '0' then proximo_estado <= S5; else proximo_estado <= S1; end if;
            when S5 =>
                -- com din = '1' achou a sequencia: encerra a leitura agora,
                -- sem esperar o fim do fluxo (o flag achou e gravado neste mesmo clock)
                if din = '1' then proximo_estado <= RESULTADO; else proximo_estado <= S0; end if;

            when RESULTADO =>
                -- o resultado ja esta no flag achou
                proximo_estado <= ESTADO_DONE;

            when ESTADO_DONE =>
                done <= '1';
                -- so volta a esperar quando o start for desativado
                if start = '0' then
                    proximo_estado <= ESPERA_START;
                end if;

        end case;

        -- Ultimo bit do fluxo: depois de processar ele, vai para o resultado
        if fim = '1' and estado_atual >= S0 and estado_atual <= S5 then
            proximo_estado <= RESULTADO;
        end if;
    end process;

end RTL;