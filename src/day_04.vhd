-- Solution for Advent of Code 2021, day 4

entity day_04 is
end entity;

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture simulation of day_04 is

    constant EXAMPLE_DRAWN_NUMBERS : integer_vector :=
    (
        7, 4, 9, 5, 11, 17, 23, 2, 0, 14, 21, 24, 10, 16, 13, 6, 15, 25, 12, 22, 18, 20, 8, 19, 3, 26, 1
    );

    -- intermediate types for creating constant and parsing boards from input file
    type board_t is array (0 to 4, 0 to 4) of natural;
    type boards_t is array (natural range <>) of board_t;

    constant EXAMPLE_BOARDS : boards_t :=
    (
        (
        (22, 13, 17, 11, 0),
        (8, 2, 23, 4, 24),
        (21, 9, 14, 16, 7),
        (6, 10, 3, 18, 5),
        (1, 12, 20, 15, 19)
        ),
        (
        (3, 15, 0, 2, 22),
        (9, 18, 13, 17, 5),
        (19, 8, 7, 25, 23),
        (20, 11, 10, 24, 4),
        (14, 21, 16, 12, 6)
        ),
        (
        (14, 21, 17, 24, 4),
        (10, 16, 15, 9, 19),
        (18, 8, 23, 26, 20),
        (22, 11, 13, 6, 5),
        (2, 0, 12, 3, 7)
        )
    );

    type marked_number_t is record
        number : natural;
        marked : boolean;
    end record;
    type marked_board_t is array (0 to 4, 0 to 4) of marked_number_t;
    type marked_boards_t is array (natural range <>) of marked_board_t;
    type maybe_marked_board_t is record
        marked_board : marked_board_t;
        valid        : boolean;
    end record;

    -- convert boards_t into marked_boards_t
    function create_marked_boards(
        boards : boards_t
    ) return marked_boards_t is
        variable marked_boards : marked_boards_t(boards'range);
    begin
        for BOARD_INDEX in boards'range loop
            for ROW in 0 to 4 loop
                for COL in 0 to 4 loop
                    marked_boards(BOARD_INDEX)(ROW, COL).number := boards(BOARD_INDEX)(ROW, COL);
                end loop;
            end loop;
        end loop;
        return marked_boards;
    end function;

    -- mark drawn number on all boards
    function mark_drawn_number(
        marked_boards : marked_boards_t;
        drawn_number  : natural
    ) return marked_boards_t is
        variable result : marked_boards_t(marked_boards'range);
    begin
        result := marked_boards;
        for BOARD_INDEX in result'range loop
            for ROW in 0 to 4 loop
                for COL in 0 to 4 loop
                    if result(BOARD_INDEX)(ROW, COL).number = drawn_number then
                        result(BOARD_INDEX)(ROW, COL).marked := true;
                    end if;
                end loop;
            end loop;
        end loop;
        return result;
    end function;

    -- check board if the winning condition is met
    function is_winning_board(
        marked_board : marked_board_t
    ) return boolean is
        variable all_marked : boolean;
    begin
        -- check diagonal numbers first to speed up search
        for DIAGONAL in 0 to 4 loop
            if marked_board(DIAGONAL, DIAGONAL).marked then
                -- check row of diagonal number
                all_marked := true;
                if DIAGONAL > 0 then
                    for COL in 0 to DIAGONAL - 1 loop
                        all_marked := all_marked and marked_board(DIAGONAL, COL).marked;
                    end loop;
                end if;
                if DIAGONAL < 4 then
                    for COL in DIAGONAL + 1 to 4 loop
                        all_marked := all_marked and marked_board(DIAGONAL, COL).marked;
                    end loop;
                end if;
                if all_marked then
                    return true;
                end if;
                -- check column of diagonal number
                all_marked := true;
                if DIAGONAL > 0 then
                    for ROW in 0 to DIAGONAL - 1 loop
                        all_marked := all_marked and marked_board(ROW, DIAGONAL).marked;
                    end loop;
                end if;
                if DIAGONAL < 4 then
                    for ROW in DIAGONAL + 1 to 4 loop
                        all_marked := all_marked and marked_board(ROW, DIAGONAL).marked;
                    end loop;
                end if;
                if all_marked then
                    return true;
                end if;
            end if;
        end loop;
        return false;
    end function;

    -- return first board for which the winning condition is met (if any)
    function get_winning_board(
        marked_boards : marked_boards_t
    ) return maybe_marked_board_t is
    begin
        for BOARD_INDEX in marked_boards'range loop
            if is_winning_board(marked_boards(BOARD_INDEX)) then
                return (marked_boards(BOARD_INDEX), true);
            end if;
        end loop;
        return ((others => (others => (0, false))), false);
    end function;

    -- return sum of unmarked numbers
    function sum_of_unmarked(
        marked_board : marked_board_t
    ) return natural is
        variable result : natural;
    begin
        for ROW in 0 to 4 loop
            for COL in 0 to 4 loop
                if not marked_board(ROW, COL).marked then
                    result := result + marked_board(ROW, COL).number;
                end if;
            end loop;
        end loop;
        return result;
    end function;

    -- Part One: Calculate score of first winning board
    function calculate_score_part1(
        boards        : boards_t;
        drawn_numbers : integer_vector
    ) return natural is
        variable marked_boards      : marked_boards_t(boards'range);
        variable drawn_number       : natural;
        variable maybe_marked_board : maybe_marked_board_t;
    begin
        marked_boards := create_marked_boards(boards);
        draw_l : for I in drawn_numbers'range loop
            drawn_number       := drawn_numbers(I);
            marked_boards      := mark_drawn_number(marked_boards, drawn_number);
            maybe_marked_board := get_winning_board(marked_boards);
            if maybe_marked_board.valid then
                return drawn_number * sum_of_unmarked(maybe_marked_board.marked_board);
            end if;
        end loop;
        report "Drawn all numbers but found no winning board!" severity error;
        return 0;
    end function;

    -- Part Two: Calculate score of last winning board
    function calculate_score_part2(
        boards        : boards_t;
        drawn_numbers : integer_vector
    ) return natural is
        variable marked_boards      : marked_boards_t(boards'range);
        variable drawn_number       : natural;
        variable maybe_marked_board : maybe_marked_board_t;
        variable winning_boards     : boolean_vector(boards'range);
    begin
        marked_boards := create_marked_boards(boards);
        draw_l : for I in drawn_numbers'range loop
            drawn_number  := drawn_numbers(I);
            marked_boards := mark_drawn_number(marked_boards, drawn_number);
            for BOARD_INDEX in marked_boards'range loop
                if not winning_boards(BOARD_INDEX) and is_winning_board(marked_boards(BOARD_INDEX)) then
                    winning_boards(BOARD_INDEX) := true;
                    if and winning_boards then
                        -- all boards have now won, return score of this board
                        return drawn_number * sum_of_unmarked(marked_boards(BOARD_INDEX));
                    end if;
                end if;
            end loop;
        end loop;
        report "Drawn all numbers but not all boards won!" severity error;
        return 0;
    end function;

begin

    process
        file i_file     : text;
        variable i_line : line;

        type integer_vector_ptr_t is access integer_vector;
        variable drawn_numbers_ptr     : integer_vector_ptr_t;
        variable drawn_numbers_ptr_old : integer_vector_ptr_t;
        variable value                 : natural;
        variable char                  : character;
        variable good                  : boolean;

        type boards_ptr_t is access boards_t;
        variable row            : natural;
        variable board          : board_t;
        variable boards_ptr     : boards_ptr_t;
        variable boards_ptr_old : boards_ptr_t;

        variable result : natural;
    begin
        -- load data from input file
        file_open(i_file, "inputs/day_04.txt", read_mode);
        -- read drawn numbers (comma separated) from first line
        readline(i_file, i_line);
        good := true;
        while good loop
            read(i_line, value, good);
            if good then
                if drawn_numbers_ptr = null then
                    drawn_numbers_ptr := new integer_vector'(0 => value);
                else
                    drawn_numbers_ptr_old := drawn_numbers_ptr;
                    drawn_numbers_ptr     := new integer_vector'(drawn_numbers_ptr.all & value);
                    deallocate(drawn_numbers_ptr_old);
                end if;
                read(i_line, char, good);
                if good and char /= ',' then
                    good := false;
                end if;
            end if;
        end loop;
        -- read boards from subsequent lines
        row := 0;
        while not endfile(i_file) loop
            readline(i_file, i_line);
            if i_line.all'length > 0 then -- skip empty lines
                for COL in 0 to 4 loop
                    read(i_line, value);
                    board(row, COL) := value;
                end loop;
                if row = 4 then
                    -- append board to vector
                    if boards_ptr = null then
                        boards_ptr := new boards_t'(0 => board);
                    else
                        boards_ptr_old := boards_ptr;
                        boards_ptr     := new boards_t'(boards_ptr.all & board);
                        deallocate(boards_ptr_old);
                    end if;
                    row := 0;
                else
                    row := row + 1;
                end if;
            end if;
        end loop;
        file_close(i_file);
        report "Number of drawn numbers in example input: " & integer'image(EXAMPLE_DRAWN_NUMBERS'length);
        report "Number of bingo boards in example input: " & integer'image(EXAMPLE_BOARDS'length);
        report "Number of drawn numbers in input file: " & integer'image(drawn_numbers_ptr.all'length);
        report "Number of bingo boards in input file: " & integer'image(boards_ptr.all'length);

        report "*** Part One ***";

        result := calculate_score_part1(EXAMPLE_BOARDS, EXAMPLE_DRAWN_NUMBERS);
        report "Score for example input: " & integer'image(result);
        assert result = 4512;

        result := calculate_score_part1(boards_ptr.all, drawn_numbers_ptr.all);
        report "Score for input file: " & integer'image(result);

        report "*** Part Two ***";

        result := calculate_score_part2(EXAMPLE_BOARDS, EXAMPLE_DRAWN_NUMBERS);
        report "Score for example input: " & integer'image(result);
        assert result = 1924;

        result := calculate_score_part2(boards_ptr.all, drawn_numbers_ptr.all);
        report "Score for input file: " & integer'image(result);

        deallocate(drawn_numbers_ptr);
        deallocate(boards_ptr);
        wait;
    end process;

end architecture;