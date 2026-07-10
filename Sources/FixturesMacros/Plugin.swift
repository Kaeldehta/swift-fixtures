import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FixtureMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    FixtureMacro.self,
    FixtureCaseMacro.self,
    FixtureInitMacro.self,
    FixtureValueMacro.self,
    RandomFixtureMacro.self,
    RandomFixtureValueMacro.self,
  ]
}
