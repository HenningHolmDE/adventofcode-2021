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

    function number_of_increases(measurements : integer_vector) return natural is

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
        result := number_of_increases(EXAMPLE_MEASUREMENTS);
        report "Number of increases in example: " & integer'image(result);
        assert result = 7;

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
        result := number_of_increases(ptr_values.all);
        report "Number of increases in input (solution for part one): " & integer'image(result);
        wait;
    end process;

end architecture;