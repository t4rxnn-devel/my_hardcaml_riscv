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
  let pc_spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let pc = Reg.spec pc_spec (width 32) in
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

  (* 4. ALU Data Path Integration *)
  (* For now, initialize regfile rd1/rd2 feedback paths *)
  let dummy_reg_data = zero 32 in
  let alu_b = mux2 ctrl.alu_src dummy_reg_data dummy_reg_data in
  let alu_input = { ALU.I.a = dummy_reg_data; b = alu_b; op = ctrl.alu_op } in
  let alu_res = ALU.create scope alu_input in

  (* 5. MMIO and FIFO Peripheral Address Decoding (0x30000000) *)
  let is_mmio = (alu_res.result ==: from_int ~width:32 0x30000000) in
  let fifo_inst = Fifo.create scope {
    Fifo.I.clock = i.clock;
    clear = i.clear;
    wr_en = ctrl.mem_write &: is_mmio;
    rd_en = gnd;
    din   = dummy_reg_data;
  } in
  ignore fifo_inst;

  (* 6. Hardware Register File Instantiation with Writeback Bus *)
  let regfile_out = Regfile.create scope {
    Regfile.I.clock;
    we  = ctrl.reg_write;
    wa  = rd;
    wd  = mux2 ctrl.mem_read i.mem_rdata alu_res.result; (* Writeback Mux: Load vs ALU *)
    ra1 = rs1;
    ra2 = rs2;
  } in

  (* 7. Hazard Detection Unit Hookup *)
  let hazard_ctrl = Hazard.create scope {
    Hazard.I.ex_mem_reg_write = ctrl.reg_write;
    ex_mem_rd        = rd;
    mem_wb_reg_write = gnd;
    mem_wb_rd        = zero 5;
    id_ex_rs1        = rs1;
    id_ex_rs2        = rs2;
    id_ex_mem_read   = ctrl.mem_read;
    id_ex_rd         = rd;
    if_id_rs1        = rs1;
    if_id_rs2        = rs2;
  } in
  ignore hazard_ctrl;

  { O.pc; alu_out = alu_res.result; mem_wdata = regfile_out.rd2 }
