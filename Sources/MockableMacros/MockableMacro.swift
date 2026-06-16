import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct MockableMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    // TODO: read stored properties from `declaration` and synthesize
    //       `static func mock(<prop>: <Type> = <default>) -> Self`,
    //       choosing a default value per property type.
    let ext = try ExtensionDeclSyntax("extension \(type.trimmed)") {
      DeclSyntax(#"static func mock() -> Self { fatalError("unimplemented") }"#)
    }
    return [ext]
  }
}
