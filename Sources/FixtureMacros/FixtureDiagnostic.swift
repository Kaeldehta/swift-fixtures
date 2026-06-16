import SwiftDiagnostics

enum FixtureDiagnostic: String, DiagnosticMessage {
  case requiresStructOrEnum
  case enumRequiresCase

  var message: String {
    switch self {
    case .requiresStructOrEnum:
      return "'@Fixture' can only be attached to a struct or enum"
    case .enumRequiresCase:
      return "'@Fixture' requires an enum with at least one case"
    }
  }

  var diagnosticID: MessageID {
    MessageID(domain: "FixtureMacros", id: rawValue)
  }

  var severity: DiagnosticSeverity { .error }
}
