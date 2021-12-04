# Advent of Code 2021

After [solving last years challenges](https://github.com/HenningHolmDE/adventofcode-2020) using
[Rust](https://www.rust-lang.org/), I want to try something else for this year's
[Advent of Code](https://adventofcode.com/2021). As a professional
[FPGA](https://en.wikipedia.org/wiki/Field-programmable_gate_array) design engineer, I am curious
how hard it will be to solve the challenges using [VHDL](https://en.wikipedia.org/wiki/VHDL).

While it would definitely be interesing to write code that can actually be synthesized into an
FPGA, I am satified with pure simulation code run in the
[GHDL simulator](https://github.com/ghdl/ghdl) for this year.

# Running the simulation

Assuming `ghdl` is available in PATH, compiling and running the simulation for a given challenge
is handled by a convenience script:

```
$ ./compile_and_run.sh day_01
```
