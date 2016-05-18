//===-- P3MCAsmInfo.h - P3 asm properties --------------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the P3MCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_P3_MCTARGETDESC_P3MCASMINFO_H
#define LLVM_LIB_TARGET_P3_MCTARGETDESC_P3MCASMINFO_H

#include "llvm/MC/MCAsmInfoELF.h"

namespace llvm {
class Triple;

class P3MCAsmInfo : public MCAsmInfoELF {
  void anchor() override;

public:
  explicit P3MCAsmInfo(const Triple &TT);
};

} // namespace llvm

#endif
