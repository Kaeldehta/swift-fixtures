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
/// ## Custom initializers
///
/// When a struct declares an initializer in its body, Swift suppresses the memberwise
/// initializer, so `@Fixture` instead mirrors that *targeted initializer*: the factory's
/// parameters match the initializer's (labels, names, types) and its body calls the
/// initializer. Each parameter defaults to `.fixture` unless the initializer already
/// supplies a default, which is kept.
///
/// ```swift
/// @Fixture
/// struct User {
///   let id: Int
///   let name: String
///   init(id: Int) {
///     self.id = id
///     self.name = "anonymous"
///   }
/// }
///
/// User.fixture(id: 1)  // calls init(id:); name stays "anonymous"
/// ```
///
/// When several initializers are declared, mark the one to target with ``FixtureInit()``.
/// To keep the memberwise factory while still offering a custom initializer, declare that
/// initializer in an *extension* rather than the body.
///
/// A ``FixtureValue(_:)-1y9c1`` on a stored property still applies, but only by
/// *passthrough correlation*: the initializer must store that parameter into the property
/// unchanged (`self.x = x`, exactly once, matching types). A `@FixtureValue` that correlates
/// to no parameter is diagnosed rather than silently dropped.
///
/// - Note: A failable, throwing, or async initializer cannot satisfy `static var fixture`
///   and is diagnosed as unsupported, as is a generic initializer (`init<S>(…)`).
///
/// ## Generic types
///
/// On a generic struct or enum the conformance is conditional. It places a `Fixture`
/// constraint on every generic parameter, or member type rooted in one (`Model.ID`), that
/// appears anywhere in the type of something defaulted to `.fixture`, including nested
/// types such as `[Item]` or `Other<Model.ID>`. Anything with an explicit default (a
/// ``FixtureValue(_:)-1y9c1``, or an initializer parameter's own default) adds no
/// constraint, so `@FixtureValue` is how you remove one. On an enum, only the chosen case's
/// associated values count.
///
/// ```swift
/// @Fixture
/// struct Page<Item, Meta> {
///   let items: [Item]
///   @FixtureValue(nil) let meta: Meta?
/// }
/// // extension Page: Fixture where Item: Fixture { … }
/// ```
///
/// - Note: Generic parameters of an *enclosing* type are treated as concrete types and
///   aren't constrained, so the expansion won't compile. The same goes for a generic
///   parameter reached only through a typealias. Write the conformance by hand instead
///   (`extension Outer.Inner: Fixture where T: Fixture { … }`).
@attached(extension, conformances: Fixture, names: named(fixture))
public macro Fixture() = #externalMacro(module: "FixturesMacros", type: "FixtureMacro")

/// Marks the enum case that `@Fixture` should use for `static var fixture`, overriding
/// the default of the first declared case.
@attached(peer)
public macro FixtureCase() = #externalMacro(module: "FixturesMacros", type: "FixtureCaseMacro")

/// Marks the initializer that `@Fixture` should target when a struct declares more than
/// one initializer in its body. Unnecessary when there is only a single initializer.
@attached(peer)
public macro FixtureInit() = #externalMacro(module: "FixturesMacros", type: "FixtureInitMacro")

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
/// For an optional property, write `@FixtureValue(nil)`; see ``FixtureValue(_:)-1qa6r``.
///
/// The expression is type-checked on its own, without the property's type, so leading-dot
/// shorthand isn't supported: write `@FixtureValue(Color.red)`, not `@FixtureValue(.red)`.
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
public macro FixtureValue<T>(_ value: T) =
  #externalMacro(module: "FixturesMacros", type: "FixtureValueMacro")

/// Defaults an optional stored property to `nil` in the generated factory.
///
/// ```swift
/// @Fixture struct User {
///   @FixtureValue(nil) let nickname: String?
/// }
/// // User.fixture().nickname == nil
/// ```
///
/// A bare `nil` has no type of its own, so it resolves to this overload; `@Fixture` copies
/// it into the factory, where the property's optional type is known.
@attached(peer)
public macro FixtureValue(_ value: Never?) =
  #externalMacro(module: "FixturesMacros", type: "FixtureValueMacro")
