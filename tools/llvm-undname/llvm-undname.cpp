//===-- llvm-undname.cpp - Microsoft ABI name undecorator
//------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This utility works like the windows undname utility. It converts mangled
// Microsoft symbol names into pretty C/C++ human-readable names.
//
//===----------------------------------------------------------------------===//

#include "llvm/ADT/StringRef.h"
#include "llvm/Demangle/Demangle.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorOr.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Process.h"
#include "llvm/Support/WithColor.h"
#include "llvm/Support/raw_ostream.h"
#include <cstdio>
#include <cstring>
#include <iostream>
#include <string>

using namespace llvm;

cl::opt<bool> DumpBackReferences("backrefs", cl::Optional,
                                 cl::desc("dump backreferences"), cl::Hidden,
                                 cl::init(false));
cl::opt<std::string> RawFile("raw-file", cl::Optional,
                             cl::desc("for fuzzer data"), cl::Hidden);
cl::list<std::string> Symbols(cl::Positional, cl::desc("<input symbols>"),
                              cl::ZeroOrMore);

static bool msDemangle(const std::string &S) {
  int Status;
  MSDemangleFlags Flags = MSDF_None;
  if (DumpBackReferences)
    Flags = MSDemangleFlags(Flags | MSDF_DumpBackrefs);

  char *ResultBuf =
      microsoftDemangle(S.c_str(), nullptr, nullptr, &Status, Flags);
  if (Status == llvm::demangle_success) {
    outs() << ResultBuf << "\n";
    outs().flush();
  } else {
    WithColor::error() << "Invalid mangled name\n";
  }
  std::free(ResultBuf);
  return Status == llvm::demangle_success;
}

int main(int argc, char **argv) {
  InitLLVM X(argc, argv);

  cl::ParseCommandLineOptions(argc, argv, "llvm-undname\n");

  if (!RawFile.empty()) {
    ErrorOr<std::unique_ptr<MemoryBuffer>> FileOrErr =
        MemoryBuffer::getFileOrSTDIN(RawFile);
    if (std::error_code EC = FileOrErr.getError()) {
      WithColor::error() << "Could not open input file \'" << RawFile
                         << "\': " << EC.message() << '\n';
      return 1;
    }
    return msDemangle(FileOrErr->get()->getBuffer()) ? 0 : 1;
  }

  bool Success = true;
  if (Symbols.empty()) {
    while (true) {
      std::string LineStr;
      std::getline(std::cin, LineStr);
      if (std::cin.eof())
        break;

      StringRef Line(LineStr);
      Line = Line.trim();
      if (Line.empty() || Line.startswith("#") || Line.startswith(";"))
        continue;

      // If the user is manually typing in these decorated names, don't echo
      // them to the terminal a second time.  If they're coming from redirected
      // input, however, then we should display the input line so that the
      // mangled and demangled name can be easily correlated in the output.
      if (!sys::Process::StandardInIsUserInput()) {
        outs() << Line << "\n";
        outs().flush();
      }
      if (!msDemangle(Line))
        Success = false;
      outs() << "\n";
    }
  } else {
    for (StringRef S : Symbols) {
      outs() << S << "\n";
      outs().flush();
      if (!msDemangle(S))
        Success = false;
      outs() << "\n";
    }
  }

  return Success ? 0 : 1;
}
