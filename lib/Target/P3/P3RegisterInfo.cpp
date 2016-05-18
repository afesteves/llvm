//===-- P3RegisterInfo.cpp - P3 Register Information --------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the P3 implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#include "P3RegisterInfo.h"
#include "P3.h"
#include "P3MachineFunctionInfo.h"
#include "P3TargetMachine.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"

using namespace llvm;

#define DEBUG_TYPE "p3-reg-info"

#define GET_REGINFO_TARGET_DESC
#include "P3GenRegisterInfo.inc"

// FIXME: Provide proper call frame setup / destroy opcodes.
P3RegisterInfo::P3RegisterInfo()
  : P3GenRegisterInfo(P3::PC) {}

const MCPhysReg*
P3RegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  const P3FrameLowering *TFI = getFrameLowering(*MF);
  const Function* F = MF->getFunction();
  static const MCPhysReg CalleeSavedRegs[] = {
    P3::FP, P3::R5, P3::R6, P3::R7,
    P3::R8, P3::R9, P3::R10, P3::R11,
    0
  };
  static const MCPhysReg CalleeSavedRegsFP[] = {
    P3::R5, P3::R6, P3::R7,
    P3::R8, P3::R9, P3::R10, P3::R11,
    0
  };
  static const MCPhysReg CalleeSavedRegsIntr[] = {
    P3::FP,  P3::R5,  P3::R6,  P3::R7,
    P3::R8,  P3::R9,  P3::R10, P3::R11,
    P3::R12, P3::R13, P3::R14, P3::R15,
    0
  };
  static const MCPhysReg CalleeSavedRegsIntrFP[] = {
    P3::R5,  P3::R6,  P3::R7,
    P3::R8,  P3::R9,  P3::R10, P3::R11,
    P3::R12, P3::R13, P3::R14, P3::R15,
    0
  };

  if (TFI->hasFP(*MF))
    return (F->getCallingConv() == CallingConv::P3_INTR ?
            CalleeSavedRegsIntrFP : CalleeSavedRegsFP);
  else
    return (F->getCallingConv() == CallingConv::P3_INTR ?
            CalleeSavedRegsIntr : CalleeSavedRegs);

}

BitVector P3RegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  const P3FrameLowering *TFI = getFrameLowering(MF);

  // Mark 4 special registers with subregisters as reserved.
  Reserved.set(P3::PCB);
  Reserved.set(P3::SPB);
  Reserved.set(P3::SRB);
  Reserved.set(P3::CGB);
  Reserved.set(P3::PC);
  Reserved.set(P3::SP);
  Reserved.set(P3::SR);
  Reserved.set(P3::CG);

  // Mark frame pointer as reserved if needed.
  if (TFI->hasFP(MF)) {
    Reserved.set(P3::FPB);
    Reserved.set(P3::FP);
  }

  return Reserved;
}

const TargetRegisterClass *
P3RegisterInfo::getPointerRegClass(const MachineFunction &MF, unsigned Kind)
                                                                         const {
  return &P3::GR16RegClass;
}

void
P3RegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                        int SPAdj, unsigned FIOperandNum,
                                        RegScavenger *RS) const {
  assert(SPAdj == 0 && "Unexpected");

  MachineInstr &MI = *II;
  MachineBasicBlock &MBB = *MI.getParent();
  MachineFunction &MF = *MBB.getParent();
  const P3FrameLowering *TFI = getFrameLowering(MF);
  DebugLoc dl = MI.getDebugLoc();
  int FrameIndex = MI.getOperand(FIOperandNum).getIndex();

  unsigned BasePtr = (TFI->hasFP(MF) ? P3::FP : P3::SP);
  int Offset = MF.getFrameInfo()->getObjectOffset(FrameIndex);

  // Skip the saved PC
  Offset += 2;

  if (!TFI->hasFP(MF))
    Offset += MF.getFrameInfo()->getStackSize();
  else
    Offset += 2; // Skip the saved FP

  // Fold imm into offset
  Offset += MI.getOperand(FIOperandNum + 1).getImm();

  if (MI.getOpcode() == P3::ADD16ri) {
    // This is actually "load effective address" of the stack slot
    // instruction. We have only two-address instructions, thus we need to
    // expand it into mov + add
    const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

    MI.setDesc(TII.get(P3::MOV16rr));
    MI.getOperand(FIOperandNum).ChangeToRegister(BasePtr, false);

    if (Offset == 0)
      return;

    // We need to materialize the offset via add instruction.
    unsigned DstReg = MI.getOperand(0).getReg();
    if (Offset < 0)
      BuildMI(MBB, std::next(II), dl, TII.get(P3::SUB16ri), DstReg)
        .addReg(DstReg).addImm(-Offset);
    else
      BuildMI(MBB, std::next(II), dl, TII.get(P3::ADD16ri), DstReg)
        .addReg(DstReg).addImm(Offset);

    return;
  }

  MI.getOperand(FIOperandNum).ChangeToRegister(BasePtr, false);
  MI.getOperand(FIOperandNum + 1).ChangeToImmediate(Offset);
}

unsigned P3RegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  const P3FrameLowering *TFI = getFrameLowering(MF);
  return TFI->hasFP(MF) ? P3::FP : P3::SP;
}
