open Hardcaml

module Control = struct
  type 'a t = {
    reg_write : 'a;
    alu_op    : 'a; (* 3-bit ALU operation selector *)
    alu_src   : 'a; (* 0: Reg/Imm, 1: Immediate *)
    mem_write : 'a;
    branch    : 'a;
  } [@@deriving sexp_of, hardcaml]
end
