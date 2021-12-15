-- Solution for Advent of Code 2021, day 8

entity day_08 is
end entity;

use std.textio.all;

architecture simulation of day_08 is

    type string_vector is array (natural range <>) of string;

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

    subtype digit_str_t is string(1 to 7);
    type pattern_t is record
        str : digit_str_t;
        len : positive;
    end record;
    type signal_patterns_t is array(0 to 9) of pattern_t;
    type output_patterns_t is array(0 to 3) of pattern_t;
    type entry_t is record
        signal_patterns : signal_patterns_t;
        output_patterns : output_patterns_t;
    end record;
    type entries_t is array(integer range <>) of entry_t;

    -- Decode input string into entry type
    function string_to_entry(
        str : string
    ) return entry_t is
        variable result           : entry_t;
        variable signal_pattern_i : natural;
        variable output_pattern_i : natural;
        variable i_start          : integer;
        variable i_end            : integer;
        variable len              : positive;
    begin
        signal_pattern_i := 0;
        output_pattern_i := 0;
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
                elsif output_pattern_i < output_patterns_t'length then
                    len := i_end - i_start + 1;
                    -- Store string and length of output digit
                    result.output_patterns(output_pattern_i).str(1 to len) := (
                    str(i_start to i_end)
                    );
                    result.output_patterns(output_pattern_i).len := len;
                    output_pattern_i                             := output_pattern_i + 1;
                    i_start                                      := I + 1;
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
            result.output_patterns(output_pattern_i).str(1 to len) := (
            str(i_start to i_end)
            );
            result.output_patterns(output_pattern_i).len := len;
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
            for DIGIT_INDEX in output_patterns_t'range loop
                case entries(ENTRY_INDEX).output_patterns(DIGIT_INDEX).len is
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

    -- Types for resulting signal to segment mapping.
    type segment_t is (SEG_A, SEG_B, SEG_C, SEG_D, SEG_E, SEG_F, SEG_G);
    type signal_t is (SIG_A, SIG_B, SIG_C, SIG_D, SIG_E, SIG_F, SIG_G);
    type signal_mapping_t is array(signal_t) of segment_t;

    -- Intermediate types for solver functions.
    type segments_t is array(integer range <>) of segment_t;
    type segments_ptr_t is access segments_t;
    type signals_t is array(integer range <>) of signal_t;
    type signals_ptr_t is access signals_t;
    type possible_segments_t is array(segment_t) of boolean;
    type signal_possibilities_t is array(signal_t) of possible_segments_t;

    -- Convert raw digit with length to array of signals
    function digit_to_signals(
        digit : pattern_t
    ) return signals_t is
        variable result : signals_t(0 to digit.len - 1);
    begin
        -- Convert each character to signal enum type
        for I in result'range loop
            -- Select enum value by difference from 'a'
            result(I) := signal_t'val(character'pos(digit.str(1 + I)) - character'pos('a'));
        end loop;
        return result;
    end function;

    -- Check if given segment/signal is contained in given array of signals/segments
    function in_array(
        hackstack : segments_t;
        needle    : segment_t
    ) return boolean is
    begin
        for INDEX in hackstack'range loop
            if hackstack(INDEX) = needle then
                return true;
            end if;
        end loop;
        return false;
    end function;
    function in_array(
        hackstack : signals_t;
        needle    : signal_t
    ) return boolean is
    begin
        for INDEX in hackstack'range loop
            if hackstack(INDEX) = needle then
                return true;
            end if;
        end loop;
        return false;
    end function;

    -- Reduce possibilities for given signals and given segments:
    -- 1. Each signal contained in the list of signals can only map to segments in the list of
    --    segments.
    -- 2. Each segment contained in the list of segments can only be mapped by signals in the list
    --    of signals.
    function reduce_possibilities(
        possibilities : signal_possibilities_t;
        signals       : signals_t;
        segments      : segments_t
    ) return signal_possibilities_t is
        variable result           : signal_possibilities_t := possibilities;
        variable signal_in_array  : boolean;
        variable segment_in_array : boolean;
        variable exclude_segment  : boolean;
    begin
        for SIGNAL1 in signal_t loop
            -- Check if current signal is in given signals
            signal_in_array := in_array(signals, SIGNAL1);

            for SEGMENT in segment_t loop
                -- Check if current segment is in given segments
                segment_in_array := in_array(segments, SEGMENT);

                -- There are two conditions under which we can exclude the current segment from the
                -- list of possibilities for the current signal.
                exclude_segment := false;
                if signal_in_array and not segment_in_array then
                    -- The current signal IS in list of given signals but the current segment IS
                    -- NOT in list of given segments.
                    exclude_segment := true;
                elsif not signal_in_array and segment_in_array then
                    -- The current signal IS NOT in the list of given signals but the current
                    -- segment IS in the list of given segments.
                    exclude_segment := true;
                end if;
                if exclude_segment then
                    result(SIGNAL1)(SEGMENT) := false;
                end if;
            end loop;
        end loop;
        return result;
    end function;

    -- Determine signal mapping for given entry.
    function determine_signal_mapping(
        patterns : signal_patterns_t
    ) return signal_mapping_t is
        variable pattern                  : pattern_t;
        variable possibilities            : signal_possibilities_t;
        variable signals_ptr              : signals_ptr_t;
        variable signals_of_one           : signals_t(0 to 1);
        variable contains_segments_of_one : boolean;
        variable mapping                  : signal_mapping_t;
    begin
        possibilities := (others => (others => true));
        -- All signals can be resolved in two runs:
        -- 1. Reduce possibilities using digits having a unique number of segments ('1', '4', '7').
        -- 2. Resolve remaining possibilities using digits '3' and '6', which can be detected by
        --    checking segments of the digit '1' seen in the first run.
        for RUN in 1 to 2 loop
            for PATTERN_INDEX in patterns'range loop
                pattern := patterns(PATTERN_INDEX);
                -- Decode signals from pattern string.
                signals_ptr := new signals_t'(digit_to_signals(pattern));
                if RUN = 1 then
                    case pattern.len is
                        when 2 =>
                            -- Only the digit '1' consists of 2 segments.
                            possibilities := reduce_possibilities(
                                possibilities,
                                signals_ptr.all,
                                -- The digit '1' only contains the segments C and F.
                                (SEG_C, SEG_F)
                                );
                            -- Store signals of one for next run
                            signals_of_one := signals_ptr.all;
                        when 3 =>
                            -- Only the digit '7' consists of 3 segments.
                            possibilities := reduce_possibilities(
                                possibilities,
                                signals_ptr.all,
                                -- The digit '7' only contains the segments A, C and F.
                                (SEG_A, SEG_C, SEG_F)
                                );
                        when 4 =>
                            -- Only the digit '4' consists of 4 segments.
                            possibilities := reduce_possibilities(
                                possibilities,
                                signals_ptr.all,
                                -- The digit '4' only contains the segments B, C, D and F.
                                (SEG_B, SEG_C, SEG_D, SEG_F)
                                );
                        when others =>
                            null;
                    end case;
                elsif RUN = 2 and (pattern.len = 5 or pattern.len = 6) then
                    -- Filter for length 5: Digits '2', '3', '5'
                    -- Filter for length 6: Digits '0', '6', '9'

                    -- Check if pattern contains both segments of the digit one.
                    contains_segments_of_one := (
                        in_array(signals_ptr.all, signals_of_one(0)) and
                        in_array(signals_ptr.all, signals_of_one(1))
                        );

                    if pattern.len = 5 and contains_segments_of_one then
                        -- Only the digit '3' consists of 5 segments with both segments of '1'.
                        possibilities := reduce_possibilities(
                            possibilities,
                            signals_ptr.all,
                            -- The digit '3' only contains the segments A, C, D, F and G.
                            (SEG_A, SEG_C, SEG_D, SEG_F, SEG_G)
                            );
                    elsif pattern.len = 6 and not contains_segments_of_one then
                        -- Only the digit '6' consists of 6 segments without both segments of '1'.
                        possibilities := reduce_possibilities(
                            possibilities,
                            signals_ptr.all,
                            -- The digit '6' only contains the segments A, B, D, E, F and G.
                            (SEG_A, SEG_B, SEG_D, SEG_E, SEG_F, SEG_G)
                            );
                    end if;
                end if;
                deallocate(signals_ptr);
            end loop;
        end loop;
        -- Create mapping from resolved possibilities
        for SIGNAL1 in signal_t loop
            mapping_segment_l : for SEGMENT in segment_t loop
                if possibilities(SIGNAL1)(SEGMENT) then
                    mapping(SIGNAL1) := SEGMENT;
                    exit mapping_segment_l;
                end if;
            end loop;
        end loop;
        return mapping;
    end function;

    -- Decode digit value from segments
    function decode_digit_value(
        segments : segments_t
    ) return natural is
    begin
        -- Decode with minimum effort assuming correctly encoded segments.
        case segments'length is
            when 2 =>
                return 1;
            when 3 =>
                return 7;
            when 4 =>
                return 4;
            when 5 =>
                if in_array(segments, SEG_B) then
                    return 5;
                elsif in_array(segments, SEG_E) then
                    return 2;
                end if;
                return 3;
            when 6 =>
                if not in_array(segments, SEG_D) then
                    return 0;
                elsif in_array(segments, SEG_C) then
                    return 9;
                end if;
                return 6;
            when 7 =>
                return 8;
            when others =>
                report "Invalid number of segments: " & integer'image(segments'length) severity failure;
        end case;
    end function;

    -- Decode output value using signal mapping
    function decode_output_value(
        output_patterns : output_patterns_t;
        mapping         : signal_mapping_t
    ) return natural is
        variable result       : natural;
        variable signals_ptr  : signals_ptr_t;
        variable segments_ptr : segments_ptr_t;
        variable digit_value  : natural;
    begin
        result := 0;
        for OV_INDEX in output_patterns'range loop
            -- Decode signals from pattern string.
            signals_ptr := new signals_t'(digit_to_signals(output_patterns(OV_INDEX)));
            -- Convert signals to segments using given signal mapping
            segments_ptr := new segments_t(signals_ptr'range);
            for I in signals_ptr'range loop
                segments_ptr(I) := mapping(signals_ptr(I));
            end loop;
            -- Get digit by list of segments
            digit_value := decode_digit_value(segments_ptr.all);
            deallocate(segments_ptr);
            deallocate(signals_ptr);
            -- Add digit to output value
            result := 10 * result + digit_value;
        end loop;
        return result;
    end function;

    -- Part Two: Sum of all the output values.
    function sum_of_output_values(
        entries : entries_t
    ) return natural is
        variable result       : natural;
        variable mapping      : signal_mapping_t;
        variable output_value : natural;
    begin
        result := 0;
        for ENTRY_INDEX in entries'range loop
            -- Determine signal mapping from patterns
            mapping := determine_signal_mapping(entries(ENTRY_INDEX).signal_patterns);
            -- Use mapping to decode output value
            output_value := decode_output_value(entries(ENTRY_INDEX).output_patterns, mapping);
            -- Add output value to resulting sum
            result := result + output_value;
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

        report "*** Part Two ***";

        result := sum_of_output_values(example_entries);
        report "Sum of output values in example input: " & integer'image(result);
        assert result = 61229;

        result := sum_of_output_values(input_entries_ptr.all);
        report "Sum of output values in input file: " & integer'image(result);
        assert result = 983026;

        deallocate(input_entries_ptr);
        wait;
    end process;

end architecture;