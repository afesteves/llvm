//===-- P3InstrInfo.td - P3 Instruction defs -------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the P3 instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

include "P3InstrFormats.td"

//===----------------------------------------------------------------------===//
// Type Constraints.
//===----------------------------------------------------------------------===//
class SDTCisI16<int OpNum> : SDTCisVT<OpNum, i16>;

//===----------------------------------------------------------------------===//
// Type Profiles.
//===----------------------------------------------------------------------===//
def SDT_P3Call         : SDTypeProfile<0, -1, [SDTCisVT<0, iPTR>]>;
def SDT_P3CallSeqStart : SDCallSeqStart<[SDTCisVT<0, i16>]>;
def SDT_P3CallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i16>, SDTCisVT<1, i16>]>;
def SDT_P3Wrapper      : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>,
                                                  SDTCisPtrTy<0>]>;
def SDT_P3Cmp          : SDTypeProfile<0, 2, [SDTCisSameAs<0, 1>]>;
def SDT_P3BrCC         : SDTypeProfile<0, 2, [SDTCisVT<0, OtherVT>,
                                                  SDTCisVT<1, i8>]>;
def SDT_P3SelectCC     : SDTypeProfile<1, 3, [SDTCisSameAs<0, 1>,
                                                  SDTCisSameAs<1, 2>, 
                                                  SDTCisVT<3, i8>]>;
def SDT_P3Shift        : SDTypeProfile<1, 2, [SDTCisSameAs<0, 1>,
                                                  SDTCisI16<2>]>;

//===----------------------------------------------------------------------===//
// P3 Specific Node Definitions.
//===----------------------------------------------------------------------===//
def P3retflag  : SDNode<"P3ISD::RET_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;
def P3retiflag : SDNode<"P3ISD::RETI_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

def P3rra     : SDNode<"P3ISD::RRA", SDTIntUnaryOp, []>;
def P3rla     : SDNode<"P3ISD::RLA", SDTIntUnaryOp, []>;
def P3rrc     : SDNode<"P3ISD::RRC", SDTIntUnaryOp, []>;

def P3call    : SDNode<"P3ISD::CALL", SDT_P3Call,
                     [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue, SDNPVariadic]>;
def P3callseq_start :
                 SDNode<"ISD::CALLSEQ_START", SDT_P3CallSeqStart,
                        [SDNPHasChain, SDNPOutGlue]>;
def P3callseq_end :
                 SDNode<"ISD::CALLSEQ_END",   SDT_P3CallSeqEnd,
                        [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;
def P3Wrapper : SDNode<"P3ISD::Wrapper", SDT_P3Wrapper>;
def P3cmp     : SDNode<"P3ISD::CMP", SDT_P3Cmp, [SDNPOutGlue]>;
def P3brcc    : SDNode<"P3ISD::BR_CC", SDT_P3BrCC,
                            [SDNPHasChain, SDNPInGlue]>;
def P3selectcc: SDNode<"P3ISD::SELECT_CC", SDT_P3SelectCC,
                            [SDNPInGlue]>;
def P3shl     : SDNode<"P3ISD::SHL", SDT_P3Shift, []>;
def P3sra     : SDNode<"P3ISD::SRA", SDT_P3Shift, []>;
def P3srl     : SDNode<"P3ISD::SRL", SDT_P3Shift, []>;

//===----------------------------------------------------------------------===//
// P3 Operand Definitions.
//===----------------------------------------------------------------------===//

// Address operands
def memsrc : Operand<i16> {
  let PrintMethod = "printSrcMemOperand";
  let MIOperandInfo = (ops GR16, i16imm);
}

def memdst : Operand<i16> {
  let PrintMethod = "printSrcMemOperand";
  let MIOperandInfo = (ops GR16, i16imm);
}

// Short jump targets have OtherVT type and are printed as pcrel imm values.
def jmptarget : Operand<OtherVT> {
  let PrintMethod = "printPCRelImmOperand";
}

// Operand for printing out a condition code.
def cc : Operand<i8> {
  let PrintMethod = "printCCOperand";
}

//===----------------------------------------------------------------------===//
// P3 Complex Pattern Definitions.
//===----------------------------------------------------------------------===//

def addr : ComplexPattern<iPTR, 2, "SelectAddr", [], []>;

//===----------------------------------------------------------------------===//
// Pattern Fragments
def zextloadi16i8 : PatFrag<(ops node:$ptr), (i16 (zextloadi8 node:$ptr))>;
def  extloadi16i8 : PatFrag<(ops node:$ptr), (i16 ( extloadi8 node:$ptr))>;
def and_su : PatFrag<(ops node:$lhs, node:$rhs), (and node:$lhs, node:$rhs), [{
  return N->hasOneUse();
}]>;
//===----------------------------------------------------------------------===//
// Instruction list..

// ADJCALLSTACKDOWN/UP implicitly use/def SP because they may be expanded into
// a stack adjustment and the codegen must know that they may modify the stack
// pointer before prolog-epilog rewriting occurs.
// Pessimistically assume ADJCALLSTACKDOWN / ADJCALLSTACKUP will become
// sub / add which can clobber SR.
let Defs = [SP, RE], Uses = [SP] in {
def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i16imm:$amt),
                              "#ADJCALLSTACKDOWN",
                              [(P3callseq_start timm:$amt)]>;
def ADJCALLSTACKUP   : Pseudo<(outs), (ins i16imm:$amt1, i16imm:$amt2),
                              "#ADJCALLSTACKUP",
                              [(P3callseq_end timm:$amt1, timm:$amt2)]>;
}

