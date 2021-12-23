-- Solution for Advent of Code 2021, day 11

entity day_11 is
end entity;

use std.textio.all;

architecture simulation of day_11 is

    type energy_levels_t is array (0 to 9, 0 to 9) of natural;

    constant EXAMPLE_ENERGY_LEVELS : energy_levels_t :=
    (
        (5, 4, 8, 3, 1, 4, 3, 2, 2, 3),
        (2, 7, 4, 5, 8, 5, 4, 7, 1, 1),
        (5, 2, 6, 4, 5, 5, 6, 1, 7, 3),
        (6, 1, 4, 1, 3, 3, 6, 1, 4, 6),
        (6, 3, 5, 7, 3, 8, 5, 4, 7, 8),
        (4, 1, 6, 7, 5, 2, 4, 6, 4, 5),
        (2, 1, 7, 6, 8, 4, 1, 7, 2, 1),
        (6, 8, 8, 2, 8, 8, 1, 1, 3, 4),
        (4, 8, 4, 6, 8, 4, 8, 5, 5, 4),
        (5, 2, 8, 3, 7, 5, 1, 5, 2, 6)
    );

    type step_result_t is record
        energy_levels     : energy_levels_t;
        number_of_flashes : natural;
    end record;

    -- Perform one step and return resulting energy levels and number of flashes during the step.
    function run_step(
        energy_levels : energy_levels_t
    ) return step_result_t is
        type already_flashed_t is array (energy_levels'range(1), energy_levels'range(2)) of boolean;
        variable result                 : step_result_t;
        variable last_number_of_flashes : natural;
        variable already_flashed        : already_flashed_t;
    begin
        -- Increase all energy levels by 1
        for ROW in energy_levels'range(1) loop
            for COL in energy_levels'range(2) loop
                result.energy_levels(ROW, COL) := energy_levels(ROW, COL) + 1;
            end loop;
        end loop;

        -- Perform flashing
        result.number_of_flashes := 0;
        already_flashed          := (others => (others => false));
        loop
            last_number_of_flashes := result.number_of_flashes;
            for ROW in energy_levels'range(1) loop
                for COL in energy_levels'range(2) loop
                    -- Find flashing octopuses.
                    if result.energy_levels(ROW, COL) > 9 and not already_flashed(ROW, COL) then
                        -- FLASH!
                        result.number_of_flashes  := result.number_of_flashes + 1;
                        already_flashed(ROW, COL) := true;
                        -- Increase energy level of adjacent octopuses.
                        for ADJ_ROW in
                            maximum(energy_levels'left(1), ROW - 1) to
                            minimum(energy_levels'right(1), ROW + 1) loop
                            for ADJ_COL in
                                maximum(energy_levels'left(1), COL - 1) to
                                minimum(energy_levels'right(1), COL + 1) loop
                                if ADJ_ROW /= ROW or ADJ_COL /= COL then
                                    result.energy_levels(ADJ_ROW, ADJ_COL) := (
                                    result.energy_levels(ADJ_ROW, ADJ_COL) + 1
                                    );
                                end if;
                            end loop;
                        end loop;
                    end if;
                end loop;
            end loop;

            -- Stop when no more flashes occurred.
            exit when result.number_of_flashes = last_number_of_flashes;
        end loop;

        -- Clear energy of flashing octopuses.
        for ROW in energy_levels'range(1) loop
            for COL in energy_levels'range(2) loop
                if already_flashed(ROW, COL) then
                    result.energy_levels(ROW, COL) := 0;
                end if;
            end loop;
        end loop;
        return result;
    end function;

    -- Part One: Calculate total number of flashes after a given number of steps.
    function flashes_after_n_steps(
        energy_levels   : energy_levels_t;
        number_of_steps : natural
    ) return natural is
        variable total_number_of_flashes : natural;
        variable step_result             : step_result_t;
    begin
        total_number_of_flashes   := 0;
        step_result.energy_levels := energy_levels;
        for STEP in 1 to number_of_steps loop
            step_result             := run_step(step_result.energy_levels);
            total_number_of_flashes := total_number_of_flashes + step_result.number_of_flashes;
        end loop;
        return total_number_of_flashes;
    end function;

    -- Part Two: Find first step where all octopuses flash simultaneously.
    function first_step_all_flashing(
        energy_levels : energy_levels_t
    ) return natural is
        variable step        : natural;
        variable step_result : step_result_t;
    begin
        step                      := 0;
        step_result.energy_levels := energy_levels;
        loop
            step        := step + 1;
            step_result := run_step(step_result.energy_levels);
            if step_result.number_of_flashes = 100 then
                exit;
            end if;
        end loop;
        return step;
    end function;

begin

    process
        variable input_energy_levels : energy_levels_t;

        file i_file     : text;
        variable i_line : line;
        variable char   : character;

        variable result : natural;
    begin
        -- Load energy levels from input file
        file_open(i_file, "inputs/day_11.txt", read_mode);
        for ROW in 0 to 9 loop
            readline(i_file, i_line);
            -- Load row of digits from line
            for COL in 0 to 9 loop
                read(i_line, char);
                input_energy_levels(ROW, COL) := character'pos(char) - character'pos('0');
            end loop;
        end loop;
        file_close(i_file);

        report "*** Part One ***";

        result := flashes_after_n_steps(EXAMPLE_ENERGY_LEVELS, 100);
        report "Number of flashes after 100 steps for example input: " & integer'image(result);
        assert result = 1656;

        result := flashes_after_n_steps(input_energy_levels, 100);
        report "Number of flashes after 100 steps for input file: " & integer'image(result);
        assert result = 1642;

        report "*** Part Two ***";

        result := first_step_all_flashing(EXAMPLE_ENERGY_LEVELS);
        report (
            "First step all octopuses flash simultaneously in example input: " &
            integer'image(result)
            );
        assert result = 195;

        result := first_step_all_flashing(input_energy_levels);
        report (
            "First step all octopuses flash simultaneously in input file: " &
            integer'image(result)
            );
        assert result = 320;

        wait;
    end process;

end architecture;