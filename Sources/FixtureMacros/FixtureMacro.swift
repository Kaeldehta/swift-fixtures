import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct FixtureMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      context.diagnose(
        Diagnostic(node: node, message: FixtureDiagnostic.requiresStruct)
      )
      return []
    }

    // Stored properties that are memberwise-init parameters: explicit type, no
    // initializer (those keep their own default), no getter/setter.
    let properties = structDecl.memberBlock.members.compactMap {
      $0.decl.as(VariableDeclSyntax.self)
    }.filter { variable in
      !variable.modifiers.contains { $0.name.tokenKind == .keyword(.static) }
        && !variable.modifiers.contains { $0.name.tokenKind == .keyword(.class) }
    }.flatMap { variable -> [(name: TokenSyntax, type: TypeSyntax)] in
      variable.bindings.compactMap { binding in
        // Skip computed properties, but keep stored ones with willSet/didSet observers.
        if let accessorBlock = binding.accessorBlock {
          switch accessorBlock.accessors {
          case .getter:
            return nil
          case .accessors(let accessors):
            let isComputed = accessors.contains {
              $0.accessorSpecifier.tokenKind == .keyword(.get)
                || $0.accessorSpecifier.tokenKind == .keyword(.set)
            }
            if isComputed { return nil }
          }
        }
        guard binding.initializer == nil,
          let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
          let type = binding.typeAnnotation?.type
        else { return nil }
        return (name: identifier.trimmed, type: type.trimmed)
      }
    }

    let accessModifier = structDecl.modifiers.first {
      [.keyword(.public), .keyword(.package)].contains($0.name.tokenKind)
    }
    let access = accessModifier.map { "\($0.trimmed) " } ?? ""

    let parameters = properties
      .map { "\($0.name): \($0.type) = .fixture" }
      .joined(separator: ",\n")
    let arguments = properties
      .map { "\($0.name): \($0.name)" }
      .joined(separator: ", ")

    let fixtureFunction: DeclSyntax = """
      \(raw: access)static func fixture(\(raw: parameters)) -> Self {
      Self(\(raw: arguments))
      }
      """
    let fixtureProperty: DeclSyntax = "\(raw: access)static var fixture: Self { fixture() }"

    // Only add the `: Fixture` clause when the type doesn't already declare it,
    // otherwise the compiler reports a redundant conformance.
    let inheritance = protocols.isEmpty ? "" : ": Fixture"
    let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed)\(raw: inheritance)") {
      fixtureFunction
      fixtureProperty
    }
    return [extensionDecl]
  }
}
