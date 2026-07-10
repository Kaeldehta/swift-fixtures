#if SwiftRandomKit && canImport(Foundation)
  import Foundation
  import SwiftRandomKit

  extension UUID: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> UUID {
      var bytes = [UInt8](repeating: 0, count: 16)
      for index in bytes.indices {
        bytes[index] = IntGenerator(in: UInt8.min ... UInt8.max).run(using: &rng)
      }
      // RFC 4122 version 4 / variant bits
      bytes[6] = (bytes[6] & 0x0F) | 0x40
      bytes[8] = (bytes[8] & 0x3F) | 0x80
      return UUID(
        uuid: (
          bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
          bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
  }

  extension Date: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Date {
      // Within ±100 years of the reference date.
      let seconds = FloatGenerator<Double>(in: -3_155_760_000...3_155_760_000).run(using: &rng)
      return Date(timeIntervalSinceReferenceDate: seconds)
    }
  }

  extension URL: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> URL {
      let path = RandomGenerators.lowercaseLetter.string(count: 8).run(using: &rng)
      return URL(string: "https://example.com/\(path)")!
    }
  }

  extension Data: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Data {
      let count = IntGenerator(in: 0...16).run(using: &rng)
      var bytes = [UInt8](repeating: 0, count: count)
      for index in bytes.indices {
        bytes[index] = IntGenerator(in: UInt8.min ... UInt8.max).run(using: &rng)
      }
      return Data(bytes)
    }
  }

  extension Decimal: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Decimal {
      Decimal(FloatGenerator<Double>(in: -1_000_000...1_000_000).run(using: &rng))
    }
  }
#endif