let usesCustomInserter = 1 in {
  def Select16 : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR16:$src2, i8imm:$cc),
                        "# Select16 PSEUDO",
                        [(set GR16:$dst,
                          (P3selectcc GR16:$src, GR16:$src2, imm:$cc))]>;
  let Defs = [RE] in {
  def Shl16    : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR16:$cnt),
                        "# Shl16 PSEUDO",
                        [(set GR16:$dst, (P3shl GR16:$src, GR16:$cnt))]>;
  def Sra16    : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR16:$cnt),
                        "# Sra16 PSEUDO",
                        [(set GR16:$dst, (P3sra GR16:$src, GR16:$cnt))]>;
  def Srl16    : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR16:$cnt),
                        "# Srl16 PSEUDO",
                        [(set GR16:$dst, (P3srl GR16:$src, GR16:$cnt))]>;

  }
}

let hasSideEffects = 0 in
def NOP : Pseudo<(outs), (ins), "nop", []>;

//===----------------------------------------------------------------------===//
//  Control Flow Instructions...
//

// FIXME: Provide proper encoding!
let isReturn = 1, isTerminator = 1, isBarrier = 1 in {
  def RET  : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                     (outs), (ins), "ret",  [(P3retflag)]>;
  def RETI : II16r<0x0, (outs), (ins), "reti", [(P3retiflag)]>;
}

let isBranch = 1, isTerminator = 1 in {

// FIXME: expand opcode & cond field for branches!

// Direct branch
let isBarrier = 1 in {
  // Short branch
  def JMP : CJForm<0, 0, (outs), (ins jmptarget:$dst),
                   "jmp\t$dst",
                   [(br bb:$dst)]>;
  let isIndirectBranch = 1 in {
    // Long branches
    def Bi  : I16ri<0, (outs), (ins i16imm:$brdst),
                    "br\t$brdst",
                    [(brind tblockaddress:$brdst)]>;
    def Br  : I16rr<0, (outs), (ins GR16:$brdst),
                    "br\t$brdst",
                    [(brind GR16:$brdst)]>;
    def Bm  : I16rm<0, (outs), (ins memsrc:$brdst),
                    "br\t$brdst",
                    [(brind (load addr:$brdst))]>;
  }
}

// Conditional branches
let Uses = [RE] in
  def JCC : CJForm<0, 0,
                   (outs), (ins jmptarget:$dst, cc:$cc),
                   "j$cc\t$dst",
                   [(P3brcc bb:$dst, imm:$cc)]>;
} // isBranch, isTerminator

//===----------------------------------------------------------------------===//
//  Call Instructions...
//
let isCall = 1 in
  // All calls clobber the non-callee saved registers. SPW is marked as
  // a use to prevent stack-pointer assignments that appear immediately
  // before calls from potentially appearing dead. Uses for argument
  // registers are added manually.
  let Defs = [EA, RD, SP, PC, RE],
      Uses = [SP] in {
    def CALLi     : II16i<0x0,
                          (outs), (ins i16imm:$dst),
                          "call\t$dst", [(P3call imm:$dst)]>;
    def CALLr     : II16r<0x0,
                          (outs), (ins GR16:$dst),
                          "call\t$dst", [(P3call GR16:$dst)]>;
    def CALLm     : II16m<0x0,
                          (outs), (ins memsrc:$dst),
                          "call\t${dst:mem}", [(P3call (load addr:$dst))]>;
  }


