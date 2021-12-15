-- Solution for Advent of Code 2021, day 9

entity day_09 is
end entity;

use std.textio.all;

architecture simulation of day_09 is

    type heightmap_t is array (natural range <>, natural range <>) of natural;

    constant EXAMPLE_HEIGHTMAP : heightmap_t :=
    (
        (2, 1, 9, 9, 9, 4, 3, 2, 1, 0),
        (3, 9, 8, 7, 8, 9, 4, 9, 2, 1),
        (9, 8, 5, 6, 7, 8, 9, 8, 9, 2),
        (8, 7, 6, 7, 8, 9, 6, 7, 8, 9),
        (9, 8, 9, 9, 9, 6, 5, 6, 7, 8)
    );

    -- Check if given location is a low point
    function is_low_point(
        heightmap : heightmap_t;
        row       : natural;
        col       : natural
    ) return boolean is
        variable height : natural;
    begin
        height := heightmap(row, col);
        -- Check adjacent points
        if row > 0 and heightmap(row - 1, col) <= height then
            -- Not a low point as up is at least as low
            return false;
        elsif col > 0 and heightmap(row, col - 1) <= height then
            -- Not a low point as left is at least as low
            return false;
        elsif col < heightmap'length(2) - 1 and heightmap(row, col + 1) <= height then
            -- Not a low point as right is at least as low
            return false;
        elsif row < heightmap'length(1) - 1 and heightmap(row + 1, col) <= height then
            -- Not a low point as down is at least as low
            return false;
        end if;
        -- Low point as all adjacent points are higher.
        return true;
    end function;

    -- Part One: Calculate sum of low point's risk levels for given heightmap
    function calculate_risk_level_sum(
        heightmap : heightmap_t
    ) return natural is
        variable risk_level : natural;
        variable result     : natural;
    begin
        result := 0;
        for ROW in heightmap'range(1) loop
            for COL in heightmap'range(2) loop
                if is_low_point(heightmap, ROW, COL) then
                    -- Add risk level of low point to resulting sum
                    risk_level := 1 + heightmap(ROW, COL);
                    result     := result + risk_level;
                end if;
            end loop;
        end loop;
        return result;
    end function;

    -- Types used by flooding algorithm
    type flooding_map_t is array(natural range <>, natural range <>) of boolean;
    type flooding_state_t is record
        flooding_map  : flooding_map_t;
        flooding_size : natural;
    end record;

    -- Recursive flooding algorithm
    function perform_flooding(
        heightmap      : heightmap_t;
        flooding_state : flooding_state_t;
        row            : natural;
        col            : natural
    ) return flooding_state_t is
        variable new_state : flooding_state_t(
        flooding_map(heightmap'range(1), heightmap'range(2))
        );
    begin
        new_state := flooding_state;

        -- Flood current position
        new_state.flooding_map(row, col) := true;
        new_state.flooding_size          := new_state.flooding_size + 1;

        -- Check and flood adjacent positions
        if row > 0 then
            -- Check UP
            if not new_state.flooding_map(row - 1, col) and heightmap(row - 1, col) /= 9 then
                -- Continue flooding as position is not yet flooded and does not contain a 9
                new_state := perform_flooding(heightmap, new_state, row - 1, col);
            end if;
        end if;
        if col > 0 then
            -- Check LEFT
            if not new_state.flooding_map(row, col - 1) and heightmap(row, col - 1) /= 9 then
                -- Continue flooding as position is not yet flooded and does not contain a 9
                new_state := perform_flooding(heightmap, new_state, row, col - 1);
            end if;
        end if;
        if col < heightmap'length(2) - 1 then
            -- Check RIGHT
            if not new_state.flooding_map(row, col + 1) and heightmap(row, col + 1) /= 9 then
                -- Continue flooding as position is not yet flooded and does not contain a 9
                new_state := perform_flooding(heightmap, new_state, row, col + 1);
            end if;
        end if;
        if row < heightmap'length(1) - 1 then
            -- Check DOWN
            if not new_state.flooding_map(row + 1, col) and heightmap(row + 1, col) /= 9 then
                -- Continue flooding as position is not yet flooded and does not contain a 9
                new_state := perform_flooding(heightmap, new_state, row + 1, col);
            end if;
        end if;

        return new_state;
    end function;

    -- Calculate size of basin around given low point
    function calculate_basin_size(
        heightmap : heightmap_t;
        row       : natural;
        col       : natural
    ) return natural is
        variable flooding_state : flooding_state_t(
        flooding_map(heightmap'range(1), heightmap'range(2))
        );
    begin
        -- Run flooding algorithm on low point and return resulting flooding size
        flooding_state := perform_flooding(heightmap, flooding_state, row, col);
        return flooding_state.flooding_size;
    end function;

    -- Part Two: Calculate product of the sizes of the three largest basins
    function calculate_basin_size_product(
        heightmap : heightmap_t
    ) return natural is
        variable basin_size     : natural;
        variable largest_basins : integer_vector(0 to 2);
        variable smallest_index : natural;
    begin
        for ROW in heightmap'range(1) loop
            for COL in heightmap'range(2) loop
                if is_low_point(heightmap, ROW, COL) then
                    -- Determine basin size for this low point
                    basin_size := calculate_basin_size(heightmap, ROW, COL);

                    -- Find index of smallest basin in vector
                    smallest_index := 0;
                    for I in largest_basins'range loop
                        if largest_basins(I) < largest_basins(smallest_index) then
                            smallest_index := I;
                        end if;
                    end loop;
                    -- Update value in vector if basin is larger
                    if basin_size > largest_basins(smallest_index) then
                        largest_basins(smallest_index) := basin_size;
                    end if;
                end if;
            end loop;
        end loop;
        -- Return product of largest three basins
        return largest_basins(0) * largest_basins(1) * largest_basins(2);
    end function;

