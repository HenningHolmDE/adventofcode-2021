-- Solution for Advent of Code 2021, day 7

entity day_07 is
end entity;

use std.textio.all;

architecture simulation of day_07 is

    constant EXAMPLE_INPUT : integer_vector := (16, 1, 2, 0, 4, 2, 7, 1, 2, 14);

    type integer_vector_ptr_t is access integer_vector;
    type part_t is (PART1, PART2);

    -- Calculate fuel consumption for aligning crabs to given position
    function calculate_fuel_by_position(
        crabs    : integer_vector;
        position : natural;
        part     : part_t
    ) return natural is
        variable result   : natural;
        variable distance : natural;
        variable fuel     : natural;
    begin
        -- Accumulate expected fuel consumption for all crabs.
        result := 0;
        for I in crabs'range loop
            distance := abs(crabs(I) - position);
            if part = PART1 then
                -- Constant fuel consumption
                fuel := distance;
            else
                -- Fuel consumption is defined by triangular number.
                fuel := distance * (distance + 1) / 2;
            end if;
            result := result + fuel;
        end loop;
        return result;
    end function;

    -- Find minimum fuel consumption for aligning crabs
    function calculate_minimum_fuel(
        crabs : integer_vector;
        part  : part_t
    ) return natural is
        constant MAXIMUM_POSITION : natural := maximum(crabs);
        variable fuel             : natural;
        variable minimum_fuel     : natural := integer'high;
        variable minimum_position : natural;
    begin
        -- Check fuel consumption for each position and track minimum.
        for POSITION in 0 to MAXIMUM_POSITION loop
            fuel := calculate_fuel_by_position(crabs, POSITION, part);
            if fuel < minimum_fuel then
                minimum_fuel     := fuel;
                minimum_position := POSITION;
            end if;
        end loop;
        report "Found minimum " & integer'image(minimum_fuel) & " at " & integer'image(minimum_position);
        return minimum_fuel;
    end function;

begin

    process
        file i_file     : text;
        variable i_line : line;

        variable input_crab_ptr  : integer_vector_ptr_t;
        variable number_of_crabs : natural;
        variable char            : character;
        variable good            : boolean;

        variable result : natural;
    begin
        -- Load lines from input file
        file_open(i_file, "inputs/day_07.txt", read_mode);
        readline(i_file, i_line);
        number_of_crabs := 1;
        -- Add number of commas in line to find out number of crabs
        for I in i_line'range loop
            if i_line(I) = ',' then
                number_of_crabs := number_of_crabs + 1;
            end if;
        end loop;
        -- Create input crab vector
        input_crab_ptr := new integer_vector(0 to number_of_crabs - 1);
        for I in input_crab_ptr'range loop
            read(i_line, input_crab_ptr(I));
            read(i_line, char, good); -- skip ','
        end loop;
        file_close(i_file);
        report "Number of crabs in example input: " & integer'image(EXAMPLE_INPUT'length);
        report "Number of crabs in input file: " & integer'image(input_crab_ptr'length);

        report "*** Part One ***";

        result := calculate_minimum_fuel(EXAMPLE_INPUT, PART1);
        report "Minimum fuel consumption for aligning crabs in example input: " & integer'image(result);
        assert result = 37;

        result := calculate_minimum_fuel(input_crab_ptr.all, PART1);
        report "Minimum fuel consumption for aligning crabs in input file: " & integer'image(result);
        assert result = 349769;

        report "*** Part Two ***";

        result := calculate_minimum_fuel(EXAMPLE_INPUT, PART2);
        report "Minimum fuel consumption for aligning crabs in example input: " & integer'image(result);
        assert result = 168;

        result := calculate_minimum_fuel(input_crab_ptr.all, PART2);
        report "Minimum fuel consumption for aligning crabs in input file: " & integer'image(result);
        assert result = 99540554;

        deallocate(input_crab_ptr);
        wait;
    end process;

end architecture;