//===-- P3MCTargetDesc.h - P3 Target Descriptions -------*- C++ -*-===//
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

#ifndef LLVM_LIB_TARGET_P3_MCTARGETDESC_P3MCTARGETDESC_H
#define LLVM_LIB_TARGET_P3_MCTARGETDESC_P3MCTARGETDESC_H

#include "llvm/Support/DataTypes.h"

namespace llvm {
class Target;

extern Target TheP3Target;

} // End llvm namespace

// Defines symbolic names for P3 registers.
// This defines a mapping from register name to register number.
#define GET_REGINFO_ENUM
#include "P3GenRegisterInfo.inc"

// Defines symbolic names for the P3 instructions.
#define GET_INSTRINFO_ENUM
#include "P3GenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "P3GenSubtargetInfo.inc"

#endif
