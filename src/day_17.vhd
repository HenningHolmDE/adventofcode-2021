-- Solution for Advent of Code 2021, day 17

entity day_17 is
end entity;

use std.textio.all;

architecture simulation of day_17 is

    type target_range_t is record
        min : integer;
        max : integer;
    end record;

    type target_area_t is record
        x : target_range_t;
        y : target_range_t;
    end record;

    constant EXAMPLE_TARGET_AREA : target_area_t := ((20, 30), (-10, -5));

    type position_t is record
        x : natural;
        y : integer;
    end record;

    type velocity_t is record
        x : natural;
        y : integer;
    end record;

    type simulation_result_t is record
        target_reached : boolean;
        maximum_y      : natural;
    end record;

    type evaluation_result_t is record
        valid_trajectories : natural;
        maximum_y          : natural;
    end record;

    -- Check if given position is in the target area.
    function in_target_area(
        target_area : target_area_t;
        position    : position_t
    ) return boolean is
    begin
        return (
        position.x >= target_area.x.min and
        position.x <= target_area.x.max and
        position.y >= target_area.y.min and
        position.y <= target_area.y.max
        );
    end function;

    -- Simulate trajectory for given initial velocity.
    function simulate_trajectory(
        target_area      : target_area_t;
        initial_velocity : velocity_t
    ) return simulation_result_t is
        variable result   : simulation_result_t;
        variable position : position_t;
        variable velocity : velocity_t;
    begin
        result   := (false, 0);
        position := (0, 0);
        velocity := initial_velocity;
        -- Run simulation until target has been missed.
        while position.x <= target_area.x.max and
            position.y >= target_area.y.min loop

            -- Update position.
            position.x := position.x + velocity.x;
            position.y := position.y + velocity.y;

            -- Apply drag and gravity to velocity.
            if velocity.x > 0 then
                velocity.x := velocity.x - 1;
            elsif velocity.x < 0 then
                velocity.x := velocity.x + 1;
            end if;
            velocity.y := velocity.y - 1;

            -- Track maximum y position.
            result.maximum_y := maximum(result.maximum_y, position.y);
            if in_target_area(target_area, position) then
                result.target_reached := true;
                exit;
            end if;
        end loop;

        return result;
    end function;

    -- Evaluate space of initial velocities and return results.
    function evaluate_valid_trajectories(
        target_area : target_area_t
    ) return evaluation_result_t is
        variable initial_velocity  : velocity_t;
        variable trajectory_result : simulation_result_t;
        variable result            : evaluation_result_t;
    begin
        result := (0, 0);
        for INITIAL_X in 1 to target_area.x.max loop
            -- There is probably a good ways to determine the upper bound for INITIAL_Y, but as
            -- 90 seems to be large enough for both inputs, 500 should give enough head room.
            for INITIAL_Y in target_area.y.min to 500 loop
                initial_velocity  := (INITIAL_X, INITIAL_Y);
                trajectory_result := simulate_trajectory(target_area, initial_velocity);
                if trajectory_result.target_reached then
                    result.valid_trajectories := result.valid_trajectories + 1;
                    result.maximum_y          := maximum(result.maximum_y, trajectory_result.maximum_y);
                end if;
            end loop;
        end loop;
        return result;
    end function;

begin

    process
        file i_file                  : text;
        variable i_line              : line;
        variable target_area         : target_area_t;
        variable eval_result_example : evaluation_result_t;
        variable eval_result_input   : evaluation_result_t;
        variable result              : natural;

        -- Skip given number of characters in line.
        procedure skip_chars(variable line1 : inout line; num_chars : natural) is
            variable char : character;
        begin
            for I in 1 to num_chars loop
                read(line1, char);
            end loop;
        end procedure;
    begin
        -- Load target area from input file
        file_open(i_file, "inputs/day_17.txt", read_mode);
        readline(i_file, i_line);
        file_close(i_file);
        skip_chars(i_line, 15); -- Skip "target area: x="
        read(i_line, target_area.x.min);
        skip_chars(i_line, 2); -- Skip ".."
        read(i_line, target_area.x.max);
        skip_chars(i_line, 4); -- Skip ", y="
        read(i_line, target_area.y.min);
        skip_chars(i_line, 2); -- Skip ".."
        read(i_line, target_area.y.max);
        file_close(i_file);

        report (
            "Target area from input file: x=" & integer'image(target_area.x.min) &
            ".." & integer'image(target_area.x.max) &
            ", y=" & integer'image(target_area.y.min) &
            ".." & integer'image(target_area.y.max)
            );

        report "*** Part One ***";

        eval_result_example := evaluate_valid_trajectories(EXAMPLE_TARGET_AREA);
        report (
            "Highest y position on valid trajectories for example target area: " &
            integer'image(eval_result_example.maximum_y)
            );
        assert eval_result_example.maximum_y = 45;

        eval_result_input := evaluate_valid_trajectories(target_area);
        report (
            "Highest y position on valid trajectories for target area from input file: " &
            integer'image(eval_result_input.maximum_y)
            );
        assert eval_result_input.maximum_y = 3916;

        report "*** Part Two ***";

        report (
            "Number of valid trajectories for example target area: " &
            integer'image(eval_result_example.valid_trajectories)
            );
        assert eval_result_example.valid_trajectories = 112;

        report (
            "Number of valid trajectories for target area from input file: " &
            integer'image(eval_result_input.valid_trajectories)
            );
        assert eval_result_input.valid_trajectories = 2986;

        wait;
    end process;

end architecture;