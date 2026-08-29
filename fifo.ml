open Hardcaml
open Signal

module I = struct
  type 'a t = {
    clock  : 'a;
    clear  : 'a;
    wr_en  : 'a;
    rd_en  : 'a;
    din    : 'a[@width 32];
  } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    dout   : 'a[@width 32];
    full   : 'a;
    empty  : 'a;
  } [@@deriving sexp_of, hardcaml]
end

let create (scope : Scope.t) (i : I.t) =
  let open Signal in
  let addr_width = 4 in (* 16-entry deep FIFO *)
  let depth = 1 lsl addr_width in

  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  
  (* Head and Tail pointers *)
  let wr_ptr = Reg.spec spec (width addr_width) in
  let rd_ptr = Reg.spec spec (width addr_width) in
  let count  = Reg.spec spec (width (addr_width + 1)) in

  let full  = count ==:. depth in
  let empty = count ==:. 0 in

  (* RAM Block for ring buffer storage *)
  let ram_we = i.wr_en &: ~:full in
  let dout = RAM.create ~size:depth ~arch:Auto ~wr_address:(some wr_ptr) ~wr_data:i.din ~wr_enable:ram_we ~rd_address:rd_ptr () in

  (* Pointer arithmetic & tracking *)
  let next_wr = mux2 (i.wr_en &: ~:full) (wr_ptr +:. 1) wr_ptr in
  let next_rd = mux2 (i.rd_en &: ~:empty) (rd_ptr +:. 1) rd_ptr in
  
  let count_delta = mux2 (i.wr_en &: ~:full) (mux2 (i.rd_en &: ~:empty) (constz ~width:(addr_width + 1) 0) (constz ~width:(addr_width + 1) 1))
                      (mux2 (i.rd_en &: ~:empty) (neg (constz ~width:(addr_width + 1) 1)) (constz ~width:(addr_width + 1) 0)) in

  wr_ptr <== next_wr;
  rd_ptr <== next_rd;
  count  <== count + count_delta;

  { O.dout; full; empty }
