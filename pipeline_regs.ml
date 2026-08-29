open Hardcaml
open Signal

module FetchToDecode = struct
  module I = struct
    type 'a t = {
      clock : 'a;
      clear : 'a;
      pc    : 'a[@width 32];
      instr : 'a[@width 32];
    } [@@deriving sexp_of, hardcaml]
  end

  module O = I
  
  let create scope (i : I.t) =
    let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
    {
      O.clock = i.clock;
      clear = i.clear;
      pc    = Reg.spec spec i.pc;
      instr = Reg.spec spec i.instr;
    }
end