//===----------------------------------------------------------------------===//
//  Miscellaneous Instructions...
//
let Defs = [SP], Uses = [SP], hasSideEffects=0 in {
let mayLoad = 1 in
def POP16r   : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                       (outs GR16:$reg), (ins), "pop.w\t$reg", []>;

let mayStore = 1 in
def PUSH16r  : II16r<0x0,
                     (outs), (ins GR16:$reg), "push.w\t$reg",[]>;
}

//===----------------------------------------------------------------------===//
// Move Instructions

// FIXME: Provide proper encoding!
let hasSideEffects = 0 in {
def MOV16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "mov.w\t{$src, $dst}",
                    []>;
}

// FIXME: Provide proper encoding!
let isReMaterializable = 1, isAsCheapAsAMove = 1 in {
def MOV16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins i16imm:$src),
                    "mov.w\t{$src, $dst}",
                    [(set GR16:$dst, imm:$src)]>;
}

let canFoldAsLoad = 1, isReMaterializable = 1 in {
def MOV16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins memsrc:$src),
                    "mov.w\t{$src, $dst}",
                    [(set GR16:$dst, (load addr:$src))]>;
}

let mayLoad = 1, hasExtraDefRegAllocReq = 1, Constraints = "$base = $base_wb" in {
def MOV16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb), (ins GR16:$base),
                           "mov.w\t{@$base+, $dst}", []>;
}

def MOV16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "mov.w\t{$src, $dst}",
                    [(store (i16 imm:$src), addr:$dst)]>;

def MOV16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "mov.w\t{$src, $dst}",
                    [(store GR16:$src, addr:$dst)]>;

def MOV16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "mov.w\t{$src, $dst}",
                    [(store (i16 (load addr:$src)), addr:$dst)]>;

//===----------------------------------------------------------------------===//
// Arithmetic Instructions

