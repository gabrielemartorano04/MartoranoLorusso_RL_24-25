-- Prova finale - Progetto di reti logiche
-- Luca Lorusso (10831296), Gabriele Martorano (10822443)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
        i_clk      : in  std_logic;
        i_rst      : in  std_logic;
        i_start    : in  std_logic;
        i_add      : in  std_logic_vector(15 downto 0);
        o_done     : out std_logic;
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in  std_logic_vector(7 downto 0);
        o_mem_data : out std_logic_vector(7 downto 0);
        o_mem_we   : out std_logic;
        o_mem_en   : out std_logic
    );
end project_reti_logiche;

architecture FSM of project_reti_logiche is
    
    -- FSM signals
    type state_type is (INIT, CONFIG, READ, FILTER, WRITE, DONE, WAIT_START);
    signal current_state, next_state : state_type;

begin
      
    -- FSM
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            current_state <= INIT;
            o_done <= '0';
        elsif rising_edge(i_clk) then
            current_state <= next_state;
            if current_state = DONE then
                o_done <= '1';
            elsif current_state = WAIT_START then
                o_done <= '0';
            end if;
        end if;
    end process;

    -- Next state logic
    process(current_state, i_clk)
    
    variable s: std_logic;
    variable k: std_logic_vector(15 downto 0);
    variable sum, r : std_logic_vector(17 downto 0);
    variable c0, c1, c2, c3, c4, c5, c6: std_logic_vector(7 downto 0);  
    variable w: std_logic_vector(55 downto 0);  
    variable index, step: integer;
    
    begin
    if rising_edge(i_clk) then
        next_state <= current_state;
        case current_state is
        
            when INIT =>
                o_done <= '0';
                if i_start = '1'  then
                    index := 0;
                    step := 0;
                    w := (others => '0');
                    o_mem_en <= '1';
                    o_mem_we <= '0';
                    o_mem_addr <= std_logic_vector(unsigned(i_add));
                    next_state <= CONFIG;
                else
                    next_state <= INIT;
                end if;

            -- Lettura Configurazione (K, S, C0-C6)
            when CONFIG =>
                case step is
                    when 0 =>
                        step := 1;
                    when 1 =>
                        k(15 downto 8) := i_mem_data; 
                        o_mem_addr <= std_logic_vector(unsigned(i_add) + 1); -- Legge K2
                        step := 2;
                    when 2 =>
                        step := 3;
                    when 3 =>
                        k(7 downto 0) := i_mem_data;
                        o_mem_addr <= std_logic_vector(unsigned(i_add) + 2); -- Legge S
                        step := 4;
                    when 4 =>
                        step := 5;
                    when 5 => 
                        s := i_mem_data(0);
                        if s = '0' then
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 3); -- Legge C0
                        else
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 10); -- Legge C0 (S=1)
                        end if;
                        step := 6;
                    when 6 =>
                        step := 7;
                    when 7 =>
                        c0 := i_mem_data;
                        if s = '0' then
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 4);
                        else
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 11);
                        end if;
                        step := 8;
                    when 8 => 
                        step := 9;
                    when 9 =>
                        c1 := i_mem_data;
                        if s = '0' then
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 5);
                        else
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 12);
                        end if;
                        step := 10;
                    when 10 =>
                        step := 11;
                    when 11 => 
                        c2 := i_mem_data;
                        if s = '0' then
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 6);
                        else
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 13);
                        end if;
                        step := 12;
                    when 12 => 
                        step := 13;
                    when 13 =>
                        c3 := i_mem_data;
                        if s = '0' then
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 7);
                        else
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 14);
                        end if;
                        step := 14;
                    when 14 => 
                        step := 15;
                    when 15 =>
                        c4 := i_mem_data;
                        if s = '0' then
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 8);
                        else
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 15);
                        end if;
                        step := 16;
                    when 16 => 
                        step := 17;
                    when 17 =>
                        c5 := i_mem_data;
                        if s = '0' then
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 9);
                        else
                            o_mem_addr <= std_logic_vector(unsigned(i_add) + 16);
                        end if;
                        step := 18;
                    when 18 => 
                        step := 19;
                    when 19 =>
                        c6 := i_mem_data;
                        step := 20;
                    when others =>
                        o_mem_addr <= std_logic_vector(unsigned(i_add) + 17 + index);
                        next_state <= READ;
                end case;


            -- Lettura Finestra (w0-w6)
            when READ =>
            if step = 20 then
                step := 0;
            end if;
            o_mem_we <= '0';
                case step is
                    when 0 =>
                        step := 1;
                    when 1 =>
                        w(31 downto 24) := i_mem_data;
                        o_mem_addr <= std_logic_vector(unsigned(i_add) + 17 + index + 1);                    
                        step := 2;
                    when 2 =>
                        step := 3;
                    when 3 =>
                        w(23 downto 16) := i_mem_data;
                        o_mem_addr <= std_logic_vector(unsigned(i_add) + 17 + index + 2);                    
                        step := 4;
                    when 4 =>
                        step := 5;
                    when 5 =>
                        w(15 downto 8) := i_mem_data;
                        o_mem_addr <= std_logic_vector(unsigned(i_add) + 17 + index + 3);                    
                        step := 6;
                    when 6 =>
                        step := 7;
                    when 7 =>
                        w(7 downto 0) := i_mem_data;
                        step := 12;
                    when 8 =>
                        w := std_logic_vector(shift_left(signed(w), 8));
                        o_mem_addr <= std_logic_vector(unsigned(i_add) + 17 + index + 3);
                        step := 9;
                    when 9 =>
                        step := 10;
                    when 10 =>
                        w(7 downto 0) := i_mem_data;
                        step := 12;
                    when 11 =>
                        w := std_logic_vector(shift_left(unsigned(w), 8));
                        step := 12;
                    when others =>
                        o_mem_en <= '0';
                        next_state <= FILTER;
                end case;
            
            -- Filtraggio
            when FILTER =>
                case step is
                    when 12 =>
                         if s = '0' then
                            sum := std_logic_vector(resize(signed(w(15 downto 8))*signed(c5), 18) + 
                                                    resize(signed(w(23 downto 16))*signed(c4), 18) + 
                                                    resize(signed(w(31 downto 24))*signed(c3), 18) + 
                                                    resize(signed(w(39 downto 32))*signed(c2), 18) + 
                                                    resize(signed(w(47 downto 40))*signed(c1), 18)); 
                        else
                            sum := std_logic_vector(resize(signed(w(7 downto 0))*signed(c6), 18) + 
                                                    resize(signed(w(15 downto 8))*signed(c5), 18) + 
                                                    resize(signed(w(23 downto 16))*signed(c4), 18) + 
                                                    resize(signed(w(31 downto 24))*signed(c3), 18) + 
                                                    resize(signed(w(39 downto 32))*signed(c2), 18) + 
                                                    resize(signed(w(47 downto 40))*signed(c1), 18) + 
                                                    resize(signed(w(55 downto 48))*signed(c0), 18));
                        end if;
                        step := 13;
                    when 13 =>
                        if s = '0' then
                            if to_integer(signed(sum)) < 0 then
                                r := std_logic_vector(shift_right(signed(sum), 4) + 
                                                      shift_right(signed(sum), 6) + 
                                                      shift_right(signed(sum), 8) + 
                                                      shift_right(signed(sum), 10) + 
                                                      to_signed(4, r'length));
                            else
                                r := std_logic_vector(shift_right(signed(sum), 4) + 
                                                      shift_right(signed(sum), 6) + 
                                                      shift_right(signed(sum), 8) + 
                                                      shift_right(signed(sum), 10));
                            end if;
                        else
                            if to_integer(signed(sum)) < 0 then
                                r := std_logic_vector(shift_right(signed(sum), 6) +  
                                                      shift_right(signed(sum), 10) + 
                                                      to_signed(2, r'length));
                            else
                                r := std_logic_vector(shift_right(signed(sum), 6) + 
                                                      shift_right(signed(sum), 10));
                            end if;
                        end if;
                        if signed(r) > to_signed(127, r'length) then
                            r := std_logic_vector(to_signed(127, r'length));
                        elsif signed(r) < to_signed(-128, r'length) then
                            r := std_logic_vector(to_signed(-128, r'length));
                        end if;
                        step := 14;
                    when others =>
                        next_state <= WRITE;
                end case;
                
            -- Scrittura
            when WRITE =>
                case step is 
                    when 14 =>
                        o_mem_addr <= std_logic_vector(unsigned(i_add) + 17 + unsigned(k) + index);
                        o_mem_data <= r(7 downto 0);
                        o_mem_en <= '1';
                        o_mem_we <= '1';
                        
                        if index >= to_integer(unsigned(k)) - 4 and index < to_integer(unsigned(k)) - 1 then
                            step := 11;
                            index := index + 1;
                        elsif index = to_integer(unsigned(k)) - 1 then
                            step := 0;
                        else
                            step := 8;
                            index := index + 1;
                        end if;
                    when others =>
                        if step = 0 then
                            next_state <= DONE;
                        elsif step = 8 or step = 11 then
                            next_state <= READ;
                        end if;
                end case;

            -- Stato Finale
            when DONE =>
                o_mem_en <= '0';
                o_mem_we <= '0';
                o_done <= '1';
                next_state <= WAIT_START;

            -- Stato Attesa                                                
            when WAIT_START =>
                if i_start = '0' then
                    o_done <= '0';
                    next_state <= INIT;
                end if;

        end case;
    end if;
    end process;

end FSM;
