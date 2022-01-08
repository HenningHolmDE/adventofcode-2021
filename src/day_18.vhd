-- Solution for Advent of Code 2021, day 18

entity day_18 is
end entity;

use std.textio.all;

architecture simulation of day_18 is

    type string_vector_t is array(natural range <>) of string;
    type sum_example_t is record
        addends : string_vector_t;
        sum     : string;
    end record;
    type magnitude_example_t is record
        number    : string;
        magnitude : natural;
    end record;

    constant SUM_EXAMPLE_1 : sum_example_t :=
    (
        ("[1,1]", "[2,2]", "[3,3]", "[4,4]"),
        "[[[[1,1],[2,2]],[3,3]],[4,4]]"
    );
    constant SUM_EXAMPLE_2 : sum_example_t :=
    (
        ("[1,1]", "[2,2]", "[3,3]", "[4,4]", "[5,5]"),
        "[[[[3,0],[5,3]],[4,4]],[5,5]]"
    );
    constant SUM_EXAMPLE_3 : sum_example_t :=
    (
        ("[1,1]", "[2,2]", "[3,3]", "[4,4]", "[5,5]", "[6,6]"),
        "[[[[5,0],[7,4]],[5,5]],[6,6]]"
    );
    constant SUM_EXAMPLE_4 : sum_example_t :=
    (
        (
        "[[[0,[4,5]],[0,0]],[[[4,5],[2,6]],[9,5]]]            ",
        "[7,[[[3,7],[4,3]],[[6,3],[8,8]]]]                    ",
        "[[2,[[0,8],[3,4]]],[[[6,7],1],[7,[1,6]]]]            ",
        "[[[[2,4],7],[6,[0,5]]],[[[6,8],[2,8]],[[2,1],[4,5]]]]",
        "[7,[5,[[3,8],[1,4]]]]                                ",
        "[[2,[2,2]],[8,[8,1]]]                                ",
        "[2,9]                                                ",
        "[1,[[[9,3],9],[[9,0],[0,7]]]]                        ",
        "[[[5,[7,4]],7],1]                                    ",
        "[[[[4,2],2],6],[8,7]]                                "
        ),
        "[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]"
    );
    constant SUM_EXAMPLE_5 : sum_example_t :=
    (
        (
        "[[[0,[5,8]],[[1,7],[9,6]]],[[4,[1,2]],[[1,4],2]]]",
        "[[[5,[2,8]],4],[5,[[9,9],0]]]                    ",
        "[6,[[[6,2],[5,6]],[[7,6],[4,7]]]]                ",
        "[[[6,[0,7]],[0,9]],[4,[9,[9,0]]]]                ",
        "[[[7,[6,4]],[3,[1,3]]],[[[5,5],1],9]]            ",
        "[[6,[[7,3],[3,2]]],[[[3,8],[5,7]],4]]            ",
        "[[[[5,4],[7,7]],8],[[8,3],8]]                    ",
        "[[9,3],[[9,9],[6,[4,9]]]]                        ",
        "[[2,[[7,7],7]],[[5,8],[[9,3],[0,2]]]]            ",
        "[[[[5,2],5],[8,[3,7]]],[[5,[7,5]],[4,4]]]        "
        ),
        "[[[[6,6],[7,6]],[[7,7],[7,0]]],[[[7,7],[7,7]],[[7,8],[9,9]]]]"
    );
    constant MAGNITUDE_EXAMPLE_1 : magnitude_example_t :=
    (
        "[[1,2],[[3,4],5]]", 143
    );
    constant MAGNITUDE_EXAMPLE_2 : magnitude_example_t :=
    (
        "[[[[0,7],4],[[7,8],[6,0]]],[8,1]]", 1384
    );
    constant MAGNITUDE_EXAMPLE_3 : magnitude_example_t :=
    (
        "[[[[1,1],[2,2]],[3,3]],[4,4]]", 445
    );
    constant MAGNITUDE_EXAMPLE_4 : magnitude_example_t :=
    (
        "[[[[3,0],[5,3]],[4,4]],[5,5]]", 791
    );
    constant MAGNITUDE_EXAMPLE_5 : magnitude_example_t :=
    (
        "[[[[5,0],[7,4]],[5,5]],[6,6]]", 1137
    );
    constant MAGNITUDE_EXAMPLE_6 : magnitude_example_t :=
    (
        "[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]", 3488
    );
    constant MAGNITUDE_EXAMPLE_7 : magnitude_example_t :=
    (
        "[[[[6,6],[7,6]],[[7,7],[7,0]]],[[[7,7],[7,7]],[[7,8],[9,9]]]]", 4140
    );

    -- Maximum depth for a reduced number.
    --  1: [1,1]
    --  2: [[2,2],1]
    --  3: [[[3,3],2],1]
    --  4: [[[[4,4],3],2],1]
    constant MAXIMUM_DEPTH_REDUCED : positive := 4;

    -- Structures for holding snailfish number trees.
    --  Depth 1: 3 Nodes (= 2 ** 2 - 1)
    --   Level 0:   0
    --             / \
    --   Level 1: 1   2
    --
    --  Depth 2: 7 Nodes (= 2 ** 3 - 1)
    --   Level 0:       0
    --                /   \
    --   Level 1:   1       2
    --             / \     / \
    --   Level 2: 3   4   5   6
    --
    --  Depth 3: 15 Nodes (= 2 ** 4 - 1)
    --   Level 0:               0
    --                       /     \
    --                     /         \
    --   Level 1:       1               2
    --                /   \           /   \
    --   Level 2:   3       4       5       6
    --             / \     / \     / \     / \
    --   Level 3: 7   8   9   10  11  12  13  14
    --                         ...
    type node_t is record
        is_pair : boolean;
        number  : natural;
    end record;
    type node_vector_t is array(natural range <>) of node_t;
    subtype snailfish_number_t is node_vector_t(0 to 2 ** (MAXIMUM_DEPTH_REDUCED + 1) - 2);
    subtype unreduced_number_t is node_vector_t(0 to 2 ** (MAXIMUM_DEPTH_REDUCED + 2) - 2);
    type snailfish_numbers_t is array(natural range <>) of snailfish_number_t;

    -- Get level of given index.
    --   0 -> 0, 1..2 -> 1, 3..6 -> 2, 7..14 -> 3, ...
    function level_by_index(
        index : natural
    ) return natural is
        variable level     : natural;
        variable remainder : natural;
        variable pow2      : natural;
    begin
        -- Find start of level (2 ** L - 1) that is higher than current index.
        level := 0;
        pow2  := 1;
        while pow2 - 1 <= index loop
            level := level + 1;
            pow2  := pow2 * 2;
        end loop;

        -- Go back one level for correct result.
        return level - 1;
    end function;

    -- Get level offset (index of first index in level) of given index.
    --   0 -> 0, 1..2 -> 1, 3..6 -> 3, 7..14 -> 7, ...
    function level_offset_by_index(
        index : natural
    ) return natural is
    begin
        -- Index of first node in level L:
        --   I(L) = 2 ** L - 1
        return 2 ** level_by_index(index) - 1;
    end function;

    -- Get index of node's parent.
    --   (N - I(L)) / 2 + I(L - 1)
    --   e.g. (11 - 7) / 2 + 3 = 5
    function parent_by_index(
        index : natural
    ) return natural is
        variable level : natural;
    begin
        level := level_by_index(index);
        return (index - (2 ** level - 1)) / 2 + (2 ** (level - 1) - 1);
    end function;

    -- Get index of first child of a node.
    --   (N - I(L)) * 2 + I(L + 1)
    --   e.g. (5 - 3) * 2 + 7 = 11
    function first_child_by_index(
        index : natural
    ) return natural is
        variable level : natural;
    begin
        level := level_by_index(index);
        return (index - (2 ** level - 1)) * 2 + (2 ** (level + 1) - 1);
    end function;

    -- Parse string into a snailfish number.
    function parse_number_string(
        str : string
    ) return snailfish_number_t is
        variable result        : snailfish_number_t;
        variable current_index : natural;
        variable char          : character;
        variable address       : natural;
    begin
        current_index := 0;
        for I in str'range loop
            case str(I) is
                when '[' =>
                    result(current_index).is_pair := true;
                    -- Advance to node's first child.
                    current_index := first_child_by_index(current_index);
                when ']' =>
                    -- Retract to node's parent.
                    current_index := parent_by_index(current_index);
                when ',' =>
                    -- Advance to second part of pair.
                    current_index := current_index + 1;
                when '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
                    result(current_index).number := character'pos(str(I)) - character'pos('0');
                when others => null;
            end case;
        end loop;
        return result;
    end function;

    -- Print out any snailfish number.
    procedure print_number(
        snailfish_number : node_vector_t
    ) is
        variable line1            : line;
        variable line1_index      : positive;
        variable current_index    : natural;
        variable number           : natural;
        variable number_of_digits : natural;
        variable digit            : natural;
        variable retracting       : boolean;
        variable advance          : boolean;

        -- Push character to line and extend string if required.
        procedure push_char(char : character) is
            variable line2           : line;
        begin
            if line1_index > line1'length then
                -- Extend string first.
                line2                    := new string(1 to line1'length + 16);
                line2(1 to line1'length) := line1.all;
                deallocate(line1);
                line1 := line2;
            end if;
            line1(line1_index) := char;
            line1_index        := line1_index + 1;
        end procedure;
    begin
        line1         := new string(1 to 16);
        line1_index   := 1;
        current_index := 0;
        retracting    := false;
        loop
            advance := false;
            if snailfish_number(current_index).is_pair then
                if not retracting then
                    -- Start of pair.
                    push_char('[');
                    current_index := first_child_by_index(current_index);
                else
                    -- End of pair.
                    push_char(']');
                    retracting := false;
                    if current_index = 0 then
                        exit;
                    else
                        advance := true;
                    end if;
                end if;
            else
                -- Add number (that might be more than one digit).
                number_of_digits := 1;
                number           := snailfish_number(current_index).number;
                while number >= 10 loop
                    number_of_digits := number_of_digits + 1;
                    number           := number / 10;
                end loop;
                number := snailfish_number(current_index).number;
                for D in number_of_digits downto 1 loop
                    digit  := number / (10 ** (D - 1));
                    number := number - digit * (10 ** (D - 1));
                    push_char(character'val(character'pos('0') + digit));
                end loop;
                advance := true;
            end if;
            -- Advance to second part of pair or retract to parent.
            if advance then
                if current_index mod 2 = 1 then
                    push_char(',');
                    current_index := current_index + 1;
                else
                    current_index := parent_by_index(current_index);
                    retracting    := true;
                end if;
            end if;
        end loop;
        report line1(1 to line1_index - 1);
        deallocate(line1);
    end procedure;

    -- Explode the pair at given index.
    --  <quote>
    --  To explode a pair, the pair's left value is added to the first regular number to the left
    --  of the exploding pair (if any), and the pair's right value is added to the first regular
    --  number to the right of the exploding pair (if any). Exploding pairs will always consist of
    --  two regular numbers. Then, the entire exploding pair is replaced with the regular number 0.
    --  </quote>
    function explode_pair(
        unreduced_number : unreduced_number_t;
        index            : natural
    ) return unreduced_number_t is
        variable result            : unreduced_number_t;
        variable first_child_index : natural;
        variable level_offset      : natural;
        variable search_index      : natural;
    begin
        result            := unreduced_number;
        level_offset      := level_offset_by_index(index);
        first_child_index := first_child_by_index(index);
        -- Add left value to first regular number to the left.
        if index > level_offset then
            search_index := index;
            -- Ascend parents until node is second child of its parent.
            while search_index mod 2 = 1 loop
                search_index := parent_by_index(search_index);
            end loop;
            -- Switch to first child.
            search_index := search_index - 1;
            -- Descend second child nodes until node is regular number.
            while result(search_index).is_pair loop
                search_index := first_child_by_index(search_index) + 1;
            end loop;
            -- Add left value to node.
            result(search_index).number := (
            result(search_index).number + result(first_child_index).number
            );
        end if;
        -- Add right value to first regular number to the right.
        if index < 2 * level_offset then
            search_index := index;
            -- Ascend parents until node is first child of its parent.
            while search_index mod 2 = 0 loop
                search_index := parent_by_index(search_index);
            end loop;
            -- Switch to second child.
            search_index := search_index + 1;
            -- Descend first child nodes until node is regular number.
            while result(search_index).is_pair loop
                search_index := first_child_by_index(search_index);
            end loop;
            -- Add right value to node.
            result(search_index).number := (
            result(search_index).number + result(first_child_index + 1).number
            );
        end if;

        -- Clear exploded pair and its children.
        result(index).is_pair                := false;
        result(index).number                 := 0;
        result(first_child_index).number     := 0;
        result(first_child_index + 1).number := 0;
        return result;
    end function;

    -- Split the number at given index.
    --  <quote>
    --  To split a regular number, replace it with a pair; the left element of the pair should be
    --  the regular number divided by two and rounded down, while the right element of the pair
    --  should be the regular number divided by two and rounded up.
    --  </quote>
    function split_number(
        unreduced_number : unreduced_number_t;
        index            : natural
    ) return unreduced_number_t is
        variable result            : unreduced_number_t;
        variable first_child_index : natural;
        variable number            : natural;
    begin
        result            := unreduced_number;
        first_child_index := first_child_by_index(index);

        -- Replace given node by pair.
        number                := result(index).number;
        result(index).is_pair := true;
        result(index).number  := 0;

        -- Calculate left pair child. (Number divided by two and rounded down)
        result(first_child_index).is_pair := false;
        result(first_child_index).number  := number / 2;

        -- Calculate right pair child. (Number divided by two and rounded up)
        result(first_child_index + 1).is_pair := false;
        result(first_child_index + 1).number  := number - result(first_child_index).number;

        return result;
    end function;

    -- Reduce a potentially unreduced snailfish number.
    function reduce_number(
        unreduced_number : unreduced_number_t
    ) return snailfish_number_t is
        variable result     : unreduced_number_t;
        variable is_reduced : boolean;
        variable index      : natural;
    begin
        result := unreduced_number;

        is_reduced := false;
        reduce_l : while not is_reduced loop
            is_reduced := true;
            -- Find pair in deepest level: Pair explodes.
            for I in snailfish_number_t'length / 2 to snailfish_number_t'length - 1 loop
                if result(I).is_pair then
                    is_reduced := false;
                    -- Explode pair.
                    result := explode_pair(result, I);
                end if;
            end loop;

            -- Find regular number greater or equal to 10: Number splits.
            index := 0;
            -- Start with leftmost regular number.
            while result(index).is_pair loop
                index := first_child_by_index(index);
            end loop;
            -- Continue until rightmost regular number has been found.
            loop
                if result(index).number > 9 then
                    is_reduced := false;
                    result     := split_number(result, index);
                    -- Potentially exploding pairs have to be handled before the next split.
                    next reduce_l;
                end if;
                if index = 2 * level_offset_by_index(index) then
                    -- This was the rightmost number.
                    exit;
                else
                    -- Ascend parents until node is first child.
                    while index mod 2 = 0 loop
                        index := parent_by_index(index);
                    end loop;
                    -- Switch to second child.
                    index := index + 1;
                    -- Descend to leftmost regular number.
                    while result(index).is_pair loop
                        index := first_child_by_index(index);
                    end loop;
                end if;
            end loop;
        end loop;

        -- For now, just cut all pairs in last level.
        for I in 15 to 30 loop
            result(I).is_pair := false;
        end loop;

        -- The deepest level can now be dropped.
        return result(snailfish_number_t'range);
    end function;

    -- Add two snailfish numbers.
    function "+" (
        L, R : snailfish_number_t
    ) return snailfish_number_t is
        variable unreduced_number : unreduced_number_t;
        variable level            : natural;
        variable offset           : natural;
    begin
        unreduced_number(0).is_pair := true;
        -- Copy L into left part of the tree.
        --  Level 0:                    0
        --  Level 1:    0    ->    1    , ...
        --  Level 2:  1 , 2  ->  3 , 4  , ...
        --  Level 3: 3,4,5,6 -> 7,8,9,10, ...
        level  := 1;
        offset := 2 ** (level - 1); -- 1
        for I in L'range loop
            if I = 2 ** level - 1 then
                level  := level + 1; -- 2, 3, ...
                offset := 2 ** (level - 1); -- 2, 4, ...
            end if;
            unreduced_number(I + offset) := L(I);
        end loop;
        -- Copy R into right part of the tree.
        --  Level 0:                0
        --  Level 1:    0    -> ... ,     2
        --  Level 2:  1 , 2  -> ... ,  5  ,  6
        --  Level 3: 3,4,5,6 -> ... ,11,12,13,14
        level  := 1;
        offset := 2 ** level; -- 2
        for I in R'range loop
            if I = 2 ** level - 1 then
                level  := level + 1; -- 2, 3, ...
                offset := 2 ** level; -- 4, 8, ...
            end if;
            unreduced_number(I + offset) := R(I);
        end loop;

        return reduce_number(unreduced_number);
    end function;

    -- Sum up several strings of snailfish numbers.
    function sum_number_strings(
        snailfish_numbers : string_vector_t
    ) return snailfish_number_t is
        variable result : snailfish_number_t;
    begin
        result := parse_number_string(snailfish_numbers(0));
        for I in 1 to snailfish_numbers'high loop
            result := result + parse_number_string(snailfish_numbers(I));
        end loop;
        return result;
    end function;

    -- Calculate magnitude of snailfish number.
    --  <quote>
    --  The magnitude of a pair is 3 times the magnitude of its left element plus 2 times the
    --  magnitude of its right element. The magnitude of a regular number is just that number.
    --  </quote>
    --  This function recurses into the tree for calculating pair magnitudes.
    function calculate_magnitude(
        snailfish_number : snailfish_number_t;
        index            : natural := 0 -- default to root node
    ) return natural is
        variable first_child_index : natural;
        variable magnitude         : natural;
        variable child_magnitude   : natural;
    begin
        if not snailfish_number(index).is_pair then
            -- The magnitude of a regular number is just that number.
            magnitude := snailfish_number(index).number;
        else
            -- The magnitude of a pair is 3 times the magnitude of its left element ...
            first_child_index := first_child_by_index(index);
            child_magnitude   := calculate_magnitude(snailfish_number, first_child_index);
            magnitude         := 3 * child_magnitude;

            -- ... plus 2 times the magnitude of its right element.
            child_magnitude := calculate_magnitude(snailfish_number, first_child_index + 1);
            magnitude       := magnitude + 2 * child_magnitude;
        end if;

        return magnitude;
    end function;

    -- Calculate the largest magnitude of the sum of any two numbers in the list.
    function largest_magnitude_of_two(
        snailfish_numbers : string_vector_t
    ) return natural is
        variable parsed_numbers    : snailfish_numbers_t(snailfish_numbers'range);
        variable sum               : snailfish_number_t;
        variable magnitude         : natural;
        variable largest_magnitude : natural;
    begin
        for I in snailfish_numbers'range loop
            parsed_numbers(I) := parse_number_string(snailfish_numbers(I));
        end loop;

        largest_magnitude := 0;
        for I in parsed_numbers'range loop
            for J in parsed_numbers'range loop
                if I /= J then
                    sum               := parsed_numbers(I) + parsed_numbers(J);
                    magnitude         := calculate_magnitude(sum);
                    largest_magnitude := maximum(largest_magnitude, magnitude);
                end if;
            end loop;
        end loop;

        return largest_magnitude;
    end function;

begin

    process
        file i_file     : text;
        variable i_line : line;

        type string_vector_ptr_t is access string_vector_t;
        variable string_vector_ptr   : string_vector_ptr_t;
        variable number_of_lines     : natural;
        variable maximum_line_length : natural;
        variable index               : natural;

        variable snailfish_number     : snailfish_number_t;
        variable snailfish_number_ref : snailfish_number_t;
        variable magnitude            : natural;
    begin
        -- Read input file once to get number of lines and maximum length of strings.
        file_open(i_file, "inputs/day_18.txt", read_mode);
        number_of_lines     := 0;
        maximum_line_length := 0;
        while not endfile(i_file) loop
            number_of_lines := number_of_lines + 1;
            readline(i_file, i_line);
            maximum_line_length := maximum(maximum_line_length, i_line'length);
        end loop;
        file_close(i_file);

        string_vector_ptr := new string_vector_t(0 to number_of_lines - 1)(1 to maximum_line_length);

        -- Read input file again to extract number strings.
        file_open(i_file, "inputs/day_18.txt", read_mode);
        index := 0;
        while not endfile(i_file) loop
            readline(i_file, i_line);
            string_vector_ptr(index)(1 to i_line'length) := i_line.all;
            index                                        := index + 1;
        end loop;
        file_close(i_file);

        -- Examples for summing up snailfish numbers.
        snailfish_number     := sum_number_strings(SUM_EXAMPLE_1.addends);
        snailfish_number_ref := parse_number_string(SUM_EXAMPLE_1.sum);
        report "Sum for example 1 should be " & SUM_EXAMPLE_1.sum & " and is:";
        print_number(snailfish_number);
        assert snailfish_number = snailfish_number_ref;

        snailfish_number     := sum_number_strings(SUM_EXAMPLE_2.addends);
        snailfish_number_ref := parse_number_string(SUM_EXAMPLE_2.sum);
        report "Sum for example 2 should be " & SUM_EXAMPLE_2.sum & " and is:";
        print_number(snailfish_number);
        assert snailfish_number = snailfish_number_ref;

        snailfish_number     := sum_number_strings(SUM_EXAMPLE_3.addends);
        snailfish_number_ref := parse_number_string(SUM_EXAMPLE_3.sum);
        report "Sum for example 3 should be " & SUM_EXAMPLE_3.sum & " and is:";
        print_number(snailfish_number);
        assert snailfish_number = snailfish_number_ref;

        snailfish_number     := sum_number_strings(SUM_EXAMPLE_4.addends);
        snailfish_number_ref := parse_number_string(SUM_EXAMPLE_4.sum);
        report "Sum for example 4 should be " & SUM_EXAMPLE_4.sum & " and is:";
        print_number(snailfish_number);
        assert snailfish_number = snailfish_number_ref;

        snailfish_number     := sum_number_strings(SUM_EXAMPLE_5.addends);
        snailfish_number_ref := parse_number_string(SUM_EXAMPLE_5.sum);
        report "Sum for example 5 should be " & SUM_EXAMPLE_5.sum & " and is:";
        print_number(snailfish_number);
        assert snailfish_number = snailfish_number_ref;

        -- Examples for calculating the magnitude of snailfish numbers.
        snailfish_number := parse_number_string(MAGNITUDE_EXAMPLE_1.number);
        magnitude        := calculate_magnitude(snailfish_number);
        report "Magnitude for example 1: " & integer'image(magnitude);
        assert magnitude = MAGNITUDE_EXAMPLE_1.magnitude;

        snailfish_number := parse_number_string(MAGNITUDE_EXAMPLE_2.number);
        magnitude        := calculate_magnitude(snailfish_number);
        report "Magnitude for example 2: " & integer'image(magnitude);
        assert magnitude = MAGNITUDE_EXAMPLE_2.magnitude;

        snailfish_number := parse_number_string(MAGNITUDE_EXAMPLE_3.number);
        magnitude        := calculate_magnitude(snailfish_number);
        report "Magnitude for example 3: " & integer'image(magnitude);
        assert magnitude = MAGNITUDE_EXAMPLE_3.magnitude;

        snailfish_number := parse_number_string(MAGNITUDE_EXAMPLE_4.number);
        magnitude        := calculate_magnitude(snailfish_number);
        report "Magnitude for example 4: " & integer'image(magnitude);
        assert magnitude = MAGNITUDE_EXAMPLE_4.magnitude;

        snailfish_number := parse_number_string(MAGNITUDE_EXAMPLE_5.number);
        magnitude        := calculate_magnitude(snailfish_number);
        report "Magnitude for example 5: " & integer'image(magnitude);
        assert magnitude = MAGNITUDE_EXAMPLE_5.magnitude;

        snailfish_number := parse_number_string(MAGNITUDE_EXAMPLE_6.number);
        magnitude        := calculate_magnitude(snailfish_number);
        report "Magnitude for example 6: " & integer'image(magnitude);
        assert magnitude = MAGNITUDE_EXAMPLE_6.magnitude;

        snailfish_number := parse_number_string(MAGNITUDE_EXAMPLE_7.number);
        magnitude        := calculate_magnitude(snailfish_number);
        report "Magnitude for example 7: " & integer'image(magnitude);
        assert magnitude = MAGNITUDE_EXAMPLE_7.magnitude;

        -- Numbers from input file.
        snailfish_number := sum_number_strings(string_vector_ptr.all);
        report "Sum for input file:";
        print_number(snailfish_number);
        magnitude := calculate_magnitude(snailfish_number);
        report "Magnitude for input file sum: " & integer'image(magnitude);
        assert magnitude = 4132;

        report "*** Part Two ***";

        magnitude := largest_magnitude_of_two(SUM_EXAMPLE_5.addends);
        report "Largest magnitude for example: " & integer'image(magnitude);
        assert magnitude = 3993;

        magnitude := largest_magnitude_of_two(string_vector_ptr.all);
        report "Largest magnitude for input file: " & integer'image(magnitude);
        assert magnitude = 4685;

        deallocate(string_vector_ptr);
        wait;
    end process;

end architecture;