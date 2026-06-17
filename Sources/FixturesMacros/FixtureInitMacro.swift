import SwiftSyntax
import SwiftSyntaxMacros

/// A marker read by `FixtureMacro` to pick the targeted initializer when a type declares
/// more than one; it produces no peers of its own.
public struct FixtureInitMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    []
  }
}
