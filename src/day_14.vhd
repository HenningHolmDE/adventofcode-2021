-- Solution for Advent of Code 2021, day 14

entity day_14 is
end entity;

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture simulation of day_14 is

    subtype big_unsigned_t is unsigned(63 downto 0);

    subtype pair_t is string(1 to 2);
    type rule_t is record
        pair : pair_t;
        char : character;
    end record;
    type rules_t is array(natural range <>) of rule_t;
    type input_t is record
        template : string;
        rules    : rules_t;
    end record;

    constant EXAMPLE_INPUT : input_t :=
    (
    "NNCB",
    (
    ("CH", 'B'),
    ("HH", 'N'),
    ("CB", 'H'),
    ("NH", 'C'),
    ("HB", 'C'),
    ("HC", 'B'),
    ("HN", 'C'),
    ("NN", 'C'),
    ("BH", 'H'),
    ("NC", 'B'),
    ("NB", 'B'),
    ("BN", 'B'),
    ("BB", 'N'),
    ("BC", 'B'),
    ("CC", 'N'),
    ("CN", 'C')
    )
    );

    type big_unsigned_vector_t is array(natural range <>) of big_unsigned_t;
    type template_in_pairs_t is record
        first_char  : character;
        last_char   : character;
        pair_counts : big_unsigned_vector_t;
    end record;

    -- Calculate the difference of the quantity of the most common element
    -- and the quantity of the least common element.
    function calculate_quantity_difference(
        template : template_in_pairs_t;
        rules    : rules_t
    ) return big_unsigned_t is
        type quantities_t is array(character) of big_unsigned_t;
        variable quantities : quantities_t;
        variable minq, maxq : big_unsigned_t;
    begin
        -- Initialize with first and last character of template.
        quantities                      := (others => (others => '0'));
        quantities(template.first_char) := to_unsigned(1, big_unsigned_t'length);
        quantities(template.last_char)  := to_unsigned(1, big_unsigned_t'length);

        -- Add pair counts to both characters in pair.
        for I in rules'range loop
            quantities(rules(I).pair(1)) :=
            (
            quantities(rules(I).pair(1)) + template.pair_counts(I)
            );
            quantities(rules(I).pair(2)) :=
            (
            quantities(rules(I).pair(2)) + template.pair_counts(I)
            );
        end loop;

        -- Note: As the quantities have been extracted from pairs, all
        --       quantities are twice their actual value.
        --       However, it it more efficient to handle this at the end.

        -- Find minimum (non-zero) and maximum quantity.
        minq := (others => '1');
        maxq := (others => '0');
        for C in character loop
            if quantities(C) > 0 then
                minq := minimum(minq, quantities(C));
                maxq := maximum(maxq, quantities(C));
            end if;
        end loop;

        -- Return difference of most common and least common element.
        return (maxq - minq) / 2; -- / 2 to get actual quantity.
    end function;

    -- Perform pair insertion and return new template.
    function perform_pair_insertion(
        template : template_in_pairs_t;
        rules    : rules_t
    ) return template_in_pairs_t is
        variable new_template : template_in_pairs_t(
        pair_counts(template.pair_counts'range)
        );
        variable pair : pair_t;
    begin
        new_template := (
            first_char => template.first_char,
            last_char  => template.last_char,
            pair_counts => (others => (others => '0'))
            );
        for I in rules'range loop
            -- Every occurence of a pair will end up in two new pairs.
            -- Add first pair after insertion.
            pair := rules(I).pair(1) & rules(I).char;
            for J in rules'range loop
                if rules(J).pair = pair then
                    new_template.pair_counts(J) :=
                    (
                    new_template.pair_counts(J) + template.pair_counts(I)
                    );
                    exit;
                end if;
            end loop;
            -- Add second pair after insertion.
            pair := rules(I).char & rules(I).pair(2);
            for J in rules'range loop
                if rules(J).pair = pair then
                    new_template.pair_counts(J) :=
                    (
                    new_template.pair_counts(J) + template.pair_counts(I)
                    );
                    exit;
                end if;
            end loop;
        end loop;
        return new_template;
    end function;

    -- Perform given number of pair insertion and return the quantity of the
    -- most common element reduced by the quantity of the least common element.
    function calculate_quantity_difference_after_insertions(
        input1               : input_t;
        number_of_insertions : natural
    ) return big_unsigned_t is
        variable template : template_in_pairs_t(
        pair_counts(0 to input1.rules'length)
        );
        variable pair : pair_t;
    begin
        -- Create template_in_pairs_t representation from template.
        template.first_char  := input1.template(1);
        template.last_char   := input1.template(input1.template'high);
        template.pair_counts := (others => (others => '0'));

        -- Determine pair amounts from template string.
        for T in 1 to input1.template'high - 1 loop
            pair := input1.template(T to T + 1);
            for I in input1.rules'range loop
                if input1.rules(I).pair = pair then
                    template.pair_counts(I) :=
                    template.pair_counts(I) + 1;
                    exit;
                end if;
            end loop;
        end loop;

        -- Perform pair insertion steps.
        for STEP in 1 to number_of_insertions loop
            template := perform_pair_insertion(template, input1.rules);
        end loop;

        -- Calculate result.
        return calculate_quantity_difference(template, input1.rules);
    end function;

begin

    process
        file i_file              : text;
        variable i_line          : line;
        variable template_len    : natural;
        variable number_of_rules : natural;

        type input_ptr_t is access input_t;
        variable input_ptr : input_ptr_t;

        variable index : natural;
        variable pair  : pair_t;
        variable char  : character;

        variable result : big_unsigned_t;
    begin
        report (
            "Length of template in example input: " &
            integer'image(EXAMPLE_INPUT.template'length)
            );
        report (
            "Number of rules in example input: " &
            integer'image(EXAMPLE_INPUT.rules'length)
            );

        -- Read input file once to get template length and number of rules.
        file_open(i_file, "inputs/day_14.txt", read_mode);

        -- Get template length.
        readline(i_file, i_line);
        template_len := i_line'length;

        readline(i_file, i_line); -- Skip empty line.

        -- Get number of rules.
        number_of_rules := 0;
        while not endfile(i_file) loop
            readline(i_file, i_line);
            number_of_rules := number_of_rules + 1;
        end loop;
        file_close(i_file);

        input_ptr := new input_t(
            template(1 to template_len), rules(0 to number_of_rules - 1)
            );

        -- Read input file again to extract data.
        file_open(i_file, "inputs/day_14.txt", read_mode);
        readline(i_file, i_line);
        input_ptr.template := i_line.all;
        readline(i_file, i_line);
        index := 0;
        while not endfile(i_file) loop
            readline(i_file, i_line);
            -- Skip the start of "fold along y" and get 'x' or 'y'.
            read(i_line, pair);
            for I in 1 to 4 loop
                read(i_line, char); -- skip ' -> '
            end loop;
            read(i_line, char);
            input_ptr.rules(index) := (pair, char);
            index                  := index + 1;
        end loop;
        file_close(i_file);

        report (
            "Length of template in input file: " &
            integer'image(input_ptr.template'length)
            );
        report (
            "Number of rules in input file: " &
            integer'image(input_ptr.rules'length)
            );

        report "*** Part One ***";

        result := calculate_quantity_difference_after_insertions(
            EXAMPLE_INPUT, 10
            );
        report (
            "Quantity difference after 10 steps for example input: " &
            integer'image(to_integer(result))
            );
        assert result = 1588;

        result := calculate_quantity_difference_after_insertions(
            input_ptr.all, 10
            );
        report (
            "Quantity difference after 10 steps for input file: " &
            integer'image(to_integer(result))
            );
        assert result = 2375;

        report "*** Part Two ***";

        result := calculate_quantity_difference_after_insertions(
            EXAMPLE_INPUT, 40
            );
        report (
            "Quantity difference after 40 steps for example input: 0x" &
            to_hstring(result)
            );
        assert result = d"2188189693529";

        result := calculate_quantity_difference_after_insertions(
            input_ptr.all, 40
            );
        report (
            "Quantity difference after 40 steps for input file: 0x" &
            to_hstring(result)
            );
        assert result = d"1976896901756";

        deallocate(input_ptr);
        wait;
    end process;

end architecture;
