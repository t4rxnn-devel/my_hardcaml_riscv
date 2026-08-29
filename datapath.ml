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

  (* 1. Hazard Detection & Stall Signal Recurrence Binding *)
  let rec pc_spec = Reg_spec.create ~clock:i.clock ~clear:i.clear ()
  and pc = Reg.spec pc_spec (width 32)
  
  (* 2. RV32I Instruction Field Slicing *)
  and opcode = select i.instr 6 0
  and funct3 = select i.instr 14 12
  and funct7 = select i.instr 31 25
  and rs1    = select i.instr 19 15
  and rs2    = select i.instr 24 20
  and rd     = select i.instr 11 7

  (* 3. Control Unit Decoding *)
  and ctrl = Control.create scope { Control.I.opcode; funct3; funct7 }

  (* 4. Hardware Register File *)
  and regfile_out = Regfile.create scope {
    Regfile.I.clock;
    we  = ctrl.reg_write;
    wa  = rd;
    wd  = mux2 ctrl.mem_read i.mem_rdata alu_res.result;
    ra1 = rs1;
    ra2 = rs2;
  }

  (* 5. ALU Data Path Integration *)
  and alu_b = mux2 ctrl.alu_src (zero 32) regfile_out.rd2
  and alu_input = { ALU.I.a = regfile_out.rd1; b = alu_b; op = ctrl.alu_op }
  and alu_res = ALU.create scope alu_input

  (* 6. MMIO Circular FIFO Peripheral Stream Interconnect (0x30000000) *)
  and is_mmio = (alu_res.result ==: from_int ~width:32 0x30000000)
  and fifo_inst = Fifo.create scope {
    Fifo.I.clock = i.clock;
    clear = i.clear;
    wr_en = ctrl.mem_write &: is_mmio;
    rd_en = gnd;
    din   = regfile_out.rd2;
  }

  (* 7. Hazard Detection & Forwarding Unit Integration *)
  and hazard_ctrl = Hazard.create scope {
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

  (* 8. PC Update Logic with Hazard Stall Support *)
  let next_pc = mux2 hazard_ctrl.stall pc (pc +:. 4) in
  pc <== next_pc;

  ignore fifo_inst;

  { O.pc; alu_out = alu_res.result; mem_wdata = regfile_out.rd2 }
