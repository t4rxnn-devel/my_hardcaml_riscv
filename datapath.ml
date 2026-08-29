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
  
  (* 1. Program Counter Register & Increment Logic *)
  let pc = Reg.spec (Reg_spec.create ~clock:i.clock ~clear:i.clear ()) (width 32) in
  let next_pc = pc +:. 4 in
  pc <== next_pc;

  (* 2. RV32I Instruction Field Slicing *)
  let opcode = select i.instr 6 0 in
  let funct3 = select i.instr 14 12 in
  let funct7 = select i.instr 31 25 in
  let rs1    = select i.instr 19 15 in
  let rs2    = select i.instr 24 20 in
  let rd     = select i.instr 11 7 in

  (* 3. Control Unit Decoding *)
  let ctrl = Control.create scope { Control.I.opcode; funct3; funct7 } in

  (* 4. Hardware Register File Instantiation *)
  let regfile_out = Regfile.create scope {
    Regfile.I.clock;
    we  = ctrl.reg_write;
    wa  = rd;
    wd  = zero 32; (* Tied to write-back bus later *)
    ra1 = rs1;
    ra2 = rs2;
  } in

  (* 5. ALU Data Path Integration *)
  let alu_b = mux2 ctrl.alu_src (zero 32) regfile_out.rd2 in
  let alu_input = { ALU.I.a = regfile_out.rd1; b = alu_b; op = ctrl.alu_op } in
  let alu_res = ALU.create scope alu_input in

  { O.pc; alu_out = alu_res.result; mem_wdata = regfile_out.rd2 }
