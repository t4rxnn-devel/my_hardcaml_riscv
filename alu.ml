open Hardcaml
open Signal

module I = struct
  type 'a t = {
    a   : 'a[@width 32];
    b   : 'a[@width 32];
    op  : 'a[@width 3];
  } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    result : 'a[@width 32];
    zero   : 'a;
  } [@@deriving sexp_of, hardcaml]
end

let create (scope : Scope.t) (i : I.t) =
  let open Signal in
  let sum  = i.a +: i.b in
  let diff = i.a -: i.b in
  let and_ = i.a &: i.b in
  let or_  = i.a |: i.b in
  let slt  =uresult (uresult (i.a <: i.b)) in (* Simplified comparison *)

  let result = 
    mux i.op [
      sum;   (* 000: Add *)
      diff;  (* 001: Sub *)
      and_;  (* 010: And *)
      or_;   (* 011: Or *)
      slt;   (* 100: Slt *)
      zero 32;
    ]
  in
  let zero = result ==:. 0 in
  { O.result; zero }
