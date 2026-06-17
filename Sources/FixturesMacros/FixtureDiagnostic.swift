import SwiftDiagnostics

enum FixtureDiagnostic: String, DiagnosticMessage {
  case requiresStructOrEnum
  case enumRequiresCase
  case multipleInitsRequireMarker
  case multipleFixtureInitMarkers
  case effectfulInitializer
  case orphanFixtureValue

  var message: String {
    switch self {
    case .requiresStructOrEnum:
      return "'@Fixture' can only be attached to a struct or enum"
    case .enumRequiresCase:
      return "'@Fixture' requires an enum with at least one case"
    case .multipleInitsRequireMarker:
      return
        "'@Fixture' needs '@FixtureInit' on one initializer when the type declares more than one"
    case .multipleFixtureInitMarkers:
      return "'@Fixture' allows only one '@FixtureInit' initializer"
    case .effectfulInitializer:
      return "'@Fixture' cannot target a failable, throwing, or async initializer"
    case .orphanFixtureValue:
      return
        "'@FixtureValue' does not correspond to any initializer parameter (the property is not stored unchanged from a parameter)"
    }
  }

  var diagnosticID: MessageID {
    MessageID(domain: "FixtureMacros", id: rawValue)
  }

  var severity: DiagnosticSeverity { .error }
}
