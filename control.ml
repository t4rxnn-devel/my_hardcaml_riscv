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
    alu_op    : 'a[@width 3];
    alu_src   : 'a;
    reg_write : 'a;
    mem_write : 'a;
  } [@@deriving sexp_of, hardcaml]
end

let create (scope : Scope.t) (i : I.t) =
  let open Signal in
  (* Basic RV32I ALU vs Immediate decoding logic *)
  let is_alu_imm = i.opcode ==:. 0x13 in
  let is_alu_reg = i.opcode ==:. 0x33 in
  let is_load    = i.opcode ==:. 0x03 in
  let is_store   = i.opcode ==:. 0x23 in

  let reg_write = is_alu_imm |: is_alu_reg |: is_load in
  let mem_write = is_store in
  let alu_src   = is_alu_imm |: is_load |: is_store in
  let alu_op    = i.funct3 in (* Map directly for basic ops *)

  { O.alu_op; alu_src; reg_write; mem_write }
