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
    // Public/package access is mirrored onto the generated members.
    let accessModifier = declaration.modifiers.first {
      [.keyword(.public), .keyword(.package)].contains($0.name.tokenKind)
    }
    let access = accessModifier.map { "\($0.trimmed) " } ?? ""

    let members: [DeclSyntax]
    if let structDecl = declaration.as(StructDeclSyntax.self) {
      members = structMembers(of: structDecl, access: access)
    } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
      guard let property = enumFixture(of: enumDecl, access: access) else {
        context.diagnose(Diagnostic(node: node, message: FixtureDiagnostic.enumRequiresCase))
        return []
      }
      members = [property]
    } else {
      context.diagnose(Diagnostic(node: node, message: FixtureDiagnostic.requiresStructOrEnum))
      return []
    }

    // Only add the `: Fixture` clause when the type doesn't already declare it,
    // otherwise the compiler reports a redundant conformance.
    let inheritance = protocols.isEmpty ? "" : ": Fixture"
    let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed)\(raw: inheritance)") {
      for member in members { member }
    }
    return [extensionDecl]
  }

  /// A `fixture(...)` factory whose parameters are the struct's memberwise-init
  /// parameters (each defaulted to `.fixture`), plus the protocol's `static var fixture`.
  private static func structMembers(
    of structDecl: StructDeclSyntax,
    access: String
  ) -> [DeclSyntax] {
    // Stored properties that are memberwise-init parameters: explicit type, no
    // initializer (those keep their own default), no getter/setter.
    let properties = structDecl.memberBlock.members.compactMap {
      $0.decl.as(VariableDeclSyntax.self)
    }.filter { variable in
      !variable.modifiers.contains { $0.name.tokenKind == .keyword(.static) }
        && !variable.modifiers.contains { $0.name.tokenKind == .keyword(.class) }
    }.flatMap { variable -> [(name: TokenSyntax, type: TypeSyntax, defaultValue: String)] in
      // A `@FixtureValue(x)` attribute supplies the parameter's default verbatim.
      let customDefault = variable.attributes
        .compactMap { $0.as(AttributeSyntax.self) }
        .first { $0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "FixtureValue" }
        .flatMap { $0.arguments?.as(LabeledExprListSyntax.self)?.first?.expression }
        .map { "\($0.trimmed)" }
      let defaultValue = customDefault ?? ".fixture"

      return variable.bindings.compactMap { binding in
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
        return (name: identifier.trimmed, type: type.trimmed, defaultValue: defaultValue)
      }
    }

    let parameters = properties
      .map { "\($0.name): \($0.type) = \($0.defaultValue)" }
      .joined(separator: ",\n")
    let arguments = properties
      .map { "\($0.name): \($0.name)" }
      .joined(separator: ", ")

    return [
      """
      \(raw: access)static func fixture(\(raw: parameters)) -> Self {
      Self(\(raw: arguments))
      }
      """,
      "\(raw: access)static var fixture: Self { fixture() }",
    ]
  }

  /// A `static var fixture` returning the case marked with `@FixtureCase` (or the first
  /// case otherwise), with any associated values defaulted to `.fixture`. Returns `nil`
  /// for an enum with no cases.
  private static func enumFixture(
    of enumDecl: EnumDeclSyntax,
    access: String
  ) -> DeclSyntax? {
    let caseDecls = enumDecl.memberBlock.members.compactMap {
      $0.decl.as(EnumCaseDeclSyntax.self)
    }
    let markedCase = caseDecls.first { caseDecl in
      caseDecl.attributes.contains { attribute in
        attribute.as(AttributeSyntax.self)?
          .attributeName.as(IdentifierTypeSyntax.self)?.name.text == "FixtureCase"
      }
    }
    guard let chosenCase = (markedCase ?? caseDecls.first)?.elements.first else { return nil }

    var value = ".\(chosenCase.name.text)"
    if let parameters = chosenCase.parameterClause?.parameters {
      let arguments = parameters.map { parameter -> String in
        if let label = parameter.firstName, label.tokenKind != .wildcard {
          return "\(label.text): .fixture"
        }
        return ".fixture"
      }
      value += "(\(arguments.joined(separator: ", ")))"
    }
    return "\(raw: access)static var fixture: Self { \(raw: value) }"
  }
}
