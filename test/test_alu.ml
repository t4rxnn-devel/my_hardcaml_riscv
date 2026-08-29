open Hardcaml
open My_hardcaml_riscv

let run_simulation () =
  let scope = Scope.create () in
  let module Sim = Cyclesim.With_interface (Alu.I) (Alu.O) in
  
  let sim = Sim.create (Alu.create scope) in
  let inputs = Cyclesim.inps sim in
  let outputs = Cyclesim.outs sim in

  Printf.printf "Running HardCaml ALU randomized testbench...\n";
  for _ = 1 to 100 do
    let a_val = Random.bits () land 0xFFFFFFFF in
    let b_val = Random.bits () land 0xFFFFFFFF in
    let op_val = Random.int 5 in

    inputs.a := Bits.of_int ~width:32 a_val;
    inputs.b := Bits.of_int ~width:32 b_val;
    inputs.op := Bits.of_int ~width:3 op_val;

    Cyclesim.cycle sim;

    let res = Bits.to_int !(outputs.result) in
    Printf.printf "A: %08x | B: %08x | Op: %d --> Result: %08x\n" a_val b_val op_val res
  done;
  Printf.printf "Simulation completed successfully with zero Verilog emission overhead!\n"

let () = run_simulation ()
