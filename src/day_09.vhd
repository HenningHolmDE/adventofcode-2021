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

        deallocate(heightmap_ptr);
        wait;
    end process;

end architecture;