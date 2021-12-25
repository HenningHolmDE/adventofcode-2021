-- Solution for Advent of Code 2021, day 12

entity day_12 is
end entity;

use std.textio.all;

architecture simulation of day_12 is

    type string_vector_t is array (natural range <>) of string;

    constant EXAMPLE_INPUT_1 : string_vector_t :=
    (
    "start-A",
    "start-b",
    "A-c    ",
    "A-b    ",
    "b-d    ",
    "A-end  ",
    "b-end  "
    );

    constant EXAMPLE_INPUT_2 : string_vector_t :=
    (
    "dc-end  ",
    "HN-start",
    "start-kj",
    "dc-start",
    "dc-HN   ",
    "LN-dc   ",
    "HN-end  ",
    "kj-sa   ",
    "kj-HN   ",
    "kj-dc   "
    );

    constant EXAMPLE_INPUT_3 : string_vector_t :=
    (
    "fs-end  ",
    "he-DX   ",
    "fs-he   ",
    "start-DX",
    "pj-DX   ",
    "end-zg  ",
    "zg-sl   ",
    "zg-pj   ",
    "pj-he   ",
    "RW-he   ",
    "fs-DX   ",
    "pj-RW   ",
    "zg-RW   ",
    "start-pj",
    "he-WI   ",
    "zg-he   ",
    "pj-fs   ",
    "start-RW"
    );

    type string_len_t is record
        str : string(1 to 100); -- This should be long enough.
        len : natural;
    end record;
    type string_len_vector_t is array(natural range <>) of string_len_t;

    type cave_type_t is (CAVE_START, CAVE_END, CAVE_BIG, CAVE_SMALL);
    type cave_type_vector_t is array (natural range <>) of cave_type_t;

    type connection_t is record
        a : natural;
        b : natural;
    end record;
    type connection_vector_t is array(natural range <>) of connection_t;

    type cave_data_t is record
        names       : string_len_vector_t;
        types       : cave_type_vector_t;
        connections : connection_vector_t;
    end record;

    function parse_cave_data(
        lines : string_vector_t
    ) return cave_data_t is
        -- Allocate vectors with number of lines as an upper bound.
        variable result : cave_data_t(
        names(0 to lines'length - 1),
        types(0 to lines'length - 1),
        connections(0 to lines'length - 1)
        );
        variable number_of_caves : positive;
        variable dash_position   : positive;
        variable line_length     : positive;
        variable start_index     : positive;
        variable end_index       : positive;
        variable len             : positive;
        variable found           : boolean;
        variable cave_index      : natural;
        variable conn_a          : natural;
    begin
        -- Define start and end first.
        result.names(0).len         := 5;
        result.names(0).str(1 to 5) := "start";
        result.types(0)             := CAVE_START;
        result.names(1).len         := 3;
        result.names(1).str(1 to 3) := "end";
        result.types(1)             := CAVE_END;
        number_of_caves             := 2;
        for LINE_INDEX in lines'range loop
            -- Determine line length and position of dash.
            line_length := lines(LINE_INDEX)'length;
            line_length_l : for I in lines(LINE_INDEX)'range loop
                if lines(LINE_INDEX)(I) = '-' then
                    dash_position := I;
                elsif lines(LINE_INDEX)(I) = ' ' then
                    line_length := I - 1;
                    exit line_length_l;
                end if;
            end loop;
            -- Add caves to list if not yet contained.
            for WORD in 1 to 2 loop
                if WORD = 1 then
                    start_index := 1;
                    end_index   := dash_position - 1;
                else
                    start_index := dash_position + 1;
                    end_index   := line_length;
                end if;
                len   := 1 + end_index - start_index;
                found := false;
                for I in 0 to number_of_caves - 1 loop
                    if len = result.names(I).len then
                        if lines(LINE_INDEX)(start_index to end_index) =
                            result.names(I).str(1 to result.names(I).len) then
                            cave_index := I;
                            found      := true;
                            exit;
                        end if;
                    end if;
                end loop;
                if not found then
                    -- Add cave to list.
                    cave_index                             := number_of_caves;
                    result.names(cave_index).str(1 to len) := lines(LINE_INDEX)(start_index to end_index);
                    result.names(cave_index).len           := len;
                    -- Derive cave type from capitalization of first letter.
                    if lines(LINE_INDEX)(start_index) >= 'a' then
                        result.types(cave_index) := CAVE_SMALL;
                    else
                        result.types(cave_index) := CAVE_BIG;
                    end if;
                    number_of_caves := number_of_caves + 1;
                end if;
                if WORD = 1 then
                    conn_a := cave_index;
                else
                    -- Add connection to list.
                    result.connections(LINE_INDEX) := (conn_a, cave_index);
                end if;
            end loop;
        end loop;
        -- Return vectors with actual size.
        return (
        result.names(0 to number_of_caves - 1),
        result.types(0 to number_of_caves - 1),
        result.connections
        );
    end function;

    -- Return cave name of given index.
    function cave_name(
        cave_data : cave_data_t;
        index     : natural
    ) return string is
    begin
        return cave_data.names(index).str(1 to cave_data.names(index).len);
    end function;

    type part_t is (PART_ONE, PART_TWO);

    -- Recursive path finding through the caves.
    function number_of_paths_recurse(
        cave_data : cave_data_t;
        part      : part_t;
        trace     : integer_vector
    ) return natural is
        variable location           : natural;
        variable result             : natural;
        variable dest               : natural;
        variable allow_second_visit : boolean;
        variable already_visited    : boolean_vector(cave_data.types'range);
    begin
        location := trace(trace'right);
        -- Stop at the end.
        if location = 1 then
            return 1;
        end if;
        result := 0;
        -- Move into all connected caves when allowed to.
        conn_l : for CONN in cave_data.connections'range loop
            -- Check if connection links with current location.
            if cave_data.connections(CONN).a = location then
                dest := cave_data.connections(CONN).b;
            elsif cave_data.connections(CONN).b = location then
                dest := cave_data.connections(CONN).a;
            else
                next;
            end if;
            -- Found connection to dest, check if we are allowed to
            -- visit it (again). Big caves may always be revisted.
            if cave_data.types(dest) /= CAVE_BIG then
                -- Cave "start" may never be revisited.
                if cave_data.types(dest) = CAVE_START then
                    next conn_l;
                end if;

                -- In part two, one small cave may be revisited.
                if part = PART_TWO then
                    allow_second_visit := true;
                    already_visited    := (others => false);
                    for I in trace'range loop
                        if (
                            already_visited(trace(I)) and
                            cave_data.types(trace(I)) = CAVE_SMALL
                            ) then
                            -- One small cave has already been
                            -- visited twice.
                            allow_second_visit := false;
                            exit;
                        end if;
                        already_visited(trace(I)) := true;
                    end loop;
                else
                    allow_second_visit := false;
                end if;

                -- If no second visit is allowed, check if destination
                -- has been visited before.
                if not allow_second_visit then
                    for I in trace'range loop
                        if trace(I) = dest then
                            next conn_l;
                        end if;
                    end loop;
                end if;
            end if;
            -- Recurse into destination cave.
            result := result + number_of_paths_recurse(
                cave_data,
                part,
                trace & dest
                );
        end loop;
        return result;
    end function;

    -- Calculate number of paths through the caves.
    function number_of_paths(
        lines : string_vector_t;
        part  : part_t
    ) return natural is
        constant CAVE_DATA : cave_data_t := parse_cave_data(lines);
    begin
        return number_of_paths_recurse(
        CAVE_DATA,
        part,
        (0 => 0) -- Current position is "start"
        );
    end function;

begin

    process
        type string_vector_ptr_t is access string_vector_t;
        variable string_vector_ptr : string_vector_ptr_t;

        file i_file              : text;
        variable i_line          : line;
        variable max_line_length : natural;
        variable number_of_lines : natural;
        variable line_index      : natural;

        variable result : natural;
    begin
        -- Find out maximum line length and number of lines
        max_line_length := 0;
        number_of_lines := 0;
        file_open(i_file, "inputs/day_12.txt", read_mode);
        while not endfile(i_file) loop
            number_of_lines := number_of_lines + 1;
            readline(i_file, i_line);
            if i_line'length > max_line_length then
                max_line_length := i_line'length;
            end if;
        end loop;
        file_close(i_file);
        -- Read lines from input file
        string_vector_ptr := new string_vector_t(0 to number_of_lines - 1)(1 to max_line_length);
        line_index        := 0;
        file_open(i_file, "inputs/day_12.txt", read_mode);
        while not endfile(i_file) loop
            readline(i_file, i_line);
            string_vector_ptr(line_index)(1 to i_line'length)                   := i_line.all;
            string_vector_ptr(line_index)(i_line'length + 1 to max_line_length) := (others => ' ');
            line_index                                                          := line_index + 1;
        end loop;
        file_close(i_file);

        report "*** Part One ***";

        result := number_of_paths(EXAMPLE_INPUT_1, PART_ONE);
        report "Number of paths for example input 1: " & integer'image(result);
        assert result = 10;
        result := number_of_paths(EXAMPLE_INPUT_2, PART_ONE);
        report "Number of paths for example input 2: " & integer'image(result);
        assert result = 19;
        result := number_of_paths(EXAMPLE_INPUT_3, PART_ONE);
        report "Number of paths for example input 3: " & integer'image(result);
        assert result = 226;

        result := number_of_paths(string_vector_ptr.all, PART_ONE);
        report "Number of paths for input file: " & integer'image(result);
        assert result = 4573;

        report "*** Part Two ***";

        result := number_of_paths(EXAMPLE_INPUT_1, PART_TWO);
        report "Number of paths for example input 1: " & integer'image(result);
        assert result = 36;
        result := number_of_paths(EXAMPLE_INPUT_2, PART_TWO);
        report "Number of paths for example input 2: " & integer'image(result);
        assert result = 103;
        result := number_of_paths(EXAMPLE_INPUT_3, PART_TWO);
        report "Number of paths for example input 3: " & integer'image(result);
        assert result = 3509;

        result := number_of_paths(string_vector_ptr.all, PART_TWO);
        report "Number of paths for input file: " & integer'image(result);
        assert result = 117509;

        deallocate(string_vector_ptr);
        wait;
    end process;

end architecture;
