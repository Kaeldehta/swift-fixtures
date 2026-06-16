import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MockableMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    MockableMacro.self
  ]
}
