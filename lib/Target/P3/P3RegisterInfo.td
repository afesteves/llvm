//===-- P3RegisterInfo.td - P3 Register defs -------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the P3 register file
//===----------------------------------------------------------------------===//

class P3Reg<bits<4> num, string n> : Register<n> {
  field bits<4> Num = num;
  let Namespace = "P3";
}

class P3RegWithSubregs<bits<4> num, string n, list<Register> subregs> 
  : RegisterWithSubRegs<n, subregs> {
  field bits<4> Num = num;
  let Namespace = "P3";
}

//===----------------------------------------------------------------------===//
//  Registers
//===----------------------------------------------------------------------===//

def PCB  : P3Reg<0,  "r0">;
def SPB  : P3Reg<1,  "r1">;
def SRB  : P3Reg<2,  "r2">;
def CGB  : P3Reg<3,  "r3">;
def FPB  : P3Reg<4,  "r4">;
def R5B  : P3Reg<5,  "r5">;
def R6B  : P3Reg<6,  "r6">;
def R7B  : P3Reg<7,  "r7">;
def R8B  : P3Reg<8,  "r8">;
def R9B  : P3Reg<9,  "r9">;
def R10B : P3Reg<10, "r10">;
def R11B : P3Reg<11, "r11">;
def R12B : P3Reg<12, "r12">;
def R13B : P3Reg<13, "r13">;
def R14B : P3Reg<14, "r14">;
def R15B : P3Reg<15, "r15">;

def subreg_8bit : SubRegIndex<8> { let Namespace = "P3"; }

let SubRegIndices = [subreg_8bit] in {
def PC  : P3RegWithSubregs<0,  "r0",  [PCB]>;
def SP  : P3RegWithSubregs<1,  "r1",  [SPB]>;
def SR  : P3RegWithSubregs<2,  "r2",  [SRB]>;
def CG  : P3RegWithSubregs<3,  "r3",  [CGB]>;
def FP  : P3RegWithSubregs<4,  "r4",  [FPB]>;
def R5  : P3RegWithSubregs<5,  "r5",  [R5B]>;
def R6  : P3RegWithSubregs<6,  "r6",  [R6B]>;
def R7  : P3RegWithSubregs<7,  "r7",  [R7B]>;
def R8  : P3RegWithSubregs<8,  "r8",  [R8B]>;
def R9  : P3RegWithSubregs<9,  "r9",  [R9B]>;
def R10 : P3RegWithSubregs<10, "r10", [R10B]>;
def R11 : P3RegWithSubregs<11, "r11", [R11B]>;
def R12 : P3RegWithSubregs<12, "r12", [R12B]>;
def R13 : P3RegWithSubregs<13, "r13", [R13B]>;
def R14 : P3RegWithSubregs<14, "r14", [R14B]>;
def R15 : P3RegWithSubregs<15, "r15", [R15B]>;
}

def GR8 : RegisterClass<"P3", [i8], 8,
   // Volatile registers
  (add R12B, R13B, R14B, R15B, R11B, R10B, R9B, R8B, R7B, R6B, R5B,
   // Frame pointer, sometimes allocable
   FPB,
   // Volatile, but not allocable
   PCB, SPB, SRB, CGB)>;

def GR16 : RegisterClass<"P3", [i16], 16,
   // Volatile registers
  (add R12, R13, R14, R15, R11, R10, R9, R8, R7, R6, R5,
   // Frame pointer, sometimes allocable
   FP,
   // Volatile, but not allocable
   PC, SP, SR, CG)>;
