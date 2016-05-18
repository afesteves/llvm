//===-- P3TargetMachine.cpp - Define TargetMachine for P3 ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Top-level implementation for the P3 target.
//
//===----------------------------------------------------------------------===//

#include "P3TargetMachine.h"
#include "P3.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

extern "C" void LLVMInitializeP3Target() {
  // Register the target.
  RegisterTargetMachine<P3TargetMachine> X(TheP3Target);
}

P3TargetMachine::P3TargetMachine(const Target &T, const Triple &TT,
                                         StringRef CPU, StringRef FS,
                                         const TargetOptions &Options,
                                         Reloc::Model RM, CodeModel::Model CM,
                                         CodeGenOpt::Level OL)
    : LLVMTargetMachine(T, "e-m:e-p:16:16-i32:16:32-a:16-n8:16", TT, CPU, FS,
                        Options, RM, CM, OL),
      TLOF(make_unique<TargetLoweringObjectFileELF>()),
      // FIXME: Check DataLayout string.
      Subtarget(TT, CPU, FS, *this) {
  initAsmInfo();
}

P3TargetMachine::~P3TargetMachine() {}

namespace {
/// P3 Code Generator Pass Configuration Options.
class P3PassConfig : public TargetPassConfig {
public:
  P3PassConfig(P3TargetMachine *TM, PassManagerBase &PM)
    : TargetPassConfig(TM, PM) {}

  P3TargetMachine &getP3TargetMachine() const {
    return getTM<P3TargetMachine>();
  }

  bool addInstSelector() override;
  void addPreEmitPass() override;
};
} // namespace

TargetPassConfig *P3TargetMachine::createPassConfig(PassManagerBase &PM) {
  return new P3PassConfig(this, PM);
}

bool P3PassConfig::addInstSelector() {
  // Install an instruction selector.
  addPass(createP3ISelDag(getP3TargetMachine(), getOptLevel()));
  return false;
}

void P3PassConfig::addPreEmitPass() {
  // Must run branch selection immediately preceding the asm printer.
  addPass(createP3BranchSelectionPass(), false);
}
