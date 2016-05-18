//==-- P3.h - Top-level interface for P3 representation --*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in
// the LLVM P3 backend.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_P3_P3_H
#define LLVM_LIB_TARGET_P3_P3_H

#include "MCTargetDesc/P3MCTargetDesc.h"
#include "llvm/Target/TargetMachine.h"

namespace P3CC {
  // P3 specific condition code.
  enum CondCodes {
    COND_E  = 0,  // aka COND_Z
    COND_NE = 1,  // aka COND_NZ
    COND_HS = 2,  // aka COND_C
    COND_LO = 3,  // aka COND_NC
    COND_GE = 4,
    COND_L  = 5,

    COND_INVALID = -1
  };
}

namespace llvm {
  class P3TargetMachine;
  class FunctionPass;
  class formatted_raw_ostream;

  FunctionPass *createP3ISelDag(P3TargetMachine &TM,
                                    CodeGenOpt::Level OptLevel);

  FunctionPass *createP3BranchSelectionPass();

} // end namespace llvm;

#endif
