-- Solution for Advent of Code 2021, day 13

entity day_13 is
end entity;

use std.textio.all;

architecture simulation of day_13 is

    subtype dot_t is integer_vector(0 to 1);
    type dots_t is array(natural range <>) of dot_t;
    type direction_t is (DIR_X, DIR_Y);
    type fold_t is record
        direction : direction_t;
        position  : natural;
    end record;
    type folds_t is array(natural range <>) of fold_t;
    type input_t is record
        dots  : dots_t;
        folds : folds_t;
    end record;

    constant EXAMPLE_INPUT : input_t :=
    (
    (
    (6, 10),
    (0, 14),
    (9, 10),
    (0, 3),
    (10, 4),
    (4, 11),
    (6, 0),
    (6, 12),
    (4, 1),
    (0, 13),
    (10, 12),
    (3, 4),
    (3, 0),
    (8, 4),
    (1, 10),
    (2, 14),
    (8, 10),
    (9, 0)
    ),
    (
    (DIR_Y, 7),
    (DIR_X, 5)
    )
    );

    -- Fold dots according to fold instruction into upper/left half.
    function fold_dots(
        dots : dots_t;
        fold : fold_t
    ) return dots_t is
        variable dots1          : dots_t(0 to dots'length - 1);
        variable invisble_count : natural;
        variable temp_dot       : dot_t;
    begin
        dots1          := dots;
        invisble_count := 0;
        for DI in dots1'range loop
            -- Fold dot into new position.
            if fold.direction = DIR_X and dots1(DI)(0) > fold.position then
                dots1(DI)(0) := 2 * fold.position - dots1(DI)(0);
            elsif fold.direction = DIR_Y and dots1(DI)(1) > fold.position then
                dots1(DI)(1) := 2 * fold.position - dots1(DI)(1);
            else
                next;
            end if;
            -- Handle invisible dots.
            for DJ in invisble_count to dots1'right loop
                if DJ = DI then
                    next;
                end if;
                if dots1(DJ) = dots1(DI) then
                    -- Dot has become invisible, swap with first visible dot.
                    temp_dot              := dots1(invisble_count);
                    dots1(invisble_count) := dots1(DI);
                    dots1(DI)             := temp_dot;
                    invisble_count        := invisble_count + 1;
                    exit;
                end if;
            end loop;
        end loop;
        -- Only return visible dots.
        return dots1(invisble_count to dots1'right);
    end function;

    -- Return the number of dots visible after first fold.
    function dots_visible_after_first_fold(
        input1 : input_t
    ) return natural is
        constant FOLDED_DOTS : dots_t := (
            fold_dots(input1.dots, input1.folds(0))
        );
    begin
        return FOLDED_DOTS'length;
    end function;

    -- Extract maximum coordinates from dots.
    function maximum_coordinates(
        dots : dots_t
    ) return dot_t is
        variable result : dot_t;
    begin
        result := (0, 0);
        for I in dots'range loop
            result(0) := maximum(result(0), dots(I)(0));
            result(1) := maximum(result(1), dots(I)(1));
        end loop;
        return result;
    end function;

    -- Display dots figure.
    procedure display_dots(
        dots : dots_t
    ) is
        constant MAX_COORDS : dot_t := maximum_coordinates(dots);
        variable linestr    : string(1 to 1 + MAX_COORDS(0));
    begin
        for Y in 0 to MAX_COORDS(1) loop
            linestr := (others => '.');
            for X in 0 to MAX_COORDS(0) loop
                for I in dots'range loop
                    if dots(I) = (X, Y) then
                        linestr(X + 1) := '#';
                        exit;
                    end if;
                end loop;
            end loop;
            report linestr;
        end loop;
    end procedure;

    -- Display the resulting figure after applying all folds.
    procedure display_dots_after_folding(
        input1 : input_t
    ) is
        type dots_ptr_t is access dots_t;
        variable dots_ptr     : dots_ptr_t;
        variable dots_ptr_old : dots_ptr_t;
    begin
        dots_ptr := new dots_t'(input1.dots);

        -- Perform folding.
        for FOLD_INDEX in 0 to input1.folds'right loop
            dots_ptr_old := dots_ptr;
            dots_ptr     := new dots_t'(
                fold_dots(dots_ptr.all, input1.folds(FOLD_INDEX))
                );
            deallocate(dots_ptr_old);
        end loop;

        display_dots(dots_ptr.all);
        deallocate(dots_ptr);
    end procedure;
begin

    process
        file i_file              : text;
        variable i_line          : line;
        variable number_of_dots  : natural;
        variable number_of_folds : natural;

        type input_ptr_t is access input_t;
        variable input_ptr    : input_ptr_t;
        variable index        : natural;
        variable dot_x, dot_y : natural;
        variable char         : character;
        variable direction    : direction_t;
        variable position     : natural;

        variable result : natural;
    begin
        report "Number of dots in example input: " & integer'image(EXAMPLE_INPUT.dots'length);
        report "Number of folds in example input: " & integer'image(EXAMPLE_INPUT.folds'length);

        -- Read input file once to get number of dots and folds.
        file_open(i_file, "inputs/day_13.txt", read_mode);
        number_of_dots := 0;
        while not endfile(i_file) loop
            readline(i_file, i_line);
            if i_line'length = 0 then
                -- End of dots section.
                exit;
            end if;
            number_of_dots := number_of_dots + 1;
        end loop;
        number_of_folds := 0;
        while not endfile(i_file) loop
            readline(i_file, i_line);
            number_of_folds := number_of_folds + 1;
        end loop;
        file_close(i_file);

        input_ptr := new input_t(dots(0 to number_of_dots - 1), folds(0 to number_of_folds - 1));

        -- Read input file again to extract data.
        file_open(i_file, "inputs/day_13.txt", read_mode);
        index := 0;
        while not endfile(i_file) loop
            readline(i_file, i_line);
            if i_line'length = 0 then
                -- End of dots section.
                exit;
            end if;
            read(i_line, dot_x);
            read(i_line, char);
            read(i_line, dot_y);
            input_ptr.dots(index) := (dot_x, dot_y);
            index                 := index + 1;
        end loop;
        index := 0;
        while not endfile(i_file) loop
            readline(i_file, i_line);
            -- Skip the start of "fold along y" and get 'x' or 'y'.
            for I in 1 to 12 loop
                read(i_line, char);
            end loop;
            if char = 'x' then
                direction := DIR_X;
            else
                direction := DIR_Y;
            end if;
            read(i_line, char); -- skip '='
            read(i_line, position);
            input_ptr.folds(index) := (direction, position);
            index                  := index + 1;
        end loop;
        file_close(i_file);

        report "Number of dots in input file: " & integer'image(input_ptr.dots'length);
        report "Number of folds in input file: " & integer'image(input_ptr.folds'length);

        report "*** Part One ***";

        result := dots_visible_after_first_fold(EXAMPLE_INPUT);
        report "Number of visible dots after first fold of example input: " & integer'image(result);
        assert result = 17;

        result := dots_visible_after_first_fold(input_ptr.all);
        report "Number of visible dots after first fold of input file: " & integer'image(result);
        assert result = 847;

        report "*** Part Two ***";

        report "Result after folding example input:";
        display_dots_after_folding(EXAMPLE_INPUT);

        report "Result after folding input from file:";
        display_dots_after_folding(input_ptr.all);

        deallocate(input_ptr);
        wait;
    end process;

end architecture;
