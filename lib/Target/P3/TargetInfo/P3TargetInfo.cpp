//===-- P3TargetInfo.cpp - P3 Target Implementation ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "P3.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

Target llvm::TheP3Target;

extern "C" void LLVMInitializeP3TargetInfo() { 
  RegisterTarget<Triple::p3> 
    X(TheP3Target, "p3", "P3 [experimental]");
}
