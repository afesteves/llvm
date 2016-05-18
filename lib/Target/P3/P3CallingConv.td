//==- P3CallingConv.td - Calling Conventions for P3 -*- tablegen -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
// This describes the calling conventions for P3 architecture.
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// P3 Return Value Calling Convention
//===----------------------------------------------------------------------===//
def RetCC_P3 : CallingConv<[
  // i8 are returned in registers R15B, R14B, R13B, R12B
  CCIfType<[i8], CCAssignToReg<[R15B, R14B, R13B, R12B]>>,

  // i16 are returned in registers R15, R14, R13, R12
  CCIfType<[i16], CCAssignToReg<[R15, R14, R13, R12]>>
]>;

//===----------------------------------------------------------------------===//
// P3 Argument Calling Conventions
//===----------------------------------------------------------------------===//
def CC_P3_AssignStack : CallingConv<[
  // Pass by value if the byval attribute is given
  CCIfByVal<CCPassByVal<2, 2>>,

  // Promote i8 arguments to i16.
  CCIfType<[i8], CCPromoteToType<i16>>,

  // Integer values get stored in stack slots that are 2 bytes in
  // size and 2-byte aligned.
  CCIfType<[i16], CCAssignToStack<2, 2>>
]>;

