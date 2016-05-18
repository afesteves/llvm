//===-- P3MCTargetDesc.cpp - P3 Target Descriptions ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides P3 specific target descriptions.
//
//===----------------------------------------------------------------------===//

#include "P3MCTargetDesc.h"
#include "InstPrinter/P3InstPrinter.h"
#include "P3MCAsmInfo.h"
#include "llvm/MC/MCCodeGenInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

#define GET_INSTRINFO_MC_DESC
#include "P3GenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "P3GenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "P3GenRegisterInfo.inc"

static MCInstrInfo *createP3MCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitP3MCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createP3MCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitP3MCRegisterInfo(X, P3::PC);
  return X;
}

static MCSubtargetInfo *
createP3MCSubtargetInfo(const Triple &TT, StringRef CPU, StringRef FS) {
  return createP3MCSubtargetInfoImpl(TT, CPU, FS);
}

static MCCodeGenInfo *createP3MCCodeGenInfo(const Triple &TT,
                                                Reloc::Model RM,
                                                CodeModel::Model CM,
                                                CodeGenOpt::Level OL) {
  MCCodeGenInfo *X = new MCCodeGenInfo();
  X->initMCCodeGenInfo(RM, CM, OL);
  return X;
}

static MCInstPrinter *createP3MCInstPrinter(const Triple &T,
                                                unsigned SyntaxVariant,
                                                const MCAsmInfo &MAI,
                                                const MCInstrInfo &MII,
                                                const MCRegisterInfo &MRI) {
  if (SyntaxVariant == 0)
    return new P3InstPrinter(MAI, MII, MRI);
  return nullptr;
}

extern "C" void LLVMInitializeP3TargetMC() {
  // Register the MC asm info.
  RegisterMCAsmInfo<P3MCAsmInfo> X(TheP3Target);

  // Register the MC codegen info.
  TargetRegistry::RegisterMCCodeGenInfo(TheP3Target,
                                        createP3MCCodeGenInfo);

  // Register the MC instruction info.
  TargetRegistry::RegisterMCInstrInfo(TheP3Target, createP3MCInstrInfo);

  // Register the MC register info.
  TargetRegistry::RegisterMCRegInfo(TheP3Target,
                                    createP3MCRegisterInfo);

  // Register the MC subtarget info.
  TargetRegistry::RegisterMCSubtargetInfo(TheP3Target,
                                          createP3MCSubtargetInfo);

  // Register the MCInstPrinter.
  TargetRegistry::RegisterMCInstPrinter(TheP3Target,
                                        createP3MCInstPrinter);
}
