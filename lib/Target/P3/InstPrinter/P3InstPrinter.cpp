//===-- P3InstPrinter.cpp - Convert P3 MCInst to assembly syntax --===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints an P3 MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#include "P3InstPrinter.h"
#include "P3.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FormattedStream.h"
using namespace llvm;

#define DEBUG_TYPE "asm-printer"


// Include the auto-generated portion of the assembly writer.
#include "P3GenAsmWriter.inc"

void P3InstPrinter::printInst(const MCInst *MI, raw_ostream &O,
                                  StringRef Annot, const MCSubtargetInfo &STI) {
  printInstruction(MI, O);
  printAnnotation(O, Annot);
}

void P3InstPrinter::printPCRelImmOperand(const MCInst *MI, unsigned OpNo,
                                             raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isImm())
    O << Op.getImm();
  else {
    assert(Op.isExpr() && "unknown pcrel immediate operand");
    Op.getExpr()->print(O, &MAI);
  }
}

void P3InstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                     raw_ostream &O, const char *Modifier) {
  assert((Modifier == nullptr || Modifier[0] == 0) && "No modifiers supported");
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isReg()) {
    O << getRegisterName(Op.getReg());
  } else if (Op.isImm()) {
    O << Op.getImm();
  } else {
    assert(Op.isExpr() && "unknown operand kind in printOperand");
    O << '#';
    Op.getExpr()->print(O, &MAI);
  }
}

void P3InstPrinter::printSrcMemOperand(const MCInst *MI, unsigned OpNo,
                                           raw_ostream &O,
                                           const char *Modifier) {
  const MCOperand &Base = MI->getOperand(OpNo);
  const MCOperand &Disp = MI->getOperand(OpNo+1);

  // Print displacement first

  // If the global address expression is a part of displacement field with a
  // register base, we should not emit any prefix symbol here, e.g.
  //   mov.w &foo, r1
  // vs
  //   mov.w glb(r1), r2
  // Otherwise (!) p3-as will silently miscompile the output :(
  if (!Base.getReg())
    O << '&';

  if (Disp.isExpr())
    Disp.getExpr()->print(O, &MAI);
  else {
    assert(Disp.isImm() && "Expected immediate in displacement field");
    O << Disp.getImm();
  }

  // Print register base field
  if (Base.getReg())
    O << '(' << getRegisterName(Base.getReg()) << ')';
}

void P3InstPrinter::printCCOperand(const MCInst *MI, unsigned OpNo,
                                       raw_ostream &O) {
  unsigned CC = MI->getOperand(OpNo).getImm();

  switch (CC) {
  default:
   llvm_unreachable("Unsupported CC code");
  case P3CC::COND_E:
   O << "eq";
   break;
  case P3CC::COND_NE:
   O << "ne";
   break;
  case P3CC::COND_HS:
   O << "hs";
   break;
  case P3CC::COND_LO:
   O << "lo";
   break;
  case P3CC::COND_GE:
   O << "ge";
   break;
  case P3CC::COND_L:
   O << 'l';
   break;
  }
}
