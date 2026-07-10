import SwiftSyntax
import SwiftSyntaxMacros

/// A marker read by `RandomFixtureMacro`; it produces no peers of its own.
public struct RandomFixtureValueMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    []
  }
}
