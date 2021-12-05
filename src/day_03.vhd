-- Solution for Advent of Code 2021, day 3

entity day_03 is
end entity;

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture simulation of day_03 is

    type report_t is array (integer range <>) of unsigned;

    constant EXAMPLE_REPORT : report_t :=
    (
        "00100",
        "11110",
        "10110",
        "10111",
        "10101",
        "01111",
        "00111",
        "11100",
        "10000",
        "11001",
        "00010",
        "01010"
    );

    type rates_t is record
        gamma            : natural;
        epsilon          : natural;
        oxygen_generator : natural;
        co2_scrubber     : natural;
    end record;

    -- Part One: Process gamma and epsilon rates.
    function process_report_part1(
        rep : report_t
    ) return rates_t is
        variable ones_at  : integer_vector(rep(rep'left)'range);
        variable zeros_at : integer_vector(rep(rep'left)'range);
        variable gamma    : unsigned(rep(rep'left)'range);
        variable epsilon  : unsigned(rep(rep'left)'range);
        variable result   : rates_t := (0, 0, 0, 0);
    begin
        -- count ones and zeros at each position
        ones_at  := (others => 0);
        zeros_at := (others => 0);
        for I in rep'range loop
            for K in rep(rep'left)'range loop
                if rep(I)(K) = '1' then
                    ones_at(K) := ones_at(K) + 1;
                else
                    zeros_at(K) := zeros_at(K) + 1;
                end if;
            end loop;
        end loop;
        -- set bits of gamma and epsilon accordingly
        gamma   := (others => '0');
        epsilon := (others => '0');
        for K in rep(rep'left)'range loop
            if ones_at(K) > zeros_at(K) then
                -- one is more common at this position
                gamma(K) := '1';
            elsif ones_at(K) < zeros_at(K) then
                -- one is less common at this position
                epsilon(K) := '1';
            end if;
        end loop;
        result.gamma   := to_integer(gamma);
        result.epsilon := to_integer(epsilon);
        return result;
    end function;

    type bit_criteria_t is (MOST_COMMON, LEAST_COMMON);

    -- filter report to find value that matches bit criteria
    function filter_report_value(
        rep          : report_t;
        bit_criteria : bit_criteria_t
    ) return unsigned is
        variable ones   : natural;
        variable zeros  : natural;
        variable filter : unsigned(rep(rep'left)'range);
        variable result : unsigned(rep(rep'left)'range);
    begin
        filter := (others => '-');
        k_loop : for K in filter'range loop
            -- extend filter with next bit
            ones  := 0;
            zeros := 0;
            for I in rep'range loop
                if rep(I) ?= filter then
                    if rep(I)(K) = '1' then
                        ones := ones + 1;
                    else
                        zeros := zeros + 1;
                    end if;
                end if;
            end loop;
            if bit_criteria = MOST_COMMON and ones >= zeros then
                filter(K) := '1';
            elsif bit_criteria = LEAST_COMMON and ones < zeros then
                filter(K) := '1';
            else
                filter(K) := '0';
            end if;

            -- result is found if only one value matches filter
            result := (others => 'U');
            for I in rep'range loop
                if rep(I) ?= filter then
                    if result(result'left) = 'U' then
                        result := rep(I);
                    else
                        -- second value matches, continue with next bit
                        next k_loop;
                    end if;
                end if;
            end loop;
            return result;
        end loop;
    end function;

    -- Part Two: Process oxygen generator and CO2 scrubber ratings.
    function process_report_part2(
        rep : report_t
    ) return rates_t is
        variable result : rates_t := (0, 0, 0, 0);
    begin
        result.oxygen_generator := to_integer(filter_report_value(rep, MOST_COMMON));
        result.co2_scrubber     := to_integer(filter_report_value(rep, LEAST_COMMON));
        return result;
    end function;

begin

    process
        type report_ptr_t is access report_t;
        variable report_ptr     : report_ptr_t;
        variable report_ptr_old : report_ptr_t;

        type unsigned_ptr_t is access unsigned;
        file i_file        : text;
        variable i_line    : line;
        variable value_ptr : unsigned_ptr_t;

        variable rates  : rates_t;
        variable result : natural;
    begin
        -- load commands from input file
        file_open(i_file, "inputs/day_03.txt", read_mode);
        while not endfile(i_file) loop
            readline(i_file, i_line);
            value_ptr := new unsigned(0 to i_line.all'length - 1);
            read(i_line, value_ptr.all);
            -- append value to vector
            if report_ptr = null then
                report_ptr    := new report_t(0 to 0)(value_ptr.all'range);
                report_ptr(0) := value_ptr.all;
            else
                report_ptr_old := report_ptr;
                report_ptr     := new report_t'(report_ptr.all & value_ptr.all);
                deallocate(report_ptr_old);
            end if;
            deallocate(value_ptr);
        end loop;
        file_close(i_file);
        report "Number of numbers in example input: " & integer'image(EXAMPLE_REPORT'length);
        report "Number of numbers in input file: " & integer'image(report_ptr.all'length);

        report "*** Part One ***";

        rates  := process_report_part1(EXAMPLE_REPORT);
        result := rates.gamma * rates.epsilon;
        report "Example input:";
        report " Gamma rate: " & integer'image(rates.gamma);
        assert rates.gamma = 22;
        report " Epsilon rate: " & integer'image(rates.epsilon);
        assert rates.epsilon = 9;
        report " Resulting power consumption: " & integer'image(result);
        assert result = 198;

        rates  := process_report_part1(report_ptr.all);
        result := rates.gamma * rates.epsilon;
        report "Report file input:";
        report " Gamma rate: " & integer'image(rates.gamma);
        report " Epsilon rate: " & integer'image(rates.epsilon);
        report " Resulting power consumption: " & integer'image(result);

        report "*** Part Two ***";

        rates  := process_report_part2(EXAMPLE_REPORT);
        result := rates.oxygen_generator * rates.co2_scrubber;
        report "Example input:";
        report " Oxygen generator rating: " & integer'image(rates.oxygen_generator);
        assert rates.oxygen_generator = 23;
        report " CO2 scrubber rating: " & integer'image(rates.co2_scrubber);
        assert rates.co2_scrubber = 10;
        report " Resulting life support rating: " & integer'image(result);
        assert result = 230;

        rates  := process_report_part2(report_ptr.all);
        result := rates.oxygen_generator * rates.co2_scrubber;
        report "Report file input:";
        report " Oxygen generator rating: " & integer'image(rates.oxygen_generator);
        report " CO2 scrubber rating: " & integer'image(rates.co2_scrubber);
        report " Resulting life support rating: " & integer'image(result);

        deallocate(report_ptr);
        wait;
    end process;

end architecture;