begin

    process
        type heightmap_ptr_t is access heightmap_t;
        variable heightmap_ptr : heightmap_ptr_t;

        file i_file     : text;
        variable i_line : line;
        variable value  : natural;
        variable char   : character;
        variable row    : natural;

        variable result : natural;
    begin
        report (
            "Size of heightmap in example input: " &
            integer'image(EXAMPLE_HEIGHTMAP'length(1)) & "x" &
            integer'image(EXAMPLE_HEIGHTMAP'length(2))
            );

        -- Load heightmap from input file
        file_open(i_file, "inputs/day_09.txt", read_mode);
        row := 0;
        while not endfile(i_file) loop
            readline(i_file, i_line);
            if heightmap_ptr = null then
                -- Assume square heightmap
                heightmap_ptr := new heightmap_t(0 to i_line'length - 1, 0 to i_line'length - 1);
            end if;
            -- Load row of digits from line
            for COL in 0 to i_line'length - 1 loop
                read(i_line, char);
                heightmap_ptr(row, COL) := character'pos(char) - character'pos('0');
            end loop;
            row := row + 1;
        end loop;
        file_close(i_file);
        report (
            "Size of heightmap in input file: " &
            integer'image(heightmap_ptr'length(1)) & "x" &
            integer'image(heightmap_ptr'length(2))
            );

        report "*** Part One ***";

        result := calculate_risk_level_sum(EXAMPLE_HEIGHTMAP);
        report "Risk level of example input: " & integer'image(result);
        assert result = 15;

        result := calculate_risk_level_sum(heightmap_ptr.all);
        report "Risk level of input file: " & integer'image(result);
        assert result = 423;

        report "*** Part Two ***";

        result := calculate_basin_size_product(EXAMPLE_HEIGHTMAP);
        report "Basin size product of example input: " & integer'image(result);
        assert result = 1134;

        result := calculate_basin_size_product(heightmap_ptr.all);
        report "Basin size product of input file: " & integer'image(result);
        assert result = 1198704;

        deallocate(heightmap_ptr);
        wait;
    end process;

end architecture;