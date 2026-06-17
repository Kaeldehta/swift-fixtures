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
      guard
        let structMembers = structMembers(
          of: structDecl, access: access, node: node, in: context)
      else { return [] }
      members = structMembers
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

  /// The `fixture(...)` factory and `static var fixture` for a struct.
  ///
  /// When the struct declares no initializer in its body, the factory is derived from the
  /// stored properties and targets the synthesized memberwise initializer
  /// (``memberwiseMembers(of:access:)``). When it declares one, the factory mirrors that
  /// *targeted initializer* instead (``customInitMembers(of:targeting:access:node:in:)``).
  ///
  /// Returns `nil` when a diagnostic was emitted, signalling the caller to produce no
  /// extension.
  private static func structMembers(
    of structDecl: StructDeclSyntax,
    access: String,
    node: AttributeSyntax,
    in context: some MacroExpansionContext
  ) -> [DeclSyntax]? {
    let initializers = structDecl.memberBlock.members.compactMap {
      $0.decl.as(InitializerDeclSyntax.self)
    }

    // Path selection: no body initializer keeps the memberwise path; one targets it;
    // several require exactly one marked with `@FixtureInit`.
    let targetInit: InitializerDeclSyntax
    switch initializers.count {
    case 0:
      return memberwiseMembers(of: structDecl, access: access)
    case 1:
      targetInit = initializers[0]
    default:
      let marked = initializers.filter { isFixtureInit($0) }
      switch marked.count {
      case 0:
        context.diagnose(
          Diagnostic(node: node, message: FixtureDiagnostic.multipleInitsRequireMarker))
        return nil
      case 1:
        targetInit = marked[0]
      default:
        context.diagnose(
          Diagnostic(node: marked[1], message: FixtureDiagnostic.multipleFixtureInitMarkers))
        return nil
      }
    }

    return customInitMembers(
      of: structDecl, targeting: targetInit, access: access, node: node, in: context)
  }

  /// A `fixture(...)` factory whose parameters are the struct's memberwise-init
  /// parameters (each defaulted to `.fixture`), plus the protocol's `static var fixture`.
  private static func memberwiseMembers(
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
      let customDefault = fixtureValue(of: variable).map { "\($0.expression.trimmed)" }
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

    let parameters =
      properties
      .map { "\($0.name): \($0.type) = \($0.defaultValue)" }
      .joined(separator: ",\n")
    let arguments =
      properties
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

  /// A `fixture(...)` factory mirroring the *targeted initializer's* parameter list
  /// verbatim and calling it, plus the protocol's `static var fixture`.
  ///
  /// Each parameter defaults to `.fixture` unless the initializer already supplies a
  /// default (kept) or a stored property's `@FixtureValue` correlates to it by passthrough
  /// (`self.x = x`, matching types), which takes precedence. Returns `nil` when a
  /// diagnostic was emitted.
  private static func customInitMembers(
    of structDecl: StructDeclSyntax,
    targeting targetInit: InitializerDeclSyntax,
    access: String,
    node: AttributeSyntax,
    in context: some MacroExpansionContext
  ) -> [DeclSyntax]? {
    // A failable / throwing / async initializer cannot satisfy `static var fixture: Self`.
    let effectSpecifiers = targetInit.signature.effectSpecifiers
    if targetInit.optionalMark != nil
      || effectSpecifiers?.throwsClause != nil
      || effectSpecifiers?.asyncSpecifier != nil
    {
      context.diagnose(
        Diagnostic(node: targetInit, message: FixtureDiagnostic.effectfulInitializer))
      return nil
    }

    let parameters = Array(targetInit.signature.parameterClause.parameters)
    let statements = targetInit.body?.statements ?? []

    // Passthrough correlation: a property's `@FixtureValue` applies to the parameter that
    // the initializer stores into it unchanged. A `@FixtureValue` that correlates to no
    // parameter is an "orphan" and is diagnosed rather than silently dropped.
    var defaultsByInternalName: [String: String] = [:]
    let storedVariables = structDecl.memberBlock.members.compactMap {
      $0.decl.as(VariableDeclSyntax.self)
    }
    for variable in storedVariables {
      guard let fixtureValue = fixtureValue(of: variable) else { continue }
      guard
        let parameter = correlatedParameter(
          for: variable, among: parameters, in: statements)
      else {
        context.diagnose(
          Diagnostic(node: fixtureValue.attribute, message: FixtureDiagnostic.orphanFixtureValue))
        return nil
      }
      defaultsByInternalName[internalName(of: parameter).text] = "\(fixtureValue.expression.trimmed)"
    }

    let parameterClause = parameters.map { parameter -> String in
      let internalName = internalName(of: parameter)
      // Precedence: correlated `@FixtureValue` > the initializer's own default > `.fixture`.
      let defaultValue =
        defaultsByInternalName[internalName.text]
        ?? parameter.defaultValue.map { "\($0.value.trimmed)" }
        ?? ".fixture"
      let names =
        parameter.secondName.map { "\(parameter.firstName.trimmed) \($0.trimmed)" }
        ?? "\(parameter.firstName.trimmed)"
      return "\(names): \(parameter.type.trimmed) = \(defaultValue)"
    }.joined(separator: ",\n")

    let arguments = parameters.map { parameter -> String in
      let value = internalName(of: parameter).text
      if parameter.firstName.tokenKind == .wildcard {
        return value
      }
      return "\(parameter.firstName.text): \(value)"
    }.joined(separator: ", ")

    return [
      """
      \(raw: access)static func fixture(\(raw: parameterClause)) -> Self {
      Self(\(raw: arguments))
      }
      """,
      "\(raw: access)static var fixture: Self { fixture() }",
    ]
  }

  /// The initializer parameter that `variable`'s `@FixtureValue` correlates to by
  /// passthrough, or `nil` when correlation fails (transformed, computed, multi-site, or
  /// type-mismatched assignment, or no parameter stored into the property).
  private static func correlatedParameter(
    for variable: VariableDeclSyntax,
    among parameters: [FunctionParameterSyntax],
    in statements: CodeBlockItemListSyntax
  ) -> FunctionParameterSyntax? {
    guard
      let binding = variable.bindings.first,
      let property = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
      let propertyType = binding.typeAnnotation?.type
    else { return nil }

    // Every top-level assignment into `self.<property>`, with its right-hand side (which
    // is `nil` when the assignment is a transformed expression rather than a single value).
    let assignedValues = statements.compactMap { statement -> ExprSyntax?? in
      guard let assignment = selfAssignment(in: statement), assignment.property == property
      else { return nil }
      return .some(assignment.value)
    }

    // Correlation requires a single, unchanged passthrough of a parameter.
    guard assignedValues.count == 1,
      let value = assignedValues[0],
      let reference = value.as(DeclReferenceExprSyntax.self)
    else { return nil }

    return parameters.first {
      internalName(of: $0).text == reference.baseName.text
        && $0.type.trimmedDescription == propertyType.trimmedDescription
    }
  }

  /// A top-level `self.<property> = <value>` assignment in an initializer body, as
  /// `(property, value)`. `value` is `nil` when the right-hand side is a compound
  /// expression rather than a single operand (a transformed assignment).
  ///
  /// The compiler hands macros *unfolded* operator sequences (`SequenceExprSyntax`), while
  /// some hosts (e.g. the macro-testing harness) fold them into `InfixOperatorExprSyntax`;
  /// both shapes are recognized.
  private static func selfAssignment(
    in statement: CodeBlockItemSyntax
  ) -> (property: String, value: ExprSyntax?)? {
    guard let expression = statement.item.as(ExprSyntax.self) else { return nil }

    let target: ExprSyntax
    let value: ExprSyntax?
    if let infix = expression.as(InfixOperatorExprSyntax.self),
      infix.operator.is(AssignmentExprSyntax.self)
    {
      target = infix.leftOperand
      value = infix.rightOperand
    } else if let sequence = expression.as(SequenceExprSyntax.self) {
      let elements = Array(sequence.elements)
      // `self.x = y` folds to exactly [target, `=`, value]; anything longer is transformed.
      guard elements.count >= 3, elements[1].is(AssignmentExprSyntax.self) else { return nil }
      target = elements[0]
      value = elements.count == 3 ? elements[2] : nil
    } else {
      return nil
    }

    guard let member = target.as(MemberAccessExprSyntax.self),
      member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "self"
    else { return nil }
    return (member.declName.baseName.text, value)
  }

  /// The name used to refer to a parameter inside the initializer body: its internal
  /// (second) name when present, otherwise its label.
  private static func internalName(of parameter: FunctionParameterSyntax) -> TokenSyntax {
    (parameter.secondName ?? parameter.firstName).trimmed
  }

  /// Whether an initializer is marked with `@FixtureInit`.
  private static func isFixtureInit(_ initializer: InitializerDeclSyntax) -> Bool {
    initializer.attributes.contains { attribute in
      attribute.as(AttributeSyntax.self)?
        .attributeName.as(IdentifierTypeSyntax.self)?.name.text == "FixtureInit"
    }
  }

  /// The `@FixtureValue(x)` attribute on a property and its argument expression, if any.
  private static func fixtureValue(
    of variable: VariableDeclSyntax
  ) -> (attribute: AttributeSyntax, expression: ExprSyntax)? {
    guard
      let attribute = variable.attributes
        .compactMap({ $0.as(AttributeSyntax.self) })
        .first(where: {
          $0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "FixtureValue"
        }),
      let expression = attribute.arguments?.as(LabeledExprListSyntax.self)?.first?.expression
    else { return nil }
    return (attribute, expression)
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
