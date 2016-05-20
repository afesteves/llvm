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

//===----------------------------------------------------------------------===//
//  Registers
//===----------------------------------------------------------------------===//

def R0  : P3Reg<0,  "r0">;
def R1  : P3Reg<1,  "r1">;
def R2  : P3Reg<2,  "r2">;
def R3  : P3Reg<3,  "r3">;
def R4  : P3Reg<4,  "r4">;
def R5  : P3Reg<5,  "r5">;
def R6  : P3Reg<6,  "r6">;
def R7  : P3Reg<7,  "r7">;

def RE  : P3Reg<8,  "RE">;
def R9  : P3Reg<9,  "R9">;
def FP  : P3Reg<10, "FP">;
def SD  : P3Reg<11, "SD">;
def EA  : P3Reg<12, "EA">;
def RD  : P3Reg<13, "RD">;
def SP  : P3Reg<14, "SP">;
def PC  : P3Reg<15, "PC">;

def GR16 : RegisterClass<"P3", [i16], 16,
  (add
   R0, R1, R2, R3, R4, R5, R6, R7, 
   RE, R9, FP, SD, EA, RD, SP, PC)>;
