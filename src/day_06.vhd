-- Solution for Advent of Code 2021, day 6

entity day_06 is
end entity;

use std.textio.all;

architecture simulation of day_06 is

    constant EXAMPLE_INPUT : integer_vector := (3, 4, 3, 1, 2);

    type integer_vector_ptr_t is access integer_vector;

    -- Simulate lanternfish growth of one day.
    procedure run_simulation_step(
        variable fish_ptr : inout integer_vector_ptr_t
    ) is
        variable number_of_new_fish : natural;
        variable fish_ptr_old       : integer_vector_ptr_t;
    begin
        -- Decrease fish timers and count the number of new fish to be created.
        number_of_new_fish := 0;
        for I in fish_ptr'range loop
            if fish_ptr(I) = 0 then
                number_of_new_fish := number_of_new_fish + 1;
                fish_ptr(I)        := 6;
            else
                fish_ptr(I) := fish_ptr(I) - 1;
            end if;
        end loop;
        -- Create new fish if required.
        if number_of_new_fish > 0 then
            fish_ptr_old := fish_ptr;
            fish_ptr     := new integer_vector(0 to fish_ptr'length + number_of_new_fish - 1);
            fish_ptr.all := fish_ptr_old.all & (0 to number_of_new_fish - 1 => 8);
            deallocate(fish_ptr_old);
        end if;
    end procedure;

    -- Simulate lanternfish growth for 80 days.
    procedure simulate_fish_growth_part1(
        variable fish_ptr : inout integer_vector_ptr_t
    ) is
    begin
        for DAY in 1 to 80 loop
            run_simulation_step(fish_ptr);
        end loop;
    end procedure;

begin

    process
        file i_file     : text;
        variable i_line : line;

        variable input_fish_ptr : integer_vector_ptr_t;
        variable number_of_fish : natural;
        variable char           : character;
        variable good           : boolean;

        variable fish_ptr : integer_vector_ptr_t;
    begin
        -- Load lines from input file
        file_open(i_file, "inputs/day_06.txt", read_mode);
        readline(i_file, i_line);
        number_of_fish := 1;
        -- Add number of commas in line to find out number of fish
        for I in i_line'range loop
            if i_line(I) = ',' then
                number_of_fish := number_of_fish + 1;
            end if;
        end loop;
        -- Create input fish vector
        input_fish_ptr := new integer_vector(0 to number_of_fish - 1);
        for I in input_fish_ptr'range loop
            read(i_line, input_fish_ptr(I));
            read(i_line, char, good); -- skip ','
        end loop;
        file_close(i_file);
        report "Number of fish in example input: " & integer'image(EXAMPLE_INPUT'length);
        report "Number of fish in input file: " & integer'image(input_fish_ptr'length);

        report "*** Part One ***";

        fish_ptr := new integer_vector'(EXAMPLE_INPUT);
        simulate_fish_growth_part1(fish_ptr);
        report "Number of fish after simulating example input: " & integer'image(fish_ptr'length);
        assert fish_ptr'length = 5934;
        deallocate(fish_ptr);

        fish_ptr := new integer_vector'(input_fish_ptr.all);
        simulate_fish_growth_part1(fish_ptr);
        report "Number of fish after simulating input file: " & integer'image(fish_ptr'length);
        assert fish_ptr'length = 380243;
        deallocate(fish_ptr);

        -- report "*** Part Two ***";

        deallocate(input_fish_ptr);
        wait;
    end process;

end architecture;