-- Solution for Advent of Code 2021, day 8

entity day_08 is
end entity;

use std.textio.all;

architecture simulation of day_08 is

    type string_vector is array (integer range <>) of string;

    constant EXAMPLE_INPUT : string_vector :=
    (
        "be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe",
        "edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc    ",
        "fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg         ",
        "fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb   ",
        "aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea   ",
        "fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb  ",
        "dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe  ",
        "bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef    ",
        "egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb       ",
        "gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce      "
    );

    subtype raw_digit_t is string(1 to 7);
    type raw_digit_with_length_t is record
        str : raw_digit_t;
        len : positive;
    end record;
    type signal_patterns_t is array(0 to 9) of raw_digit_with_length_t;
    type output_value_t is array(0 to 3) of raw_digit_with_length_t;
    type entry_t is record
        signal_patterns : signal_patterns_t;
        output_value    : output_value_t;
    end record;
    type entries_t is array(integer range <>) of entry_t;

    -- Decode input string into entry type
    function string_to_entry(
        str : string
    ) return entry_t is
        variable result           : entry_t;
        variable signal_pattern_i : natural;
        variable output_value_i   : natural;
        variable i_start          : integer;
        variable i_end            : integer;
        variable len              : positive;
    begin
        signal_pattern_i := 0;
        output_value_i   := 0;
        i_start          := str'left;
        for I in str'range loop
            if str(I) = ' ' and str(I - 1) /= '|' then
                -- Store digit string in corresponding vector
                if signal_pattern_i < signal_patterns_t'length then
                    len := i_end - i_start + 1;
                    -- Store string and length of signal pattern
                    result.signal_patterns(signal_pattern_i).str(1 to len) := (
                    str(i_start to i_end)
                    );
                    result.signal_patterns(signal_pattern_i).len := len;
                    signal_pattern_i                             := signal_pattern_i + 1;
                    i_start                                      := I + 1;
                elsif output_value_i < output_value_t'length then
                    len := i_end - i_start + 1;
                    -- Store string and length of output digit
                    result.output_value(output_value_i).str(1 to len) := (
                    str(i_start to i_end)
                    );
                    result.output_value(output_value_i).len := len;
                    output_value_i                          := output_value_i + 1;
                    i_start                                 := I + 1;
                end if;
            elsif str(I) = '|' then
                -- Skip pipe and successive space characters
                i_start := I + 2;
            else
                -- Advance end pointer to current non-delimiter
                i_end := I;
            end if;
        end loop;
        if str(str'right) /= ' ' then
            -- No padding after input, store last output digit as well.
            len := i_end - i_start + 1;
            -- Store string and corresponding length
            result.output_value(output_value_i).str(1 to len) := (
            str(i_start to i_end)
            );
            result.output_value(output_value_i).len := len;
        end if;
        return result;
    end function;

    -- Part One: Count unique output digits in given entries
    function count_unique_output_digits(
        entries : entries_t
    ) return natural is
        variable result : natural;
    begin
        result := 0;
        for ENTRY_INDEX in entries'range loop
            for DIGIT_INDEX in output_value_t'range loop
                case entries(ENTRY_INDEX).output_value(DIGIT_INDEX).len is
                    when 2 | 3 | 4 | 7 =>
                        -- Digit with unique length
                        result := result + 1;
                    when others =>
                        null;
                end case;
            end loop;
        end loop;
        return result;
    end function;

begin

    process
        variable example_entries : entries_t(EXAMPLE_INPUT'range);

        file i_file     : text;
        variable i_line : line;
        variable entry  : entry_t;

        type entries_ptr_t is access entries_t;
        variable input_entries_ptr     : entries_ptr_t;
        variable input_entries_ptr_old : entries_ptr_t;

        variable result : natural;
    begin
        -- Decode example lines
        for I in EXAMPLE_INPUT'range loop
            example_entries(I) := string_to_entry(EXAMPLE_INPUT(I));
        end loop;
        report "Number of entries in example input: " & integer'image(example_entries'length);

        -- Load entries from input file
        file_open(i_file, "inputs/day_08.txt", read_mode);
        while not endfile(i_file) loop
            readline(i_file, i_line);
            entry := string_to_entry(i_line.all);
            if input_entries_ptr = null then
                input_entries_ptr := new entries_t'(0 => entry);
            else
                input_entries_ptr_old := input_entries_ptr;
                input_entries_ptr     := new entries_t'(input_entries_ptr.all & entry);
                deallocate(input_entries_ptr_old);
            end if;
        end loop;
        file_close(i_file);
        report "Number of entries in input file: " & integer'image(input_entries_ptr'length);

        report "*** Part One ***";

        result := count_unique_output_digits(example_entries);
        report "Number of unique output digits in example input: " & integer'image(result);
        assert result = 26;

        result := count_unique_output_digits(input_entries_ptr.all);
        report "Number of unique output digits in input file: " & integer'image(result);
        assert result = 245;

        -- report "*** Part Two ***";

        deallocate(input_entries_ptr);
        wait;
    end process;

end architecture;