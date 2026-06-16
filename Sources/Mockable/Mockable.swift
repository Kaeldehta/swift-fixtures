/// A type that can produce a default "mock" value of itself.
///
/// `@Mockable` synthesizes this conformance for structs, and the library ships
/// conformances for common standard-library and Foundation types. The default value
/// is used as the per-property default in the generated `mock(...)` factory, so mocks
/// compose recursively: a `@Mockable` struct whose properties are themselves `Mockable`
/// needs no extra wiring.
public protocol Mockable {
  /// A default value used when building mock data.
  static var mock: Self { get }
}

/// Generates a `static func mock(...)` factory with a default for every stored
/// property, so test data can be built by overriding only what's needed.
///
/// ```swift
/// @Mockable
/// struct User {
///   let id: Int
///   let name: String
/// }
///
/// let user = User.mock(name: "Blob")  // everything else defaulted
/// ```
///
/// The macro also synthesizes the type's own ``Mockable`` conformance
/// (`static var mock`), so nested `@Mockable` structs compose automatically.
///
/// - Note: This targets the struct's implicit memberwise initializer. A struct with a
///   custom `init` whose signature differs from its stored properties may not compile
///   against the generated factory.
@attached(extension, conformances: Mockable, names: named(mock))
public macro Mockable() = #externalMacro(module: "MockableMacros", type: "MockableMacro")
