#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

func errPrint(_ message: String) {
  var msg = message.hasSuffix("\n") ? message : message + "\n"
  msg.withUTF8 { ptr in
    _ = write(STDERR_FILENO, ptr.baseAddress, ptr.count)
  }
}

guard CommandLine.arguments.count == 3 else {
  errPrint("Usage: TACodeGenerator <xml-input-path> <swift-output-path>")
  exit(1)
}

let xmlPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

do {
  let functions = try TAFuncAPIParser.parse(path: xmlPath)
  let source = SwiftCodeEmitter(functions: functions).emit()

  guard let file = fopen(outputPath, "w") else {
    errPrint("Error: cannot write to \(outputPath)")
    exit(1)
  }
  _ = source.withCString { ptr in fputs(ptr, file) }
  fclose(file)

  print("Generated \(functions.count) functions → \(outputPath)")
} catch {
  errPrint("Error: \(error)")
  exit(1)
}
