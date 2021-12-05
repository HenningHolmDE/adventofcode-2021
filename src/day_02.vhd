-- Solution for Advent of Code 2021, day 2

entity day_02 is
end entity;

use std.textio.all;

architecture simulation of day_02 is

    -- command type for holding decoded commands
    type operation_t is (FORWARD, DOWN, UP);
    type command_t is record
        operation : operation_t;
        value     : integer;
    end record;
    type command_vector_t is array (integer range <>) of command_t;

    -- decode command string into command type
    function decode_command(
        command_str : string
    ) return command_t is
        variable command_line  : line;
        variable operation_str : string(1 to 7); -- longest operation string ist "forward"
        variable strlen        : natural;
        variable operation     : operation_t;
        variable value         : natural;
        variable result        : command_t;
    begin
        -- create line from input string
        write(command_line, command_str);
        -- decode operation into enum type
        sread(command_line, operation_str, strlen);
        operation := operation_t'value(operation_str(1 to strlen));
        -- decode value
        read(command_line, value);
        return (operation, value);
    end function;

    -- commands from example
    constant EXAMPLE_COMMANDS : command_vector_t :=
    (
        decode_command("forward 5"),
        decode_command("down 5"),
        decode_command("forward 8"),
        decode_command("up 3"),
        decode_command("down 8"),
        decode_command("forward 2")
    );

    type position_t is record
        horizontal : natural;
        depth      : natural;
        aim        : integer;
    end record;

    -- process all commands and return resulting position
    function process_commands_part1(
        commands : command_vector_t
    ) return position_t is
        variable position : position_t := (0, 0, 0);
        variable command  : command_t;
    begin
        for I in commands'range loop
            command := commands(I);
            case command.operation is
                when FORWARD =>
                    position.horizontal := position.horizontal + command.value;
                when DOWN =>
                    position.depth := position.depth + command.value;
                when UP =>
                    position.depth := position.depth - command.value;
            end case;
        end loop;
        return position;
    end function;

    -- process all commands and return resulting position
    function process_commands_part2(
        commands : command_vector_t
    ) return position_t is
        variable position : position_t := (0, 0, 0);
        variable command  : command_t;
    begin
        for I in commands'range loop
            command := commands(I);
            case command.operation is
                when FORWARD =>
                    position.horizontal := position.horizontal + command.value;
                    position.depth      := position.depth + (position.aim * command.value);
                when DOWN =>
                    position.aim := position.aim + command.value;
                when UP =>
                    position.aim := position.aim - command.value;
            end case;
        end loop;
        return position;
    end function;

begin

    process
        type command_vector_ptr_t is access command_vector_t;
        variable commands_ptr     : command_vector_ptr_t;
        variable commands_ptr_old : command_vector_ptr_t;

        variable position : position_t;
        variable result   : natural;
        file i_file       : text;
        variable i_line   : line;
        variable command  : command_t;
    begin
        -- load commands from input file
        file_open(i_file, "inputs/day_02.txt", read_mode);
        while not endfile(i_file) loop
            readline(i_file, i_line);
            command := decode_command(i_line.all);
            -- append command to vector
            if commands_ptr = null then
                commands_ptr := new command_vector_t'(0 => command);
            else
                commands_ptr_old := commands_ptr;
                commands_ptr     := new command_vector_t'(commands_ptr.all & command);
                deallocate(commands_ptr_old);
            end if;
        end loop;
        file_close(i_file);
        report "Number of commands in example input: " & integer'image(EXAMPLE_COMMANDS'length);
        report "Number of commands in input file: " & integer'image(commands_ptr.all'length);

        report "*** Part One ***";

        position := process_commands_part1(EXAMPLE_COMMANDS);
        result   := position.horizontal * position.depth;
        report "Position after running example commands:";
        report " Horizontal: " & integer'image(position.horizontal);
        assert position.horizontal = 15;
        report " Depth: " & integer'image(position.depth);
        assert position.depth = 10;
        report " Resulting product: " & integer'image(result);
        assert result = 150;

        position := process_commands_part1(commands_ptr.all);
        result   := position.horizontal * position.depth;
        report "Position after running input commands:";
        report " Horizontal: " & integer'image(position.horizontal);
        report " Depth: " & integer'image(position.depth);
        report " Resulting product: " & integer'image(result);
        assert result = 150;

        report "*** Part Two ***";

        position := process_commands_part2(EXAMPLE_COMMANDS);
        result   := position.horizontal * position.depth;
        report "Position after running example commands:";
        report " Horizontal: " & integer'image(position.horizontal);
        assert position.horizontal = 15;
        report " Depth: " & integer'image(position.depth);
        assert position.depth = 60;
        report " Aim: " & integer'image(position.aim);
        assert position.aim = 10;
        report " Resulting product: " & integer'image(result);
        assert result = 900;

        position := process_commands_part2(commands_ptr.all);
        result   := position.horizontal * position.depth;
        report "Position after running input commands:";
        report " Horizontal: " & integer'image(position.horizontal);
        report " Depth: " & integer'image(position.depth);
        report " Aim: " & integer'image(position.aim);
        report " Resulting product: " & integer'image(result);

        deallocate(commands_ptr);
        wait;
    end process;

end architecture;