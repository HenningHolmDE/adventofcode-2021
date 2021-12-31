-- Solution for Advent of Code 2021, day 16

entity day_16 is
end entity;

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture simulation of day_16 is

    subtype big_unsigned_t is unsigned(63 downto 0);
    type packet_t is record
        version : natural;
        type_id : natural;
        parent  : natural;
        value   : big_unsigned_t;
    end record;
    type packets_t is array(natural range <>) of packet_t;
    type packets_ptr_t is access packets_t;
    type risk_levels_t is array (natural range <>, natural range <>) of natural;

    constant MAXIMUM_FIELD_WIDTH : positive := 15;
    type pop_bits_result_t is record
        position : natural;
        bits     : unsigned(MAXIMUM_FIELD_WIDTH - 1 downto 0);
    end record;

    -- Pop given number of bits from the transmission, starting at given position.
    function pop_bits_from_transmission(
        hex_string     : string;
        position       : natural;
        number_of_bits : positive
    ) return pop_bits_result_t is
        variable position_result : natural;
        variable bits_result     : unsigned(MAXIMUM_FIELD_WIDTH - 1 downto 0);
        variable remaining_bits  : natural;
        variable position_char   : positive;
        variable position_bit    : natural;
        variable char            : character;
        variable char_value      : natural;
        variable char_bits       : unsigned(3 downto 0);
        variable bits_to_add     : natural;
    begin
        position_result := position;
        remaining_bits  := number_of_bits;
        -- Requested number of bits can span multiple characters.
        while remaining_bits > 0 loop
            -- Get bits of next character from hex string.
            position_char := position_result / 4 + 1;
            char          := hex_string(position_char);
            if char >= '0' and char <= '9' then
                char_value := character'pos(char) - character'pos('0');
            elsif char >= 'A' and char <= 'F' then
                char_value := 10 + character'pos(char) - character'pos('A');
            else
                char_value := 0;
            end if;
            position_bit := position_result mod 4;
            char_bits    := to_unsigned(char_value, 4);
            char_bits    := char_bits sll position_bit; -- Move next bit to high bit.
            -- Append next bit(s) to result.
            bits_to_add := minimum(remaining_bits, 4 - position_bit);
            bits_result := (
                bits_result(bits_result'high - bits_to_add downto 0) &
                char_bits(3 downto 4 - bits_to_add)
                );
            remaining_bits  := remaining_bits - bits_to_add;
            position_result := position_result + bits_to_add;
        end loop;
        return (position_result, bits_result);
    end function;

    -- Decode hexadecimal string representation into an array of packets.
    function decode_transmission(
        hex_string : string
    ) return packets_t is
        -- Packets consist of at least 11 bits while every hex digit represents 4 bits.
        -- Therefore an upper bound for the number of packets can be calculated.
        variable packets               : packets_t(1 to (hex_string'length * 4 / 11));
        variable end_positions         : integer_vector(packets'range);
        variable num_sub_packets       : integer_vector(packets'range);
        variable num_packets           : natural;
        variable pop_bits_result       : pop_bits_result_t;
        variable current_parent        : natural;
        variable bits                  : unsigned(3 downto 0);
        variable number_of_sub_packets : natural;
        variable parent_finished       : boolean;
    begin
        num_packets              := 0;
        pop_bits_result.position := 0;
        current_parent           := 0;
        packets_l : loop
            num_packets := num_packets + 1;

            packets(num_packets).parent := current_parent;

            -- Packet version (3 bits)
            pop_bits_result := pop_bits_from_transmission(
                hex_string, pop_bits_result.position, 3
                );
            packets(num_packets).version := to_integer(pop_bits_result.bits(2 downto 0));

            -- Packet type ID (3 bits)
            pop_bits_result := pop_bits_from_transmission(
                hex_string, pop_bits_result.position, 3
                );
            packets(num_packets).type_id := to_integer(pop_bits_result.bits(2 downto 0));

            -- report "Type ID: " & integer'image(packets(num_packets).type_id);
            if packets(num_packets).type_id = 4 then
                -- Literal value
                packets(num_packets).value := (others => '0');
                loop
                    -- Bit group (5 bits)
                    pop_bits_result := pop_bits_from_transmission(
                        hex_string, pop_bits_result.position, 5
                        );
                    packets(num_packets).value := (
                    packets(num_packets).value(packets(num_packets).value'high - 4 downto 0) &
                    pop_bits_result.bits(3 downto 0)
                    );
                    if pop_bits_result.bits(4) = '0' then
                        exit;
                    end if;
                end loop;

                -- Check if parent packet is finished.
                while current_parent /= 0 loop
                    parent_finished := false;
                    if num_sub_packets(current_parent) > 0 then
                        number_of_sub_packets := 0;
                        for I in 1 to num_packets loop
                            if packets(I).parent = current_parent then
                                number_of_sub_packets := number_of_sub_packets + 1;
                            end if;
                        end loop;
                        if number_of_sub_packets >= num_sub_packets(current_parent) then
                            parent_finished := true;
                        end if;
                    elsif pop_bits_result.position > end_positions(current_parent) then
                        parent_finished := true;
                    end if;
                    if parent_finished then
                        -- Move up to parent's parent.
                        current_parent := packets(current_parent).parent;
                    else
                        exit;
                    end if;
                end loop;
                if current_parent = 0 then
                    -- Outermost packet has been finished.
                    exit;
                end if;
            else
                -- Operator
                -- Length type ID (1 bit)
                pop_bits_result := pop_bits_from_transmission(
                    hex_string, pop_bits_result.position, 1
                    );
                if pop_bits_result.bits(0) = '0' then
                    -- Number of bits in sub-packets (15 bits)
                    pop_bits_result := pop_bits_from_transmission(
                        hex_string, pop_bits_result.position, 15
                        );
                    end_positions(num_packets) := (
                    pop_bits_result.position - 1 +
                    to_integer(pop_bits_result.bits(14 downto 0))
                    );
                    current_parent := num_packets;
                else
                    -- Number of sub-packets (11 bits)
                    pop_bits_result := pop_bits_from_transmission(
                        hex_string, pop_bits_result.position, 11
                        );
                    num_sub_packets(num_packets) := (
                    to_integer(pop_bits_result.bits(10 downto 0))
                    );
                    current_parent := num_packets;
                end if;
            end if;
        end loop;

        return packets(1 to num_packets);
    end function;

    -- Part One: Return the sum of all packets' version numbers.
    function sum_of_version_numbers(
        packets : packets_t
    ) return natural is
        variable result : natural;
    begin
        result := 0;
        for I in packets'range loop
            result := result + packets(I).version;
        end loop;
        return result;
    end function;

    type children_t is record
        count    : natural;
        children : integer_vector;
    end record;
    type children_map_t is array(natural range <>) of children_t;

    -- Recursively evaluate expression starting from given node.
    function evaluate_expression_recurse(
        packets      : packets_t;
        children_map : children_map_t;
        node         : natural
    ) return big_unsigned_t is
        type big_unsigned_vector_t is array(integer range <>) of big_unsigned_t;
        variable children_results : big_unsigned_vector_t(children_map(node).children'range);
        variable result           : big_unsigned_t;
    begin
        -- Return value of literal nodes.
        if packets(node).type_id = 4 then
            return packets(node).value;
        end if;

        -- For other nodes recurse into children first.
        for I in 0 to children_map(node).count - 1 loop
            children_results(I) := evaluate_expression_recurse(
            packets, children_map, children_map(node).children(I)
            );
        end loop;

        -- Perform operation on depending on operator type.
        if packets(node).type_id = 0 then
            -- Sum operator
            result := children_results(0);
            for I in 1 to children_map(node).count - 1 loop
                result := result + children_results(I);
            end loop;
        elsif packets(node).type_id = 1 then
            -- Product operator
            result := children_results(0);
            for I in 1 to children_map(node).count - 1 loop
                result := resize(result * children_results(I), result'length);
            end loop;
        elsif packets(node).type_id = 2 then
            -- Minimum operator
            result := children_results(0);
            for I in 1 to children_map(node).count - 1 loop
                result := minimum(result, children_results(I));
            end loop;
        elsif packets(node).type_id = 3 then
            -- Maximum operator
            result := children_results(0);
            for I in 1 to children_map(node).count - 1 loop
                result := maximum(result, children_results(I));
            end loop;
        elsif packets(node).type_id = 5 then
            -- Greater than operator
            if children_results(0) > children_results(1) then
                result := to_unsigned(1, result'length);
            else
                result := (others => '0');
            end if;
        elsif packets(node).type_id = 6 then
            -- Less than operator
            if children_results(0) < children_results(1) then
                result := to_unsigned(1, result'length);
            else
                result := (others => '0');
            end if;
        elsif packets(node).type_id = 7 then
            -- Equal to operator
            if children_results(0) = children_results(1) then
                result := to_unsigned(1, result'length);
            else
                result := (others => '0');
            end if;
        else
            report "Unknown type ID: " & integer'image(packets(node).type_id) severity failure;
        end if;

        return result;
    end function;

    -- Part Two: Evaluate expression represented by packets.
    function evaluate_expression(
        packets : packets_t
    ) return big_unsigned_t is
        -- Using number of packets as an upper bound for the number of children.
        variable children_map : children_map_t(packets'range)(children(0 to packets'length - 1));
    begin
        -- Set up map parent to children.
        children_map := (others => (0, (others => 0)));
        for I in packets'range loop
            if packets(I).parent > 0 then
                -- Add child
                children_map(packets(I).parent).children(
                children_map(packets(I).parent).count
                ) := I;
                -- Increase children count.
                children_map(packets(I).parent).count := (
                children_map(packets(I).parent).count + 1
                );
            end if;
        end loop;

        -- Start recursive evaluation.
        return evaluate_expression_recurse(packets, children_map, 1);
    end function;

begin

    process
        file i_file               : text;
        variable transmission_ptr : line;

        variable result      : natural;
        variable packets_ptr : packets_ptr_t;
        variable result2     : big_unsigned_t;
    begin
        -- Load transmission from input file
        file_open(i_file, "inputs/day_16.txt", read_mode);
        readline(i_file, transmission_ptr);
        file_close(i_file);
        report "Length of transmission from input file: " & integer'image(transmission_ptr'length);

        report "*** Part One ***";

        result := sum_of_version_numbers(decode_transmission("D2FE28"));
        report "Sum of all version numbers in example input 1: " & integer'image(result);
        assert result = 6;

        result := sum_of_version_numbers(decode_transmission("38006F45291200"));
        report "Sum of all version numbers in example input 2: " & integer'image(result);
        assert result = 9;

        result := sum_of_version_numbers(decode_transmission("EE00D40C823060"));
        report "Sum of all version numbers in example input 3: " & integer'image(result);
        assert result = 14;

        result := sum_of_version_numbers(decode_transmission("8A004A801A8002F478"));
        report "Sum of all version numbers in example input 4: " & integer'image(result);
        assert result = 16;

        result := sum_of_version_numbers(decode_transmission("620080001611562C8802118E34"));
        report "Sum of all version numbers in example input 5: " & integer'image(result);
        assert result = 12;

        result := sum_of_version_numbers(decode_transmission("C0015000016115A2E0802F182340"));
        report "Sum of all version numbers in example input 6: " & integer'image(result);
        assert result = 23;

        result := sum_of_version_numbers(decode_transmission("A0016C880162017C3686B18A3D4780"));
        report "Sum of all version numbers in example input 7: " & integer'image(result);
        assert result = 31;

        packets_ptr := new packets_t'(decode_transmission(transmission_ptr.all));
        result      := sum_of_version_numbers(packets_ptr.all);
        report "Sum of all version numbers in input from file: " & integer'image(result);
        assert result = 967;

        report "*** Part Two ***";

        result := to_integer(evaluate_expression(decode_transmission("C200B40A82")));
        report "Result of evaluation of example input 8: " & integer'image(result);
        assert result = 3;

        result := to_integer(evaluate_expression(decode_transmission("04005AC33890")));
        report "Result of evaluation of example input 9: " & integer'image(result);
        assert result = 54;

        result := to_integer(evaluate_expression(decode_transmission("880086C3E88112")));
        report "Result of evaluation of example input 10: " & integer'image(result);
        assert result = 7;

        result := to_integer(evaluate_expression(decode_transmission("CE00C43D881120")));
        report "Result of evaluation of example input 11: " & integer'image(result);
        assert result = 9;

        result := to_integer(evaluate_expression(decode_transmission("D8005AC2A8F0")));
        report "Result of evaluation of example input 12: " & integer'image(result);
        assert result = 1;

        result := to_integer(evaluate_expression(decode_transmission("F600BC2D8F")));
        report "Result of evaluation of example input 13: " & integer'image(result);
        assert result = 0;

        result := to_integer(evaluate_expression(decode_transmission("9C005AC2F8F0")));
        report "Result of evaluation of example input 14: " & integer'image(result);
        assert result = 0;

        result := to_integer(evaluate_expression(decode_transmission("9C0141080250320F1802104A08")));
        report "Result of evaluation of example input 15: " & integer'image(result);
        assert result = 1;

        result2 := evaluate_expression(packets_ptr.all);
        report "Result of evaluation of input from file: 0x" & to_hstring(result2);
        assert result2 = d"12883091136209";

        deallocate(packets_ptr);
        wait;
    end process;

end architecture;