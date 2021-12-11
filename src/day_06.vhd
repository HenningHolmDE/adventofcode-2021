-- Solution for Advent of Code 2021, day 6

entity day_06 is
end entity;

use std.textio.all;

architecture simulation of day_06 is

    constant EXAMPLE_INPUT : integer_vector := (3, 4, 3, 1, 2);

    -- Type for holding fish population sorted by timer value.
    subtype lanternfish_timers_t is integer_vector(0 to 8);

    -- Simulate lanternfish growth of one day.
    function run_simulation_step(
        fish : lanternfish_timers_t
    ) return lanternfish_timers_t is
        variable result : lanternfish_timers_t;
    begin
        -- decrement lanternfish timers
        result := (
            0 to 5 => fish(1 to 6),
            6      => fish(7) + fish(0), -- decremented from 7 or restarted from 0
            7      => fish(8),
            8      => fish(0) -- new fish created by expired timers
            );
        return result;
    end function;

    -- Simulate lanternfish growth for 80 days.
    function simulate_fish_growth_part1(
        fish : lanternfish_timers_t
    ) return lanternfish_timers_t is
        variable result : lanternfish_timers_t;
    begin
        result := fish;
        for DAY in 1 to 80 loop
            result := run_simulation_step(result);
        end loop;
        return result;
    end function;

    -- Sum fish over all timer values
    function sum(fish : lanternfish_timers_t) return natural is
        variable result   : natural := 0;
    begin
        for I in fish'range loop
            result := result + fish(I);
        end loop;
        return result;
    end function;

begin

    process
        file i_file          : text;
        variable i_line      : line;
        variable timer_value : natural;
        variable char        : character;
        variable good        : boolean;

        variable example_fish : lanternfish_timers_t;
        variable input_fish   : lanternfish_timers_t;
        variable result       : natural;
    begin
        -- Load fish from example input
        example_fish := (others => 0);
        for I in EXAMPLE_INPUT'range loop
            example_fish(EXAMPLE_INPUT(I)) := example_fish(EXAMPLE_INPUT(I)) + 1;
        end loop;
        report "Number of fish in example input: " & integer'image(sum(example_fish));

        -- Load fish from input file
        input_fish := (others => 0);
        file_open(i_file, "inputs/day_06.txt", read_mode);
        readline(i_file, i_line);
        good := true;
        while good loop
            read(i_line, timer_value);
            input_fish(timer_value) := input_fish(timer_value) + 1;
            read(i_line, char, good); -- skip ',' if available
        end loop;
        file_close(i_file);
        report "Number of fish in input file: " & integer'image(sum(input_fish));

        report "*** Part One ***";

        result := sum(simulate_fish_growth_part1(example_fish));
        report "Number of fish after simulating example input: " & integer'image(result);
        assert result = 5934;

        result := sum(simulate_fish_growth_part1(input_fish));
        report "Number of fish after simulating input file: " & integer'image(result);
        assert result = 380243;

        -- report "*** Part Two ***";

        wait;
    end process;

end architecture;