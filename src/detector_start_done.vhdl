library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity detector_start_done is
    Port ( 
        clk    : in  STD_LOGIC;
        rst    : in  STD_LOGIC;
        start  : in  STD_LOGIC;  -- Inicia o algoritmo
        din    : in  STD_LOGIC;
        detect : out STD_LOGIC;  -- Sinal de resultado
        done   : out STD_LOGIC   -- Sinaliza a conclusão do algoritmo
    );
end detector_start_done;

architecture RTL of detector_start_done is
    -- Estados mapeados diretamente do fluxograma fornecido
    type state_type is (
        ESPERA_START,   -- Aguardando START
        INICIALIZACAO,  -- Inicialização
        S0, S1, S2, S3, S4, S5, -- Processamento do algoritmo (Busca por 101101)
        RESULTADO,      -- Resultado
        ESTADO_DONE     -- DONE
    );
    signal estado_atual, proximo_estado : state_type;
    
begin

    -- Processo 1: Memória de Estado (Síncrono)
    process(clk, rst)
    begin
        if rst = '1' then
            estado_atual <= ESPERA_START;
        elsif rising_edge(clk) then
            estado_atual <= proximo_estado;
        end if;
    end process;

    -- Processo 2: Lógica de Transição de Estados (Combinacional)
    process(estado_atual, start, din)
    begin
        -- Valores padrão
        proximo_estado <= estado_atual;
        detect <= '0';
        done   <= '0';

        case estado_atual is
            
            -- [Bloco: START]
            when ESPERA_START => 
                if start = '1' then 
                    proximo_estado <= INICIALIZACAO; 
                end if;
                
            -- [Bloco: Inicialização]
            when INICIALIZACAO =>
                -- Prepara o sistema para iniciar a leitura. 
                -- Como não há contadores para zerar neste algoritmo, apenas avança.
                proximo_estado <= S0;
                
            -- [Bloco: Processamento do algoritmo]
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
                if din = '1' then 
                    proximo_estado <= RESULTADO; -- Sequência "101101" encontrada
                else 
                    proximo_estado <= S0; 
                end if;
                
            -- [Bloco: Resultado]
            when RESULTADO =>
                detect <= '1'; -- Gera a indicação de detecção
                proximo_estado <= ESTADO_DONE;
                
            -- [Bloco: DONE]
            when ESTADO_DONE =>
                done <= '1'; -- Sinaliza a conclusão por meio de done
                
                -- Protocolo de Handshake: Aguarda o sinal 'start' ser desativado 
                -- pelo sistema mestre antes de voltar ao estado de espera, 
                -- garantindo que o algoritmo não reinicie acidentalmente.
                if start = '0' then
                    proximo_estado <= ESPERA_START;
                end if;
                
        end case;
    end process;

end RTL;