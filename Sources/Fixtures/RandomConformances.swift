#if SwiftRandomKit
  import SwiftRandomKit

  // Varied-but-bounded defaults: full domain for integers, sane finite ranges where the
  // full domain is unhelpful (floating point), and short collections/strings so failure
  // output stays readable. Customize per property with @RandomFixtureValue.

  extension Int: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Int {
      IntGenerator(in: .min ... .max).run(using: &rng)
    }
  }
  extension Int8: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Int8 {
      IntGenerator(in: .min ... .max).run(using: &rng)
    }
  }
  extension Int16: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Int16 {
      IntGenerator(in: .min ... .max).run(using: &rng)
    }
  }
  extension Int32: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Int32 {
      IntGenerator(in: .min ... .max).run(using: &rng)
    }
  }
  extension Int64: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Int64 {
      IntGenerator(in: .min ... .max).run(using: &rng)
    }
  }
  extension UInt: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> UInt {
      IntGenerator(in: .min ... .max).run(using: &rng)
    }
  }
  extension UInt8: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> UInt8 {
      IntGenerator(in: .min ... .max).run(using: &rng)
    }
  }
  extension UInt16: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> UInt16 {
      IntGenerator(in: .min ... .max).run(using: &rng)
    }
  }
  extension UInt32: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> UInt32 {
      IntGenerator(in: .min ... .max).run(using: &rng)
    }
  }
  extension UInt64: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> UInt64 {
      IntGenerator(in: .min ... .max).run(using: &rng)
    }
  }

  extension Double: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Double {
      FloatGenerator<Double>(in: -1_000_000...1_000_000).run(using: &rng)
    }
  }
  extension Float: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Float {
      FloatGenerator<Float>(in: -1_000_000...1_000_000).run(using: &rng)
    }
  }

  extension Bool: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Bool {
      BoolGenerator().run(using: &rng)
    }
  }

  extension String: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> String {
      let count = IntGenerator(in: 0...16).run(using: &rng)
      return RandomGenerators.letterOrNumber.string(count: count).run(using: &rng)
    }
  }

  extension Character: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Character {
      RandomGenerators.letterOrNumber.run(using: &rng)
    }
  }

  extension Optional: RandomFixture where Wrapped: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Wrapped? {
      if BoolGenerator().run(using: &rng) {
        return Wrapped.randomFixture(using: &rng)
      }
      return nil
    }
  }

  extension Array: RandomFixture where Element: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> [Element] {
      let count = IntGenerator(in: 0...3).run(using: &rng)
      return (0..<count).map { _ in Element.randomFixture(using: &rng) }
    }
  }

  extension ContiguousArray: RandomFixture where Element: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(
      using rng: inout RNG
    ) -> ContiguousArray<Element> {
      ContiguousArray([Element].randomFixture(using: &rng))
    }
  }

  extension Set: RandomFixture where Element: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Set<Element> {
      Set([Element].randomFixture(using: &rng))
    }
  }

  extension Dictionary: RandomFixture where Key: RandomFixture, Value: RandomFixture {
    public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> [Key: Value] {
      let count = IntGenerator(in: 0...3).run(using: &rng)
      var dictionary: [Key: Value] = [:]
      for _ in 0..<count {
        dictionary[Key.randomFixture(using: &rng)] = Value.randomFixture(using: &rng)
      }
      return dictionary
    }
  }
#endif
