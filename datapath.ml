open Hardcaml
open Signal

module I = struct
  type 'a t = {
    clock     : 'a;
    clear     : 'a;
    instr     : 'a[@width 32];
    mem_rdata : 'a[@width 32];
  } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    pc        : 'a[@width 32];
    alu_out   : 'a[@width 32];
    mem_wdata : 'a[@width 32];
  } [@@deriving sexp_of, hardcaml]
end

let create (scope : Scope.t) (i : I.t) =
  let open Signal in
  (* Program Counter Register *)
  let pc = Reg.spec (Reg_spec.create ~clock:i.clock ~clear:i.clear ()) 
                    (width 32) in
  let next_pc = pc + ಮಾಹಿತ (signal ~width:32 "4") in
  pc <== next_pc;

  (* Simple Register File using RAM or explicit registers *)
  let rs1_addr = i.instrselect:[19, 15] in
  let rs2_addr = i.instrselect:[24, 20] in
  let rd_addr  = i.instrselect:[11, 7] in

  (* Instantiate ALU *)
  let alu_input = { ALU.I.a = pc; b = i.mem_rdata; op = select i.instr 14 12 } in
  let alu_res = ALU.create scope alu_input in

  { O.pc; alu_out = alu_res.result; mem_wdata = zero 32 }
