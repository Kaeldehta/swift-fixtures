#if canImport(Foundation)
  import Foundation

  // Foundation `Mockable` conformances. Values are deterministic (no randomness, no
  // "now") so mock data is stable across runs and snapshot tests.

  extension UUID: Mockable {
    public static var mock: UUID {
      UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
  }

  extension Date: Mockable {
    public static var mock: Date {
      Date(timeIntervalSinceReferenceDate: 0)
    }
  }

  extension URL: Mockable {
    public static var mock: URL {
      URL(string: "https://example.com")!
    }
  }

  extension Data: Mockable {
    public static var mock: Data { Data() }
  }

  extension Decimal: Mockable {
    public static var mock: Decimal { 0 }
  }
#endif
