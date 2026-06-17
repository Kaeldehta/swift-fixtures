import SwiftSyntax
import SwiftSyntaxMacros

/// A marker read by `FixtureMacro`; it produces no peers of its own.
public struct FixtureValueMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    []
  }
}
