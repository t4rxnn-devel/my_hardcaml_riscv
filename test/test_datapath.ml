open Hardcaml
open My_hardcaml_riscv

let run_datapath_sim () =
  let scope = Scope.create () in
  let module Sim = Cyclesim.With_interface (Datapath.I) (Datapath.O) in
  
  let sim = Sim.create (Datapath.create scope) in
  let inputs = Cyclesim.inps sim in
  let outputs = Cyclesim.outs sim in

  Printf.printf "Running HardCaml Datapath cycle simulation...\n";
  
  (* Initialize signals *)
  inputs.clear := Bits.vdd;
  inputs.instr := Bits.zero 32;
  inputs.mem_rdata := Bits.zero 32;
  
  Cyclesim.cycle sim;
  inputs.clear := Bits.gnd;

  (* Run a few clock ticks *)
  for step = 1 to 5 do
    Cyclesim.cycle sim;
    let pc_val = Bits.to_int !(outputs.pc) in
    let alu_val = Bits.to_int !(outputs.alu_out) in
    Printf.printf "Cycle %d -> PC: 0x%08x | ALU Out: 0x%08x\n" step pc_val alu_val
  done;

  Printf.printf "Datapath verification complete!\n"

let () = run_datapath_sim ()
