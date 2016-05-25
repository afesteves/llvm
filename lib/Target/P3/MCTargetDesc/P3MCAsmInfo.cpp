//===-- P3MCAsmInfo.cpp - P3 asm properties -----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the P3MCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "P3MCAsmInfo.h"
using namespace llvm;

void P3MCAsmInfo::anchor() { }

P3MCAsmInfo::P3MCAsmInfo(const Triple &TT) {
  PointerSize = CalleeSaveStackSlotSize = 2;

  CommentString = ";";

  AlignmentIsInBytes = false;
  UsesELFSectionDirectiveForBSS = true;
  HasDotTypeDotSizeDirective = false;
  HasSingleParameterDotFile = false;
}
