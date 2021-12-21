-- Solution for Advent of Code 2021, day 10

entity day_10 is
end entity;

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture simulation of day_10 is

    type string_vector is array (natural range <>) of string;

    constant EXAMPLE_INPUT : string_vector :=
    (
        "[({(<(())[]>[[{[]{<()<>>",
        "[(()[<>])]({[<{<<[]>>(  ",
        "{([(<{}[<>[]}>{[]{[(<()>",
        "(((({<>}<{<{<>}{[]{[]{} ",
        "[[<[([]))<([[{}[[()]]]  ",
        "[{[{({}]{}}([{[{{{}}([] ",
        "{<[[]]>}<{[{[{[]{()[[[] ",
        "[<(<(<(<{}))><([]([]()  ",
        "<{([([[(<>()){}]>(<<{{  ",
        "<{([{{}}[<[[[<>{}]]]>[]]"
    );

    type mode_t is (CORRUPTED, INCOMPLETE);
    subtype unsigned64_t is unsigned(63 downto 0);

    -- Calculate line score of given string.
    function calculate_line_score(
        str  : string;
        mode : mode_t
    ) return unsigned64_t is
        variable stack              : string(str'range);
        variable stack_index        : integer range stack'range;
        variable close_matching     : character;
        variable corrupted_score    : natural;
        variable autocomplete_score : unsigned64_t;
    begin
        for I in str'range loop
            close_matching := NUL;
            case str(I) is
                when '(' | '[' | '{' | '<' =>
                    -- Add opening bracket to stack.
                    stack(stack_index) := str(I);
                    stack_index        := stack_index + 1;
                when ')' =>
                    close_matching  := '(';
                    corrupted_score := 3;
                when ']' =>
                    close_matching  := '[';
                    corrupted_score := 57;
                when '}' =>
                    close_matching  := '{';
                    corrupted_score := 1197;
                when '>' =>
                    close_matching  := '<';
                    corrupted_score := 25137;
                when others =>
                    null;
            end case;
            if close_matching /= NUL then
                if stack_index = stack'left or stack(stack_index - 1) /= close_matching then
                    -- Invalid closing bracket, line is corrupted.
                    if mode = CORRUPTED then
                        return to_unsigned(corrupted_score, unsigned64_t'length);
                    else
                        return (others => '0');
                    end if;
                end if;
                -- Decrease stack index.
                stack_index := stack_index - 1;
            end if;
        end loop;
        autocomplete_score := (others => '0');
        if mode = INCOMPLETE and stack_index > 1 then
            -- Calculate autocomplete score from remaining stack content.
            for I in stack_index - 1 downto 1 loop
                autocomplete_score := resize(5 * autocomplete_score, unsigned64_t'length);
                case stack(I) is
                    when '('    => autocomplete_score := autocomplete_score + 1;
                    when '['    => autocomplete_score := autocomplete_score + 2;
                    when '{'    => autocomplete_score := autocomplete_score + 3;
                    when '<'    => autocomplete_score := autocomplete_score + 4;
                    when others => null;
                end case;
            end loop;
        end if;
        return autocomplete_score;
    end function;

    -- Calculate syntax error score of given lines.
    function calculate_syntax_error_score(
        lines : string_vector
    ) return natural is
        variable score : natural;
    begin
        score := 0;
        for I in lines'range loop
            score := score + to_integer(calculate_line_score(lines(I), CORRUPTED));
        end loop;
        return score;
    end function;

    -- Calculate autocomplete score of given lines.
    function calculate_autocomplete_score(
        lines : string_vector
    ) return unsigned64_t is
        type unsigned64_vector_t is array (natural range <>) of unsigned64_t;
        variable scores       : unsigned64_vector_t(lines'range);
        variable num_non_zero : natural;
        variable num_larger   : natural;
    begin
        -- Get scores of all lines.
        for I in lines'range loop
            scores(I) := calculate_line_score(lines(I), INCOMPLETE);
            if scores(I) > 0 then
                num_non_zero := num_non_zero + 1;
            end if;
        end loop;
        -- Return middle score.
        for I in scores'range loop
            if scores(I) /= 0 then
                -- Count number of scores larger than this one.
                num_larger := 0;
                for J in scores'range loop
                    if scores(J) > scores(I) then
                        num_larger := num_larger + 1;
                    end if;
                end loop;
                -- This is the middle score if half of non-zeros are larger.
                if num_larger = num_non_zero / 2 then
                    return scores(I);
                end if;
            end if;
        end loop;
        return (others => '0');
    end function;

begin

    process
        type string_vector_ptr_t is access string_vector;
        variable string_vector_ptr : string_vector_ptr_t;

        file i_file              : text;
        variable i_line          : line;
        variable max_line_length : natural;
        variable number_of_lines : natural;
        variable line_index      : natural;

        variable result     : natural;
        variable result_u64 : unsigned64_t;
    begin
        report ("Number of lines in example input: " & integer'image(EXAMPLE_INPUT'length));

        -- Find out maximum line length and number of lines
        max_line_length := 0;
        number_of_lines := 0;
        file_open(i_file, "inputs/day_10.txt", read_mode);
        while not endfile(i_file) loop
            number_of_lines := number_of_lines + 1;
            readline(i_file, i_line);
            if i_line'length > max_line_length then
                max_line_length := i_line'length;
            end if;
        end loop;
        file_close(i_file);
        -- Read lines from input file
        string_vector_ptr := new string_vector(0 to number_of_lines - 1)(1 to max_line_length);
        line_index        := 0;
        file_open(i_file, "inputs/day_10.txt", read_mode);
        while not endfile(i_file) loop
            readline(i_file, i_line);
            string_vector_ptr(line_index)(1 to i_line'length) := i_line.all;
            line_index                                        := line_index + 1;
        end loop;
        file_close(i_file);

        report ("Number of lines in input file: " & integer'image(string_vector_ptr'length));

        report "*** Part One ***";

        result := calculate_syntax_error_score(EXAMPLE_INPUT);
        report "Total syntax error score for example input: " & integer'image(result);
        assert result = 26397;

        result := calculate_syntax_error_score(string_vector_ptr.all);
        report "Total syntax error score for input file: " & integer'image(result);
        assert result = 290691;

        report "*** Part Two ***";

        result_u64 := calculate_autocomplete_score(EXAMPLE_INPUT);
        report "Autocomplete score for example input: 0x" & to_hstring(result_u64);
        assert result_u64 = 288957;

        result_u64 := calculate_autocomplete_score(string_vector_ptr.all);
        report "Autocomplete score for input file: 0x" & to_hstring(result_u64);
        assert result_u64 = d"2768166558";

        deallocate(string_vector_ptr);
        wait;
    end process;

end architecture;