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
@attached(extension, names: named(mock))
public macro Mockable() = #externalMacro(module: "MockableMacros", type: "MockableMacro")
