open Hardcaml
open Signal

module I = struct
  type 'a t = {
    ex_mem_reg_write : 'a;
    ex_mem_rd        : 'a[@width 5];
    mem_wb_reg_write : 'a;
    mem_wb_rd        : 'a[@width 5];
    id_ex_rs1        : 'a[@width 5];
    id_ex_rs2        : 'a[@width 5];
    id_ex_mem_read   : 'a;
    id_ex_rd         : 'a[@width 5];
    if_id_rs1        : 'a[@width 5];
    if_id_rs2        : 'a[@width 5];
  } [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t = {
    forward_a : 'a[@width 2];
    forward_b : 'a[@width 2];
    stall     : 'a;
  } [@@deriving sexp_of, hardcaml]
end

let create (scope : Scope.t) (i : I.t) =
  let open Signal in

  (* Forwarding logic for EX stage *)
  let fw_a_ex = (i.ex_mem_reg_write &: (i.ex_mem_rd <>:. 0) &: (i.ex_mem_rd ==: i.id_ex_rs1)) in
  let fw_a_mem = (i.mem_wb_reg_write &: (i.mem_wb_rd <>:. 0) &: ~:(fw_a_ex) &: (i.mem_wb_rd ==: i.id_ex_rs1)) in
  
  let forward_a = mux2 fw_a_ex (bit_reverse (constz ~width:2 1)) (* 01 *) 
                    (mux2 fw_a_mem (constz ~width:2 2) (constz ~width:2 0)) in

  let fw_b_ex = (i.ex_mem_reg_write &: (i.ex_mem_rd <>:. 0) &: (i.ex_mem_rd ==: i.id_ex_rs2)) in
  let fw_b_mem = (i.mem_wb_reg_write &: (i.mem_wb_rd <>:. 0) &: ~:(fw_b_ex) &: (i.mem_wb_rd ==: i.id_ex_rs2)) in

  let forward_b = mux2 fw_b_ex (constz ~width:2 1) 
                    (mux2 fw_b_mem (constz ~width:2 2) (constz ~width:2 0)) in

  (* Load-use hazard detection stall *)
  let load_use_hazard = i.id_ex_mem_read &: 
    ((i.id_ex_rd ==: i.if_id_rs1) |: (i.id_ex_rd ==: i.if_id_rs2)) in

  { O.forward_a; forward_b; stall = load_use_hazard }
