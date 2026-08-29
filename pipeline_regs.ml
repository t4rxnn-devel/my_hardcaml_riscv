open Hardcaml
open Signal

module StageReg (Config : sig val width : int end) = struct
  module I = struct
    type 'a t = {
      clock : 'a;
      clear : 'a;
      stall : 'a;
      d     : 'a[@width Config.width];
    } [@@deriving sexp_of, hardcaml]
  end

  module O = I

  let create scope (i : I.t) =
    let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
    (* Hold current state if stall is asserted, otherwise load new data *)
    let q = Reg.spec spec (mux2 i.stall (reg_specify spec i.d) i.d) in
    { O.clock = i.clock; clear = i.clear; stall = i.stall; d = q }
end

(* Pipeline register boundaries can be typed and instantiated using record bundles *)
