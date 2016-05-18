set(LLVM_TARGET_DEFINITIONS P3.td)

tablegen(LLVM P3GenRegisterInfo.inc -gen-register-info)
tablegen(LLVM P3GenInstrInfo.inc -gen-instr-info)
tablegen(LLVM P3GenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM P3GenDAGISel.inc -gen-dag-isel)
tablegen(LLVM P3GenCallingConv.inc -gen-callingconv)
tablegen(LLVM P3GenSubtargetInfo.inc -gen-subtarget)
add_public_tablegen_target(P3CommonTableGen)

add_llvm_target(P3CodeGen
  P3BranchSelector.cpp
  P3ISelDAGToDAG.cpp
  P3ISelLowering.cpp
  P3InstrInfo.cpp
  P3FrameLowering.cpp
  P3MachineFunctionInfo.cpp
  P3RegisterInfo.cpp
  P3Subtarget.cpp
  P3TargetMachine.cpp
  P3AsmPrinter.cpp
  P3MCInstLower.cpp
  )

add_subdirectory(InstPrinter)
add_subdirectory(TargetInfo)
add_subdirectory(MCTargetDesc)
