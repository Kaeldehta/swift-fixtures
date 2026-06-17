#if canImport(Foundation)
  import Foundation

  // Deterministic values (no randomness, no "now") so fixtures stay stable across runs.

  extension UUID: Fixture {
    public static var fixture: UUID {
      UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
  }

  extension Date: Fixture {
    public static var fixture: Date {
      Date(timeIntervalSinceReferenceDate: 0)
    }
  }

  extension URL: Fixture {
    public static var fixture: URL {
      URL(string: "https://example.com")!
    }
  }

  extension Data: Fixture {
    public static var fixture: Data { Data() }
  }

  extension Decimal: Fixture {
    public static var fixture: Decimal { 0 }
  }
#endif
