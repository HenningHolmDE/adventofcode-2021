-- Solution for Advent of Code 2021, day 5

entity day_05 is
end entity;

use std.textio.all;

architecture simulation of day_05 is

    type line_t is record
        x1 : natural;
        y1 : natural;
        x2 : natural;
        y2 : natural;
    end record;
    type lines_t is array(natural range <>) of line_t;

    constant EXAMPLE_LINES : lines_t :=
    (
        (0, 9, 5, 9),
        (8, 0, 0, 8),
        (9, 4, 3, 4),
        (2, 2, 2, 1),
        (7, 0, 7, 4),
        (6, 4, 2, 0),
        (0, 9, 2, 9),
        (3, 4, 1, 4),
        (0, 0, 8, 8),
        (5, 5, 8, 2)
    );

    -- Check if line is horizontal or vertical
    function is_horizontal_or_vertical(
        line1 : line_t
    ) return boolean is
    begin
        return line1.x1 = line1.x2 or line1.y1 = line1.y2;
    end function;

    -- Get maximum X value of lines
    function maximum_x(
        lines : lines_t
    ) return natural is
        variable result : natural;
    begin
        for LINE_INDEX in lines'range loop
            if lines(LINE_INDEX).x1 > result then
                result := lines(LINE_INDEX).x1;
            end if;
            if lines(LINE_INDEX).x2 > result then
                result := lines(LINE_INDEX).x2;
            end if;
        end loop;
        return result;
    end function;

    -- Get maximum Y value of lines
    function maximum_y(
        lines : lines_t
    ) return natural is
        variable result : natural;
    begin
        for LINE_INDEX in lines'range loop
            if lines(LINE_INDEX).y1 > result then
                result := lines(LINE_INDEX).y1;
            end if;
            if lines(LINE_INDEX).y2 > result then
                result := lines(LINE_INDEX).y2;
            end if;
        end loop;
        return result;
    end function;

    type overlaps_t is array(natural range <>, natural range <>) of natural;

    -- Calculate line overlaps
    function calculate_overlaps_for_horizontal_and_vertical_lines(
        lines : lines_t
    ) return overlaps_t is
        variable line1    : line_t;
        variable overlaps : overlaps_t(0 to maximum_x(lines), 0 to maximum_y(lines));
    begin
        for LINE_INDEX in lines'range loop
            line1 := lines(LINE_INDEX);
            if is_horizontal_or_vertical(line1) then
                for X in minimum(line1.x1, line1.x2) to maximum(line1.x1, line1.x2) loop
                    for Y in minimum(line1.y1, line1.y2) to maximum(line1.y1, line1.y2) loop
                        overlaps(X, Y) := overlaps(X, Y) + 1;
                    end loop;
                end loop;
            end if;
        end loop;
        return overlaps;
    end function;

    -- Check for points with at least two overlaps
    function count_dangerous_points(
        overlaps : overlaps_t
    ) return natural is
        variable result : natural;
    begin
        result := 0;
        for X in overlaps'range(1) loop
            for Y in overlaps'range(2) loop
                if overlaps(X, Y) >= 2 then
                    result := result + 1;
                end if;
            end loop;
        end loop;

        return result;
    end function;

    -- Part One: Number of points where at least two horizontal or vertical lines overlap.
    function number_of_dangerous_areas_part1(
        lines : lines_t
    ) return natural is
        variable line1    : line_t;
        variable overlaps : overlaps_t(0 to maximum_x(lines), 0 to maximum_y(lines));
    begin
        overlaps := calculate_overlaps_for_horizontal_and_vertical_lines(lines);

        return count_dangerous_points(overlaps);
    end function;

    -- Part Two: Number of points where at least two of all lines overlap.
    function number_of_dangerous_areas_part2(
        lines : lines_t
    ) return natural is
        variable overlaps        : overlaps_t(0 to maximum_x(lines), 0 to maximum_y(lines));
        variable line1           : line_t;
        variable diagonal_length : natural;
        variable diagonal_x      : natural;
        variable diagonal_y      : natural;
        variable result          : natural;
    begin
        overlaps := calculate_overlaps_for_horizontal_and_vertical_lines(lines);

        -- add overlaps for diagonal lines
        for LINE_INDEX in lines'range loop
            line1 := lines(LINE_INDEX);
            if not is_horizontal_or_vertical(line1) then
                diagonal_length := maximum(line1.x1, line1.x2) - minimum(line1.x1, line1.x2);
                for DIAGONAL_INC in 0 to diagonal_length loop
                    if line1.x1 > line1.x2 then
                        diagonal_x := line1.x1 - DIAGONAL_INC;
                    else
                        diagonal_x := line1.x1 + DIAGONAL_INC;
                    end if;
                    if line1.y1 > line1.y2 then
                        diagonal_y := line1.y1 - DIAGONAL_INC;
                    else
                        diagonal_y := line1.y1 + DIAGONAL_INC;
                    end if;
                    overlaps(diagonal_x, diagonal_y) := overlaps(diagonal_x, diagonal_y) + 1;
                end loop;
            end if;
        end loop;

        return count_dangerous_points(overlaps);
    end function;

begin

    process
        file i_file     : text;
        variable i_line : line;

        variable x1, y1, x2, y2 : natural;
        variable char           : character;
        variable line1          : line_t;
        type lines_ptr_t is access lines_t;
        variable lines_ptr     : lines_ptr_t;
        variable lines_ptr_old : lines_ptr_t;

        variable result : natural;
    begin
        -- load lines from input file
        file_open(i_file, "inputs/day_05.txt", read_mode);
        while not endfile(i_file) loop
            readline(i_file, i_line);
            -- parse line of input file into line_t
            read(i_line, x1);
            read(i_line, char); -- read ','
            read(i_line, y1);
            for I in 0 to 3 loop
                read(i_line, char); -- read ' ', '-', '>', ' '
            end loop;
            read(i_line, x2);
            read(i_line, char); -- read ','
            read(i_line, y2);
            line1 := (x1, y1, x2, y2);

            -- append line to vector
            if lines_ptr = null then
                lines_ptr := new lines_t'(0 => line1);
            else
                lines_ptr_old := lines_ptr;
                lines_ptr     := new lines_t'(lines_ptr.all & line1);
                deallocate(lines_ptr_old);
            end if;
        end loop;
        file_close(i_file);
        report "Number of lines in example input: " & integer'image(EXAMPLE_LINES'length);
        report "Number of lines in input file: " & integer'image(lines_ptr.all'length);

        report "*** Part One ***";

        result := number_of_dangerous_areas_part1(EXAMPLE_LINES);
        report "Number of dangerous areas in example input: " & integer'image(result);
        assert result = 5;

        result := number_of_dangerous_areas_part1(lines_ptr.all);
        report "Number of dangerous areas in input file: " & integer'image(result);
        assert result = 6548;

        report "*** Part Two ***";

        result := number_of_dangerous_areas_part2(EXAMPLE_LINES);
        report "Number of dangerous areas in example input: " & integer'image(result);
        assert result = 12;

        result := number_of_dangerous_areas_part2(lines_ptr.all);
        report "Number of dangerous areas in input file: " & integer'image(result);
        assert result = 19663;

        deallocate(lines_ptr);
        wait;
    end process;

end architecture;