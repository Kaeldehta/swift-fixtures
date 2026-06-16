import SwiftDiagnostics
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
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      context.diagnose(
        Diagnostic(node: node, message: MockableDiagnostic.requiresStruct)
      )
      return []
    }

    // Memberwise-init parameters: stored properties with an explicit type annotation,
    // no initializer, and no getter/setter. Properties with an initializer use their
    // own default and are omitted from both the signature and the `Self(...)` call.
    let properties = structDecl.memberBlock.members.compactMap {
      $0.decl.as(VariableDeclSyntax.self)
    }.filter { variable in
      !variable.modifiers.contains { $0.name.tokenKind == .keyword(.static) }
        && !variable.modifiers.contains { $0.name.tokenKind == .keyword(.class) }
    }.flatMap { variable -> [(name: TokenSyntax, type: TypeSyntax)] in
      variable.bindings.compactMap { binding in
        // Skip computed properties (a getter/setter accessor block); keep `willSet`/
        // `didSet` observers, which are still stored.
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
        // Skip properties that already have an initializer.
        guard binding.initializer == nil,
          let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
          let type = binding.typeAnnotation?.type
        else { return nil }
        return (name: identifier.trimmed, type: type.trimmed)
      }
    }

    // Mirror the struct's access level on the generated members.
    let accessModifier = structDecl.modifiers.first {
      [.keyword(.public), .keyword(.package)].contains($0.name.tokenKind)
    }
    let access = accessModifier.map { "\($0.trimmed) " } ?? ""

    let parameters = properties
      .map { "\($0.name): \($0.type) = .mock" }
      .joined(separator: ",\n")
    let arguments = properties
      .map { "\($0.name): \($0.name)" }
      .joined(separator: ", ")

    let mockFunction: DeclSyntax = """
      \(raw: access)static func mock(\(raw: parameters)) -> Self {
      Self(\(raw: arguments))
      }
      """
    let mockProperty: DeclSyntax = "\(raw: access)static var mock: Self { mock() }"

    // Only add the `: Mockable` clause when the type doesn't already declare it,
    // otherwise the compiler reports a redundant conformance.
    let inheritance = protocols.isEmpty ? "" : ": Mockable"
    let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed)\(raw: inheritance)") {
      mockFunction
      mockProperty
    }
    return [extensionDecl]
  }
}
