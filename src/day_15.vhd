-- Solution for Advent of Code 2021, day 15

entity day_15 is
end entity;

use std.textio.all;

architecture simulation of day_15 is

    type risk_levels_t is array (natural range <>, natural range <>) of natural;

    constant EXAMPLE_RISK_LEVELS : risk_levels_t :=
    (
    (1, 1, 6, 3, 7, 5, 1, 7, 4, 2),
    (1, 3, 8, 1, 3, 7, 3, 6, 7, 2),
    (2, 1, 3, 6, 5, 1, 1, 3, 2, 8),
    (3, 6, 9, 4, 9, 3, 1, 5, 6, 9),
    (7, 4, 6, 3, 4, 1, 7, 1, 1, 1),
    (1, 3, 1, 9, 1, 2, 8, 1, 3, 7),
    (1, 3, 5, 9, 9, 1, 2, 4, 2, 1),
    (3, 1, 2, 5, 4, 2, 1, 6, 3, 9),
    (1, 2, 9, 3, 1, 3, 8, 5, 2, 1),
    (2, 3, 1, 1, 9, 4, 4, 5, 8, 1)
    );

    subtype position_t is integer_vector(1 to 2);
    type update_positions_t is array(natural range <>) of position_t;
    type update_positions_len_t is record
        positions : update_positions_t;
        length    : natural;
    end record;
    type part_t is (PART_ONE, PART_TWO);

    -- Determine risk level of position in tiled cave.
    function position_risk_level(
        risk_levels : risk_levels_t;
        position    : position_t
    ) return natural is
        variable result : natural;
    begin
        result := risk_levels(
            position(1) mod risk_levels'length(1),
            position(2) mod risk_levels'length(2)
            );
        result := result + position(1) / risk_levels'length(1);
        result := result + position(2) / risk_levels'length(2);
        result := ((result - 1) mod 9) + 1;
        return result;
    end function;

    -- Enable update for positions adjacent to given position. 
    function update_adjacent_positions(
        position_values : risk_levels_t;
        risk_levels     : risk_levels_t;
        position        : position_t
    ) return update_positions_len_t is
        -- There are only four adjacent positions.
        variable update_positions     : update_positions_t(0 to 3);
        variable update_positions_len : natural;
        variable position_value       : natural;
        variable adj_position_value   : natural;
        variable adj_risk_level       : natural;
    begin
        update_positions_len := 0;
        position_value       := position_values(position(1), position(2));
        if position(1) > 0 then
            update_positions(update_positions_len) :=
            (position(1) - 1, position(2));
            update_positions_len := update_positions_len + 1;
        end if;
        if position(2) > 0 then
            update_positions(update_positions_len) :=
            (position(1), position(2) - 1);
            update_positions_len := update_positions_len + 1;
        end if;
        if position(1) < position_values'high(1) then
            update_positions(update_positions_len) :=
            (position(1) + 1, position(2));
            update_positions_len := update_positions_len + 1;
        end if;
        if position(2) < position_values'high(2) then
            update_positions(update_positions_len) :=
            (position(1), position(2) + 1);
            update_positions_len := update_positions_len + 1;
        end if;
        return (update_positions, update_positions_len);
    end function;

    -- Calculate value for given position from minimum adjacent value
    -- increased by risk level of position.
    function calculate_position_value(
        risk_levels     : risk_levels_t;
        position_values : risk_levels_t;
        position        : position_t
    ) return natural is
        variable minimum_adjacent_value : natural;
        variable risk_level             : natural;
    begin
        if position = (0, 0) then
            -- Starting position has not to be entered.
            return 0;
        end if;
        minimum_adjacent_value := integer'high;
        if position(1) > 0 then
            minimum_adjacent_value := minimum(
                minimum_adjacent_value,
                position_values(position(1) - 1, position(2))
                );
        end if;
        if position(2) > 0 then
            minimum_adjacent_value := minimum(
                minimum_adjacent_value,
                position_values(position(1), position(2) - 1)
                );
        end if;
        if position(1) < position_values'high(1) then
            minimum_adjacent_value := minimum(
                minimum_adjacent_value,
                position_values(position(1) + 1, position(2))
                );
        end if;
        if position(2) < position_values'high(2) then
            minimum_adjacent_value := minimum(
                minimum_adjacent_value,
                position_values(position(1), position(2) + 1)
                );
        end if;

        -- Increase minimum adjacent value by risk level of position.
        return (
        minimum_adjacent_value +
        position_risk_level(risk_levels, position)
        );
    end function;

    -- Calculate cave dimension depending on challenge part.
    function cave_size(
        risk_levels : risk_levels_t;
        part        : part_t;
        dimension   : integer range 1 to 2
    ) return positive is
        variable sizes : integer_vector(1 to 2);
    begin
        sizes := (risk_levels'length(1), risk_levels'length(1));
        if part = PART_TWO then
            sizes := (sizes(1) * 5, sizes(2) * 5);
        end if;
        return sizes(dimension);
    end function;

    -- Find the lowest total risk of any path from the top left
    -- to the bottom right.
    function lowest_total_risk_path(
        risk_levels : risk_levels_t;
        part        : part_t
    ) return natural is
        constant NUM_ROWS : positive := cave_size(
        risk_levels, part, 1
        );
        constant NUM_COLS : positive := cave_size(
        risk_levels, part, 2
        );
        variable position_values : risk_levels_t(
        0 to NUM_ROWS - 1, 0 to NUM_COLS - 1
        );
        -- Total number of positions should never be exceeded.
        variable update_positions : update_positions_len_t(
        positions(0 to NUM_ROWS * NUM_ROWS - 1)
        );
        variable update_positions_index : natural;
        variable update_position        : position_t;
        variable position_value         : natural;
        variable new_update_positions   : update_positions_len_t(
        positions(0 to 3)
        );
        variable new_update_position : position_t;
        variable found               : boolean;
    begin
        -- Starting position has not to be entered.
        position_values       := (others => (others => natural'high));
        position_values(0, 0) := 0;

        -- Next, update positions next to starting position.
        new_update_positions := update_adjacent_positions(
            position_values, risk_levels, (0, 0)
            );
        update_positions.positions(0 to 3) := new_update_positions.positions;
        update_positions.length            := new_update_positions.length;

        -- Increase update area incrementally.
        for AREA_SIZE in 10 to maximum(NUM_ROWS, NUM_COLS) loop
            -- Update positions until all remaining positions are outside of
            -- update area.
            update_positions_index := 0;
            while update_positions_index < update_positions.length loop
                update_position := (
                    update_positions.positions(update_positions_index)
                    );
                if maximum(update_position(1), update_position(2)) < AREA_SIZE then
                    -- Calculate position value from adjacent values
                    -- and update position if value has changed.
                    position_value := calculate_position_value(
                        risk_levels, position_values, update_position
                        );
                    if position_value /=
                        position_values(update_position(1), update_position(2)) then
                        -- Update position with new value and
                        -- check update of adjacent positions. 
                        position_values(
                        update_position(1), update_position(2)
                        )                    := position_value;
                        new_update_positions := update_adjacent_positions(
                            position_values, risk_levels, update_position
                            );
                        for I in 0 to new_update_positions.length - 1 loop
                            new_update_position := new_update_positions.positions(I);
                            -- Skip position if it won't be reduces by update.
                            if position_values(
                                new_update_position(1), new_update_position(2)
                                ) <= (
                                position_value +
                                position_risk_level(risk_levels, new_update_position)
                                ) then
                                next;
                            end if;
                            -- Only add positions that are not in the list already.
                            found := false;
                            for J in 0 to update_positions.length - 1 loop
                                if update_positions.positions(J) =
                                    new_update_position then
                                    found := true;
                                    exit;
                                end if;
                            end loop;
                            if not found then
                                update_positions.positions(
                                update_positions.length) := new_update_position;
                                update_positions.length  := update_positions.length + 1;
                            end if;
                        end loop;
                    end if;
                    -- Replace handled entry with last entry.
                    update_positions.positions(update_positions_index) :=
                    update_positions.positions(update_positions.length - 1);
                    update_positions.length := update_positions.length - 1;
                else
                    -- Advance to next entry.
                    update_positions_index := update_positions_index + 1;
                end if;
            end loop;
        end loop;

        -- Return resulting value of bottom right position.
        return position_values(position_values'high(1), position_values'high(2));
    end function;

begin

    process
        type risk_levels_ptr_t is access risk_levels_t;
        variable risk_levels_ptr : risk_levels_ptr_t;

        file i_file     : text;
        variable i_line : line;
        variable value  : natural;
        variable char   : character;
        variable row    : natural;

        variable result : natural;
    begin
        report (
            "Size of risk level map in example input: " &
            integer'image(EXAMPLE_RISK_LEVELS'length(1)) & "x" &
            integer'image(EXAMPLE_RISK_LEVELS'length(2))
            );

        -- Load risk levels map from input file
        file_open(i_file, "inputs/day_15.txt", read_mode);
        row := 0;
        while not endfile(i_file) loop
            readline(i_file, i_line);
            if risk_levels_ptr = null then
                -- Assume square map
                risk_levels_ptr := new risk_levels_t(0 to i_line'length - 1, 0 to i_line'length - 1);
            end if;
            -- Load row of digits from line
            for COL in 0 to i_line'length - 1 loop
                read(i_line, char);
                risk_levels_ptr(row, COL) := character'pos(char) - character'pos('0');
            end loop;
            row := row + 1;
        end loop;
        file_close(i_file);
        report (
            "Size of risk level map in input file: " &
            integer'image(risk_levels_ptr'length(1)) & "x" &
            integer'image(risk_levels_ptr'length(2))
            );

        report "*** Part One ***";

        result := lowest_total_risk_path(EXAMPLE_RISK_LEVELS, PART_ONE);
        report "Lowest total risk path for example input: " & integer'image(result);
        assert result = 40;

        result := lowest_total_risk_path(risk_levels_ptr.all, PART_ONE);
        report "Lowest total risk path for puzzle input: " & integer'image(result);
        assert result = 363;

        report "*** Part Two ***";

        result := lowest_total_risk_path(EXAMPLE_RISK_LEVELS, PART_TWO);
        report "Lowest total risk path for example input: " & integer'image(result);
        assert result = 315;

        result := lowest_total_risk_path(risk_levels_ptr.all, PART_TWO);
        report "Lowest total risk path for puzzle input: " & integer'image(result);
        assert result = 2835;

        deallocate(risk_levels_ptr);
        wait;
    end process;

end architecture;