let Constraints = "$src = $dst" in {

let Defs = [RE] in {

let isCommutable = 1 in { // X = ADD Y, Z  == X = ADD Z, Y

def ADD16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "add.w\t{$src2, $dst}",
                    [(set GR16:$dst, (add GR16:$src, GR16:$src2)),
                     (implicit RE)]>;
}

def ADD16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "add.w\t{$src2, $dst}",
                    [(set GR16:$dst, (add GR16:$src, (load addr:$src2))),
                     (implicit RE)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1, 
Constraints = "$base = $base_wb, $src = $dst" in {

def ADD16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb),
                           (ins GR16:$src, GR16:$base),
                          "add.w\t{@$base+, $dst}", []>;
}

def ADD16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "add.w\t{$src2, $dst}",
                    [(set GR16:$dst, (add GR16:$src, imm:$src2)),
                     (implicit RE)]>;

let Constraints = "" in {
def ADD16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "add.w\t{$src, $dst}",
                    [(store (add (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RE)]>;

def ADD16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "add.w\t{$src, $dst}",
                    [(store (add (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RE)]>;

def ADD16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "add.w\t{$src, $dst}",
                    [(store (add (load addr:$dst), 
                                  (i16 (load addr:$src))), addr:$dst),
                     (implicit RE)]>;
}

let Uses = [RE] in {

let isCommutable = 1 in { // X = ADDC Y, Z  == X = ADDC Z, Y
def ADC16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "addc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (adde GR16:$src, GR16:$src2)),
                     (implicit RE)]>;
} // isCommutable

def ADC16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "addc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (adde GR16:$src, imm:$src2)),
                     (implicit RE)]>;

def ADC16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "addc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (adde GR16:$src, (load addr:$src2))),
                     (implicit RE)]>;

let Constraints = "" in {
def ADC16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "addc.w\t{$src, $dst}",
                    [(store (adde (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RE)]>;

def ADC16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "addc.w\t{$src, $dst}",
                    [(store (adde (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RE)]>;

def ADC16mm : I16mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "addc.w\t{$src, $dst}",
                   [(store (adde (load addr:$dst), 
                                 (i16 (load addr:$src))), addr:$dst),
                    (implicit RE)]>;
}

} // Uses = [SR]

let isCommutable = 1 in { // X = AND Y, Z  == X = AND Z, Y
def AND16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "and.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, GR16:$src2)),
                     (implicit RE)]>;
}

def AND16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "and.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, imm:$src2)),
                     (implicit RE)]>;

def AND16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "and.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, (load addr:$src2))),
                     (implicit RE)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1, 
Constraints = "$base = $base_wb, $src = $dst" in {
def AND16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb),
                           (ins GR16:$src, GR16:$base),
                           "and.w\t{@$base+, $dst}", []>;
}

let Constraints = "" in {
def AND16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "and.w\t{$src, $dst}",
                    [(store (and (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RE)]>;

def AND16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "and.w\t{$src, $dst}",
                    [(store (and (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RE)]>;

def AND16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "and.w\t{$src, $dst}",
                    [(store (and (load addr:$dst), 
                                 (i16 (load addr:$src))), addr:$dst),
                     (implicit RE)]>;
}

let isCommutable = 1 in { // X = OR Y, Z  == X = OR Z, Y
def OR16rr : I16rr<0x0,
                   (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                   "bis.w\t{$src2, $dst}",
                   [(set GR16:$dst, (or GR16:$src, GR16:$src2))]>;
}

def OR16ri : I16ri<0x0,
                   (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                   "bis.w\t{$src2, $dst}",
                   [(set GR16:$dst, (or GR16:$src, imm:$src2))]>;

def OR16rm : I16rm<0x0,
                   (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                   "bis.w\t{$src2, $dst}",
                   [(set GR16:$dst, (or GR16:$src, (load addr:$src2)))]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1, 
Constraints = "$base = $base_wb, $src = $dst" in {
def OR16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                          (outs GR16:$dst, GR16:$base_wb),
                          (ins GR16:$src, GR16:$base),
                          "bis.w\t{@$base+, $dst}", []>;
}

let Constraints = "" in {
def OR16mr : I16mr<0x0,
                   (outs), (ins memdst:$dst, GR16:$src),
                   "bis.w\t{$src, $dst}",
                   [(store (or (load addr:$dst), GR16:$src), addr:$dst)]>;

def OR16mi : I16mi<0x0,
                   (outs), (ins memdst:$dst, i16imm:$src),
                   "bis.w\t{$src, $dst}",
                   [(store (or (load addr:$dst), (i16 imm:$src)), addr:$dst)]>;

def OR16mm : I16mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "bis.w\t{$src, $dst}",
                   [(store (or (i16 (load addr:$dst)),
                               (i16 (load addr:$src))), addr:$dst)]>;
}

// bic does not modify condition codes
def BIC16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "bic.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, (not GR16:$src2)))]>;

def BIC16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "bic.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, (not (i16 (load addr:$src2)))))]>;

let Constraints = "" in {
def BIC16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "bic.w\t{$src, $dst}",
                    [(store (and (load addr:$dst), (not GR16:$src)), addr:$dst)]>;

def BIC16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "bic.w\t{$src, $dst}",
                    [(store (and (load addr:$dst),
                                 (not (i16 (load addr:$src)))), addr:$dst)]>;
}

let isCommutable = 1 in { // X = XOR Y, Z  == X = XOR Z, Y
def XOR16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "xor.w\t{$src2, $dst}",
                    [(set GR16:$dst, (xor GR16:$src, GR16:$src2)),
                     (implicit RE)]>;
}

def XOR16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "xor.w\t{$src2, $dst}",
                    [(set GR16:$dst, (xor GR16:$src, imm:$src2)),
                     (implicit RE)]>;

def XOR16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "xor.w\t{$src2, $dst}",
                    [(set GR16:$dst, (xor GR16:$src, (load addr:$src2))),
                     (implicit RE)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1, 
Constraints = "$base = $base_wb, $src = $dst" in {
def XOR16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb),
                           (ins GR16:$src, GR16:$base),
                           "xor.w\t{@$base+, $dst}", []>;
}

let Constraints = "" in {
def XOR16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "xor.w\t{$src, $dst}",
                    [(store (xor (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RE)]>;

def XOR16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "xor.w\t{$src, $dst}",
                    [(store (xor (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RE)]>;

def XOR16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "xor.w\t{$src, $dst}",
                    [(store (xor (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
                     (implicit RE)]>;
}

def SUB16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "sub.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sub GR16:$src, GR16:$src2)),
                     (implicit RE)]>;
def SUB16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "sub.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sub GR16:$src, imm:$src2)),
                     (implicit RE)]>;

def SUB16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "sub.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sub GR16:$src, (load addr:$src2))),
                     (implicit RE)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1, 
Constraints = "$base = $base_wb, $src = $dst" in {
def SUB16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                          (outs GR16:$dst, GR16:$base_wb),
                          (ins GR16:$src, GR16:$base),
                          "sub.w\t{@$base+, $dst}", []>;
}

let Constraints = "" in {
def SUB16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "sub.w\t{$src, $dst}",
                    [(store (sub (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RE)]>;

def SUB16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "sub.w\t{$src, $dst}",
                    [(store (sub (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RE)]>;

def SUB16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "sub.w\t{$src, $dst}",
                    [(store (sub (load addr:$dst), 
                                 (i16 (load addr:$src))), addr:$dst),
                     (implicit RE)]>;
}

let Uses = [RE] in {
def SBC16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "subc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sube GR16:$src, GR16:$src2)),
                     (implicit RE)]>;

def SBC16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "subc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sube GR16:$src, imm:$src2)),
                     (implicit RE)]>;

def SBC16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "subc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sube GR16:$src, (load addr:$src2))),
                     (implicit RE)]>;

let Constraints = "" in {
def SBC16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "subc.w\t{$src, $dst}",
                    [(store (sube (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit RE)]>;

def SBC16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "subc.w\t{$src, $dst}",
                    [(store (sube (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit RE)]>;

def SBC16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "subc.w\t{$src, $dst}",
                    [(store (sube (load addr:$dst),
                            (i16 (load addr:$src))), addr:$dst),
                     (implicit RE)]>;
}

} // Uses = [SR]

// FIXME: memory variant!
def SAR16r1 : II16r<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "rra.w\t$dst",
                    [(set GR16:$dst, (P3rra GR16:$src)),
                     (implicit RE)]>;

def SHL16r1 : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "rla.w\t$dst",
                    [(set GR16:$dst, (P3rla GR16:$src)),
                     (implicit RE)]>;

def SAR16r1c : Pseudo<(outs GR16:$dst), (ins GR16:$src),
                      "clrc\n\t"
                      "rrc.w\t$dst",
                      [(set GR16:$dst, (P3rrc GR16:$src)),
                       (implicit RE)]>;
} // Defs = [SR]

// FIXME: Memory bitswaps?
def SWPB16r : II16r<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "swpb\t$dst",
                    [(set GR16:$dst, (bswap GR16:$src))]>;

} // Constraints = "$src = $dst"

// Integer comparisons
let Defs = [RE] in {
def CMP16rr : I16rr<0x0,
                    (outs), (ins GR16:$src, GR16:$src2),
                    "cmp.w\t{$src2, $src}",
                    [(P3cmp GR16:$src, GR16:$src2), (implicit RE)]>;

def CMP16ri : I16ri<0x0,
                    (outs), (ins GR16:$src, i16imm:$src2),
                    "cmp.w\t{$src2, $src}",
                    [(P3cmp GR16:$src, imm:$src2), (implicit RE)]>;

def CMP16mi : I16mi<0x0,
                    (outs), (ins memsrc:$src, i16imm:$src2),
                    "cmp.w\t{$src2, $src}",
                     [(P3cmp (load addr:$src),
                                 (i16 imm:$src2)), (implicit RE)]>;

def CMP16rm : I16rm<0x0,
                    (outs), (ins GR16:$src, memsrc:$src2),
                    "cmp.w\t{$src2, $src}",
                    [(P3cmp GR16:$src, (load addr:$src2)),
                     (implicit RE)]>;

def CMP16mr : I16mr<0x0,
                    (outs), (ins memsrc:$src, GR16:$src2),
                    "cmp.w\t{$src2, $src}",
                    [(P3cmp (load addr:$src), GR16:$src2), 
                     (implicit RE)]>;


// BIT TESTS, just sets condition codes
// Note that the C condition is set differently than when using CMP.
let isCommutable = 1 in {
def BIT16rr : I16rr<0x0,
                    (outs), (ins GR16:$src, GR16:$src2),
                    "bit.w\t{$src2, $src}",
                    [(P3cmp (and_su GR16:$src, GR16:$src2), 0),
                     (implicit RE)]>;
}
def BIT16ri : I16ri<0x0,
                    (outs), (ins GR16:$src, i16imm:$src2),
                    "bit.w\t{$src2, $src}",
                    [(P3cmp (and_su GR16:$src, imm:$src2), 0),
                     (implicit RE)]>;

def BIT16rm : I16rm<0x0,
                    (outs), (ins GR16:$src, memdst:$src2),
                    "bit.w\t{$src2, $src}",
                    [(P3cmp (and_su GR16:$src,  (load addr:$src2)), 0),
                     (implicit RE)]>;

def BIT16mr : I16mr<0x0,
                    (outs), (ins memsrc:$src, GR16:$src2),
                    "bit.w\t{$src2, $src}",
                    [(P3cmp (and_su (load addr:$src), GR16:$src2), 0),
                     (implicit RE)]>;

def BIT16mi : I16mi<0x0,
                    (outs), (ins memsrc:$src, i16imm:$src2),
                    "bit.w\t{$src2, $src}",
                    [(P3cmp (and_su (load addr:$src), (i16 imm:$src2)), 0),
                     (implicit RE)]>;

def BIT16mm : I16mm<0x0,
                    (outs), (ins memsrc:$src, memsrc:$src2),
                    "bit.w\t{$src2, $src}",
                    [(P3cmp (and_su (i16 (load addr:$src)),
                                        (load addr:$src2)),
                                 0),
                     (implicit RE)]>;
} // Defs = [SR]

//===----------------------------------------------------------------------===//
// Non-Instruction Patterns

// GlobalAddress, ExternalSymbol
def : Pat<(i16 (P3Wrapper tglobaladdr:$dst)), (MOV16ri tglobaladdr:$dst)>;
def : Pat<(i16 (P3Wrapper texternalsym:$dst)), (MOV16ri texternalsym:$dst)>;
def : Pat<(i16 (P3Wrapper tblockaddress:$dst)), (MOV16ri tblockaddress:$dst)>;

def : Pat<(add GR16:$src, (P3Wrapper tglobaladdr :$src2)),
          (ADD16ri GR16:$src, tglobaladdr:$src2)>;
def : Pat<(add GR16:$src, (P3Wrapper texternalsym:$src2)),
          (ADD16ri GR16:$src, texternalsym:$src2)>;
def : Pat<(add GR16:$src, (P3Wrapper tblockaddress:$src2)),
          (ADD16ri GR16:$src, tblockaddress:$src2)>;

def : Pat<(store (i16 (P3Wrapper tglobaladdr:$src)), addr:$dst),
          (MOV16mi addr:$dst, tglobaladdr:$src)>;
def : Pat<(store (i16 (P3Wrapper texternalsym:$src)), addr:$dst),
          (MOV16mi addr:$dst, texternalsym:$src)>;
def : Pat<(store (i16 (P3Wrapper tblockaddress:$src)), addr:$dst),
          (MOV16mi addr:$dst, tblockaddress:$src)>;

// calls
def : Pat<(P3call (i16 tglobaladdr:$dst)),
          (CALLi tglobaladdr:$dst)>;
def : Pat<(P3call (i16 texternalsym:$dst)),
          (CALLi texternalsym:$dst)>;

// add and sub always produce carry
def : Pat<(addc GR16:$src, GR16:$src2),
          (ADD16rr GR16:$src, GR16:$src2)>;
def : Pat<(addc GR16:$src, (load addr:$src2)),
          (ADD16rm GR16:$src, addr:$src2)>;
def : Pat<(addc GR16:$src, imm:$src2),
          (ADD16ri GR16:$src, imm:$src2)>;
def : Pat<(store (addc (load addr:$dst), GR16:$src), addr:$dst),
          (ADD16mr addr:$dst, GR16:$src)>;
def : Pat<(store (addc (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
          (ADD16mm addr:$dst, addr:$src)>;

def : Pat<(subc GR16:$src, GR16:$src2),
          (SUB16rr GR16:$src, GR16:$src2)>;
def : Pat<(subc GR16:$src, (load addr:$src2)),
          (SUB16rm GR16:$src, addr:$src2)>;
def : Pat<(subc GR16:$src, imm:$src2),
          (SUB16ri GR16:$src, imm:$src2)>;
def : Pat<(store (subc (load addr:$dst), GR16:$src), addr:$dst),
          (SUB16mr addr:$dst, GR16:$src)>;
def : Pat<(store (subc (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
          (SUB16mm addr:$dst, addr:$src)>;

