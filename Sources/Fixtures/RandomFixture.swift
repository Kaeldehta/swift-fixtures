#if SwiftRandomKit
  import SwiftRandomKit

  /// A type that can produce a randomized fixture value.
  ///
  /// The randomized counterpart of ``Fixture``: where `Fixture` supplies one predictable
  /// default, `RandomFixture` draws a varied value from a `RandomNumberGenerator`, so
  /// repeated fixtures differ from each other while remaining reproducible under a
  /// seeded RNG.
  ///
  /// ```swift
  /// var rng = Xoshiro256(seed: 42)
  /// let user = User.randomFixture(using: &rng)   // same seed, same user
  /// ```
  public protocol RandomFixture {
    /// Draws a randomized fixture value from the given random number generator.
    static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Self
  }

  extension RandomFixture {
    /// A SwiftRandomKit generator of randomized fixtures, composable with every
    /// SwiftRandomKit combinator.
    ///
    /// ```swift
    /// var rng = Xoshiro256(seed: 42)
    /// let users = User.randomFixtureGenerator.array(50).run(using: &rng)
    /// let maybe = User.randomFixtureGenerator.orNil(probability: 0.3).run(using: &rng)
    /// ```
    public static var randomFixtureGenerator: AnyRandomGenerator<Self> {
      AnyRandomGenerator { rng in
        Self.randomFixture(using: &rng)
      }
    }
  }

  /// Generates a `RandomFixture` conformance that draws every stored property from its
  /// own `RandomFixture`, so randomized test data composes recursively the same way
  /// ``Fixture()`` defaults do.
  ///
  /// ```swift
  /// @RandomFixture
  /// struct User {
  ///   let id: Int
  ///   let name: String
  /// }
  ///
  /// var rng = Xoshiro256(seed: 42)
  /// let user = User.randomFixture(using: &rng)     // varied but reproducible
  /// let many = User.randomFixtureGenerator.array(10).run(using: &rng)
  /// ```
  ///
  /// On an enum, a case is picked **uniformly at random** (unlike ``Fixture()``, which
  /// always uses the first case), with associated values drawn from their own
  /// `RandomFixture`.
  ///
  /// Customize a property's distribution with ``RandomFixtureValue(_:)``, passing any
  /// SwiftRandomKit generator:
  ///
  /// ```swift
  /// @RandomFixture
  /// struct Player {
  ///   @RandomFixtureValue(IntGenerator(in: 1...99)) let level: Int
  ///   let name: String
  /// }
  /// ```
  ///
  /// - Note: Only the memberwise path is supported: a struct that declares an
  ///   initializer in its body is diagnosed. Declare custom initializers in an
  ///   extension to keep the memberwise path, matching the ``Fixture()`` guidance.
  @attached(extension, conformances: RandomFixture, names: named(randomFixture))
  public macro RandomFixture() =
    #externalMacro(module: "FixturesMacros", type: "RandomFixtureMacro")

  /// Overrides the generator `@RandomFixture` uses for a stored property, replacing the
  /// type's `.randomFixture` draw with a draw from the given SwiftRandomKit generator.
  ///
  /// ```swift
  /// @RandomFixture
  /// struct Player {
  ///   @RandomFixtureValue(IntGenerator(in: 1...99)) let level: Int
  /// }
  /// ```
  ///
  /// The expression is type-checked where the attribute is written and must be a
  /// `RandomGenerator` whose `Element` matches the property's type.
  @attached(peer)
  public macro RandomFixtureValue(_ generator: Any) =
    #externalMacro(module: "FixturesMacros", type: "RandomFixtureValueMacro")
#endif
