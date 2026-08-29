open Hardcaml

module Circuit_top = struct
  module I = Datapath.I
  module O = Datapath.O

  let create scope (i : I.t) =
    Datapath.create scope i
end

let () =
  let scope = Scope.create () in
  let module Sim = Circuit.With_interface(Circuit_top.I)(Circuit_top.O) in
  let circuit = Sim.create ~name:"rv32i_simple" (Circuit_top.create scope) in
  
  (* Output generated Verilog to standard out *)
  Rtl.output Rtl.Verilog Out_channel.stdout circuit
