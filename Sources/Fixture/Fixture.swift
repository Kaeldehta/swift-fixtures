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
/// let user = User.fixture(name: "Alice")  // everything else defaulted
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

/// Overrides the default value `@Fixture` uses for a stored property, replacing the
/// type's `.fixture` with the given expression in the generated factory.
///
/// ```swift
/// @Fixture struct User {
///   @FixtureValue("someone@example.com") let email: String
/// }
/// // User.fixture().email == "someone@example.com"
/// ```
///
/// ## Customizing a nested `@Fixture` value
///
/// The expression is type-checked where the attribute is written, *before* `@Fixture`
/// expands. A macro cannot see members synthesized by another macro at that point, so a
/// nested type's generated `fixture(...)` factory is **not** visible if that type is
/// declared in the *same module*:
///
/// ```swift
/// @Fixture struct Address { let street: String; let city: String }
/// @Fixture struct User {
///   @FixtureValue(Address.fixture(city: "NYC")) let address: Address  // ❌ same module
/// }
/// ```
///
/// This compiles fine when `Address` comes from a *different* module (its factory is
/// already a visible member by then). For a same-module nested type, customize a baked
/// default through the memberwise initializer instead — which the compiler synthesizes,
/// so it *is* visible — pulling the fields you don't change from `.fixture`:
///
/// ```swift
/// @FixtureValue(Address(street: Address.fixture.street, city: "NYC")) let address: Address
/// ```
///
/// Or skip the baked default and override at the call site, where the factory is fully
/// visible: `User.fixture(address: .fixture(city: "NYC"))`. See
/// `docs/adr/0001-nested-fixture-value-customization.md`.
@attached(peer)
public macro FixtureValue(_ value: Any) =
  #externalMacro(module: "FixtureMacros", type: "FixtureValueMacro")
