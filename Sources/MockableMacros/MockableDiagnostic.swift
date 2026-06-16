import SwiftDiagnostics

enum MockableDiagnostic: String, DiagnosticMessage {
  case requiresStruct

  var message: String {
    switch self {
    case .requiresStruct:
      return "'@Mockable' can only be attached to a struct"
    }
  }

  var diagnosticID: MessageID {
    MessageID(domain: "MockableMacros", id: rawValue)
  }

  var severity: DiagnosticSeverity { .error }
}
