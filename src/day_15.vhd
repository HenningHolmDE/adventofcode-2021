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

    type update_positions_t is array(natural range <>, natural range <>) of boolean;
    type part_t is (PART_ONE, PART_TWO);

    -- Determine risk level of position in tiled cave.
    function position_risk_level(
        risk_levels : risk_levels_t;
        row, col    : natural
    ) return natural is
        variable result : natural;
    begin
        result := risk_levels(
            row mod risk_levels'length(1),
            col mod risk_levels'length(2)
            );
        result := result + row / risk_levels'length(1);
        result := result + col / risk_levels'length(2);
        result := ((result - 1) mod 9) + 1;
        return result;
    end function;

    -- Enable update for positions adjacent to given position. 
    function update_adjacent_positions(
        update_positions : update_positions_t;
        position_values  : risk_levels_t;
        risk_levels      : risk_levels_t;
        row, col         : natural
    ) return update_positions_t is
        variable result : update_positions_t(
        update_positions'range(1), update_positions'range(2)
        );
        variable position_value     : natural;
        variable adj_position_value : natural;
        variable adj_risk_level     : natural;
    begin
        result         := update_positions;
        position_value := position_values(row, col);
        if row > 0 then
            adj_position_value := position_values(row - 1, col);
            adj_risk_level     := position_risk_level(risk_levels, row - 1, col);
            if adj_position_value > position_value + adj_risk_level then
                result(row - 1, col) := true;
            end if;
        end if;
        if col > 0 then
            adj_position_value := position_values(row, col - 1);
            adj_risk_level     := position_risk_level(risk_levels, row, col - 1);
            if adj_position_value > position_value + adj_risk_level then
                result(row, col - 1) := true;
            end if;
        end if;
        if row < update_positions'high(1) then
            adj_position_value := position_values(row + 1, col);
            adj_risk_level     := position_risk_level(risk_levels, row + 1, col);
            if adj_position_value > position_value + adj_risk_level then
                result(row + 1, col) := true;
            end if;
        end if;
        if col < update_positions'high(2) then
            adj_position_value := position_values(row, col + 1);
            adj_risk_level     := position_risk_level(risk_levels, row, col + 1);
            if adj_position_value > position_value + adj_risk_level then
                result(row, col + 1) := true;
            end if;
        end if;
        return result;
    end function;

    -- Calculate value for given position from minimum adjacent value
    -- increased by risk level of position.
    function calculate_position_value(
        risk_levels     : risk_levels_t;
        position_values : risk_levels_t;
        row, col        : natural
    ) return natural is
        variable minimum_adjacent_value : natural;
        variable risk_level             : natural;
    begin
        if row = 0 and col = 0 then
            -- Starting position has not to be entered.
            return 0;
        end if;
        minimum_adjacent_value := integer'high;
        if row > 0 then
            minimum_adjacent_value := minimum(
                minimum_adjacent_value, position_values(row - 1, col)
                );
        end if;
        if col > 0 then
            minimum_adjacent_value := minimum(
                minimum_adjacent_value, position_values(row, col - 1)
                );
        end if;
        if row < position_values'high(1) then
            minimum_adjacent_value := minimum(
                minimum_adjacent_value, position_values(row + 1, col)
                );
        end if;
        if col < position_values'high(2) then
            minimum_adjacent_value := minimum(
                minimum_adjacent_value, position_values(row, col + 1)
                );
        end if;

        -- Increase minimum adjacent value by risk level of position.
        return (
        minimum_adjacent_value +
        position_risk_level(risk_levels, row, col)
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
        variable update_positions : update_positions_t(
        0 to NUM_ROWS - 1, 0 to NUM_COLS - 1
        );
        variable update_any_position : boolean;
        variable update_area_size    : natural;
        variable position_value      : natural;
    begin
        -- Starting position has not to be entered.
        position_values       := (others => (others => natural'high));
        position_values(0, 0) := 0;

        -- Next, update positions next to starting position.
        update_positions := (others => (others => false));
        update_positions := update_adjacent_positions(
            update_positions, position_values, risk_levels, 0, 0
            );
        update_any_position := true;
        update_area_size    := 10;

        -- Update designated positions until no values changed.
        while update_any_position loop
            update_any_position := false;
            for ROW in 0 to minimum(update_area_size, NUM_ROWS) - 1 loop
                for COL in 0 to minimum(update_area_size, NUM_COLS) - 1 loop
                    if update_positions(ROW, COL) then
                        update_positions(ROW, COL) := false;
                        -- Calculate position value from adjacent values
                        -- and update position if value has changed.
                        position_value := calculate_position_value(
                            risk_levels, position_values, row, col
                            );
                        if position_value /= position_values(row, col) then
                            -- Update position with new value and
                            -- request update of adjacent positions. 
                            position_values(row, col) := position_value;
                            update_positions          := update_adjacent_positions(
                                update_positions, position_values, risk_levels, row, col
                                );
                            update_any_position := true;
                        end if;
                    end if;
                end loop;
            end loop;
            -- Increase update area size.
            if update_area_size < maximum(NUM_ROWS, NUM_COLS) then
                update_area_size    := update_area_size + 1;
                update_any_position := true;
            end if;
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
