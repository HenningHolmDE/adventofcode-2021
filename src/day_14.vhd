-- Solution for Advent of Code 2021, day 14

entity day_14 is
end entity;

use std.textio.all;

architecture simulation of day_14 is

    type rule_t is record
        pair : string(1 to 2);
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

    function calculate_quantity_difference(
        template : string
    ) return natural is
        type quantities_t is array(character) of natural;
        variable quantities : quantities_t;
        variable minq, maxq : natural;
    begin
        -- Count quantities of all characters.
        quantities := (others => 0);
        for I in template'range loop
            quantities(template(I)) := quantities(template(I)) + 1;
        end loop;
        -- Find minimum (non-zero) and maximum quantity.
        minq := natural'high;
        maxq := 0;
        for C in character loop
            if quantities(C) > 0 then
                minq := minimum(minq, quantities(C));
                maxq := maximum(maxq, quantities(C));
            end if;
        end loop;
        -- Return difference of most common and least common element.
        return maxq - minq;
    end function;

    -- Perform pair insertion and return new template.
    function perform_pair_insertion(
        template : string;
        rules    : rules_t
    ) return string is
        -- As an element will be inserted into every pair of elemente,
        -- the template length will grow to (2 * l - 1).
        variable new_template : string(1 to 2 * template'length - 1);
        variable pair         : string(1 to 2);
    begin
        new_template := (others => '_');
        for T in template'range loop
            -- Add current element to new template.
            new_template(2 * T - 1) := template(T);
            -- Perform pair insertion for current pair.
            if T < template'high then
                pair := template(T to T + 1);
                -- Find rule for pair.
                for R in rules'range loop
                    if rules(R).pair = pair then
                        new_template(2 * T) := rules(R).char;
                        exit;
                    end if;
                end loop;
            end if;
        end loop;
        return new_template;
    end function;

    -- Perform given number of pair insertion and return the quantity of the
    -- most common element reduced by the quantity of the least common element.
    function calculate_quantity_difference_after_insertions(
        input1               : input_t;
        number_of_insertions : natural
    ) return natural is
        type string_ptr_t is access string;
        variable template_ptr     : string_ptr_t;
        variable template_ptr_old : string_ptr_t;
        variable result           : natural;
    begin
        template_ptr := new string'(input1.template);

        -- Perform pair insertion steps.
        for STEP in 1 to number_of_insertions loop
            template_ptr_old := template_ptr;
            template_ptr     := new string'(
                perform_pair_insertion(template_ptr.all, input1.rules)
                );
            deallocate(template_ptr_old);
        end loop;

        -- Calculate result.
        result := calculate_quantity_difference(template_ptr.all);
        deallocate(template_ptr);
        return result;
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
        variable pair  : string(1 to 2);
        variable char  : character;

        variable result : natural;
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
            integer'image(result)
            );
        assert result = 1588;

        result := calculate_quantity_difference_after_insertions(
            input_ptr.all, 10
            );
        report (
            "Quantity difference after 10 steps for input file: " &
            integer'image(result)
            );
        assert result = 2375;

        -- report "*** Part Two ***";

        deallocate(input_ptr);
        wait;
    end process;

end architecture;
