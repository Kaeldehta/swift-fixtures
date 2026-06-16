import SwiftDiagnostics

enum FixtureDiagnostic: String, DiagnosticMessage {
  case requiresStruct

  var message: String {
    switch self {
    case .requiresStruct:
      return "'@Fixture' can only be attached to a struct"
    }
  }

  var diagnosticID: MessageID {
    MessageID(domain: "FixtureMacros", id: rawValue)
  }

  var severity: DiagnosticSeverity { .error }
}
