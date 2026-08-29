open Hardcaml
open Signal

module I = struct
  type 'a t = {
    opcode : 'a[@width 7];
    funct3 : 'a[@width 3];
    funct7 : 'a[@width 7];
  } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    reg_write : 'a;
    alu_src   : 'a;
    mem_read  : 'a;
    mem_write : 'a;
    branch    : 'a;
    jump      : 'a;
    alu_op    : 'a[@width 3];
  } [@@deriving sexp_of, hardcaml]
end

let create (scope : Scope.t) (i : I.t) =
  let open Signal in
  
  let is_alu_imm = i.opcode ==: from_int ~width:7 0x13 in
  let is_alu_reg = i.opcode ==: from_int ~width:7 0x33 in
  let is_load    = i.opcode ==: from_int ~width:7 0x03 in
  let is_store   = i.opcode ==: from_int ~width:7 0x23 in
  let is_branch  = i.opcode ==: from_int ~width:7 0x63 in
  let is_jal     = i.opcode ==: from_int ~width:7 0x6F in
  let is_jalr    = i.opcode ==: from_int ~width:7 0x67 in

  let reg_write = is_alu_imm |: is_alu_reg |: is_load |: is_jal |: is_jalr in
  let alu_src   = is_alu_imm |: is_load |: is_store in
  let mem_read  = is_load in
  let mem_write = is_store in
  let branch    = is_branch in
  let jump      = is_jal |: is_jalr in
  
  let alu_op = mux2 is_alu_reg (select i.funct3 2 0) (constz ~width:3 0) in

  { O.reg_write; alu_src; mem_read; mem_write; branch; jump; alu_op }
