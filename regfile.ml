open Hardcaml
open Signal

module I = struct
  type 'a t = {
    clock     : 'a;
    we        : 'a;
    wa        : 'a[@width 5];
    wd        : 'a[@width 32];
    ra1       : 'a[@width 5];
    ra2       : 'a[@width 5];
  } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    rd1       : 'a[@width 32];
    rd2       : 'a[@width 32];
  } [@@deriving sexp_of, hardcaml]
end

let create (scope : Scope.t) (i : I.t) =
  let open Signal in
  let ram = RAM.create ~size:32 ~patch_wr_during_rd:false 
             ~clock:i.clock ~we:i.we ~wa:i.wa ~wd:i.wd () in
  
  let rd1 = mux i.ra1 [zero 32; ram.rd @. i.ra1] in
  let rd2 = mux i.ra2 [zero 32; ram.rd @. i.ra2] in

  { O.rd1; rd2 }
