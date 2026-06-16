/// A type that can produce a default "fixture" value of itself.
///
/// `@Fixture` synthesizes this conformance for structs, and the library ships
/// conformances for common standard-library and Foundation types. The default value
/// is used as the per-property default in the generated `fixture(...)` factory, so
/// fixtures compose recursively: a `@Fixture` struct whose properties are themselves
/// `Fixture` needs no extra wiring.
public protocol Fixture {
  /// A default value used when building fixture data.
  static var fixture: Self { get }
}

/// Generates a `static func fixture(...)` factory with a default for every stored
/// property, so test data can be built by overriding only what's needed.
///
/// ```swift
/// @Fixture
/// struct User {
///   let id: Int
///   let name: String
/// }
///
/// let user = User.fixture(name: "Blob")  // everything else defaulted
/// ```
///
/// The macro also synthesizes the type's own ``Fixture`` conformance
/// (`static var fixture`), so nested `@Fixture` structs compose automatically.
///
/// On an enum, `static var fixture` returns the first case (associated values defaulted
/// to `.fixture`), or the case marked with ``FixtureCase()`` if one is present.
///
/// - Note: This targets the struct's implicit memberwise initializer. A struct with a
///   custom `init` whose signature differs from its stored properties may not compile
///   against the generated factory.
@attached(extension, conformances: Fixture, names: named(fixture))
public macro Fixture() = #externalMacro(module: "FixtureMacros", type: "FixtureMacro")

/// Marks the enum case that `@Fixture` should use for `static var fixture`, overriding
/// the default of the first declared case.
@attached(peer)
public macro FixtureCase() = #externalMacro(module: "FixtureMacros", type: "FixtureCaseMacro")
