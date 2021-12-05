-- Solution for Advent of Code 2021, day 1

entity day_01 is
end entity;

use std.textio.all;

architecture simulation of day_01 is

    -- depth measurements from example
    constant EXAMPLE_MEASUREMENTS : integer_vector :=
    (
        199,
        200,
        208,
        210,
        200,
        207,
        240,
        269,
        260,
        263
    );

    -- return number of measurements that are higher than the previous one
    function number_of_increases_part1(measurements : integer_vector) return natural is

        variable result : natural := 0;
    begin
        for I in measurements'range loop
            -- skip first measurement
            if I /= measurements'left then
                if measurements(I) > measurements(I - 1) then
                    result := result + 1;
                end if;
            end if;
        end loop;
        return result;
    end function;

    -- return number of three-measurement-sums that are higher than the previous one
    function number_of_increases_part2(measurements : integer_vector) return natural is

        constant WINDOW_SIZE       : natural := 3;
        constant NUMBER_OF_WINDOWS : natural := measurements'length - (WINDOW_SIZE - 1);
        variable window_sum        : natural;
        variable last_window_sum   : natural;
        variable result            : natural := 0;
    begin
        for I in 0 to NUMBER_OF_WINDOWS - 1 loop
            window_sum := 0;
            for J in I to I + WINDOW_SIZE - 1 loop
                window_sum := window_sum + measurements(J);
            end loop;
            if I > 0 and window_sum > last_window_sum then
                result := result + 1;
            end if;
            last_window_sum := window_sum;
        end loop;
        return result;
    end function;

begin

    process
        variable result  : natural;
        file i_file      : text;
        variable i_line  : line;
        variable i_value : natural;
        type ptr_values_t is access integer_vector;
        variable ptr_values     : ptr_values_t;
        variable ptr_values_old : ptr_values_t;
    begin
        -- load input values from file
        file_open(i_file, "inputs/day_01.txt", read_mode);
        while not endfile(i_file) loop
            readline(i_file, i_line);
            read(i_line, i_value);
            if ptr_values = null then
                ptr_values := new integer_vector'(0 => i_value);
            else
                ptr_values_old := ptr_values;
                ptr_values     := new integer_vector'(ptr_values.all & i_value);
                deallocate(ptr_values_old);
            end if;
        end loop;
        file_close(i_file);
        report "Number of values in input: " & integer'image(ptr_values.all'length);

        report "*** Part One ***";

        result := number_of_increases_part1(EXAMPLE_MEASUREMENTS);
        report "Number of increases in example: " & integer'image(result);
        assert result = 7;

        result := number_of_increases_part1(ptr_values.all);
        report "Number of increases in input: " & integer'image(result);

        report "*** Part Two ***";

        result := number_of_increases_part2(EXAMPLE_MEASUREMENTS);
        report "Number of increases in example: " & integer'image(result);
        assert result = 5;

        result := number_of_increases_part2(ptr_values.all);
        report "Number of increases in input: " & integer'image(result);

        deallocate(ptr_values);
        wait;
    end process;

end architecture;