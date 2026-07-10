import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct RandomFixtureMacro: ExtensionMacro {
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

    let member: DeclSyntax
    if let structDecl = declaration.as(StructDeclSyntax.self) {
      guard let structMember = structMember(of: structDecl, access: access, node: node, in: context)
      else { return [] }
      member = structMember
    } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
      guard let enumMember = enumMember(of: enumDecl, access: access) else {
        context.diagnose(
          Diagnostic(node: node, message: FixtureDiagnostic.randomFixtureEnumRequiresCase))
        return []
      }
      member = enumMember
    } else {
      context.diagnose(
        Diagnostic(node: node, message: FixtureDiagnostic.randomFixtureRequiresStructOrEnum))
      return []
    }

    // Only add the `: RandomFixture` clause when the type doesn't already declare it,
    // otherwise the compiler reports a redundant conformance.
    let inheritance = protocols.isEmpty ? "" : ": RandomFixture"
    let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed)\(raw: inheritance)") {
      member
    }
    return [extensionDecl]
  }

  /// A `randomFixture(using:)` that draws every memberwise-init parameter from its own
  /// `RandomFixture` (or from the generator given in `@RandomFixtureValue`).
  ///
  /// Only the memberwise path is supported: a struct that declares an initializer in its
  /// body is diagnosed, mirroring the `@Fixture` guidance to declare custom initializers
  /// in an extension. Returns `nil` when a diagnostic was emitted.
  private static func structMember(
    of structDecl: StructDeclSyntax,
    access: String,
    node: AttributeSyntax,
    in context: some MacroExpansionContext
  ) -> DeclSyntax? {
    let declaresInitializer = structDecl.memberBlock.members.contains {
      $0.decl.is(InitializerDeclSyntax.self)
    }
    guard !declaresInitializer else {
      context.diagnose(
        Diagnostic(node: node, message: FixtureDiagnostic.randomFixtureRequiresMemberwise))
      return nil
    }

    // Stored properties that are memberwise-init parameters: explicit type, no
    // initializer (those keep their own default), no getter/setter.
    let properties = structDecl.memberBlock.members.compactMap {
      $0.decl.as(VariableDeclSyntax.self)
    }.filter { variable in
      !variable.modifiers.contains { $0.name.tokenKind == .keyword(.static) }
        && !variable.modifiers.contains { $0.name.tokenKind == .keyword(.class) }
    }.flatMap { variable -> [(name: TokenSyntax, draw: String)] in
      // A `@RandomFixtureValue(g)` attribute supplies the generator to draw from.
      let customGenerator = randomFixtureValue(of: variable).map { "(\($0.expression.trimmed))" }
      let draw = customGenerator.map { "\($0).run(using: &rng)" } ?? ".randomFixture(using: &rng)"

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
          binding.pattern.is(IdentifierPatternSyntax.self),
          binding.typeAnnotation != nil,
          let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
        else { return nil }
        return (name: identifier.trimmed, draw: draw)
      }
    }

    let arguments =
      properties
      .map { "\($0.name): \($0.draw)" }
      .joined(separator: ",\n")
    return """
      \(raw: access)static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Self {
        Self(\(raw: arguments))
      }
      """
  }

  /// A `randomFixture(using:)` that picks a case uniformly at random, with associated
  /// values drawn from their own `RandomFixture`. Returns `nil` for an enum with no
  /// cases.
  private static func enumMember(
    of enumDecl: EnumDeclSyntax,
    access: String
  ) -> DeclSyntax? {
    let cases = enumDecl.memberBlock.members
      .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
      .flatMap { $0.elements }
    guard !cases.isEmpty else { return nil }

    let values = cases.map { caseElement -> String in
      var value = ".\(caseElement.name.text)"
      if let parameters = caseElement.parameterClause?.parameters {
        let arguments = parameters.map { parameter -> String in
          if let label = parameter.firstName, label.tokenKind != .wildcard {
            return "\(label.text): .randomFixture(using: &rng)"
          }
          return ".randomFixture(using: &rng)"
        }
        value += "(\(arguments.joined(separator: ", ")))"
      }
      return value
    }

    if values.count == 1 {
      return """
        \(raw: access)static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Self {
          \(raw: values[0])
        }
        """
    }

    let branches = values.enumerated().map { index, value in
      index == values.count - 1 ? "default:\n    return \(value)" : "case \(index):\n    return \(value)"
    }.joined(separator: "\n  ")
    return """
      \(raw: access)static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Self {
        switch Int.random(in: 0 ..< \(raw: values.count), using: &rng) {
        \(raw: branches)
        }
      }
      """
  }

  /// The `@RandomFixtureValue(g)` attribute on a property and its argument expression,
  /// if any.
  private static func randomFixtureValue(
    of variable: VariableDeclSyntax
  ) -> (attribute: AttributeSyntax, expression: ExprSyntax)? {
    guard
      let attribute = variable.attributes
        .compactMap({ $0.as(AttributeSyntax.self) })
        .first(where: {
          $0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "RandomFixtureValue"
        }),
      let expression = attribute.arguments?.as(LabeledExprListSyntax.self)?.first?.expression
    else { return nil }
    return (attribute, expression)
  }
}
