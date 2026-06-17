# Fixtures

[![CI](https://github.com/Kaeldehta/swift-fixtures/workflows/CI/badge.svg)](https://github.com/Kaeldehta/swift-fixtures/actions?query=workflow%3ACI)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FKaeldehta%2Fswift-fixtures%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Kaeldehta/swift-fixtures)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FKaeldehta%2Fswift-fixtures%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Kaeldehta/swift-fixtures)

A Swift macro that generates `fixture(...)` factories for your types, so tests can build
data by overriding only the fields they care about.

```swift
@Fixture
struct User {
  let id: Int
  let name: String
  let isAdmin: Bool
}

let user = User.fixture(name: "Alice")  // id and isAdmin defaulted
```

> [!WARNING]
> **This package is very early in development.** It is pre-1.0, the API may change without
> notice, and it has not yet been battle-tested in production. Pin a specific version and
> expect breaking changes.
>
> Development relies heavily on AI coding tools — both the implementation and much of the
> documentation are AI-assisted. Review generated code before depending on it.

## Why

Test data is mostly boilerplate: a `User` needs an `id`, a `name`, an `isAdmin`, a
`team`, a list of `tags` — but a given test only cares about one or two of them. Writing
out every field on every initializer call buries the one value that matters under a pile
of placeholders, and every new stored property breaks every call site.

`@Fixture` generates a `static func fixture(...)` whose every parameter is pre-defaulted,
so a test supplies only what it asserts on. Defaults compose recursively: a `@Fixture`
type whose properties are themselves fixtures needs no extra wiring.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/Kaeldehta/swift-fixtures", from: "0.1.0")
]
```

`@Fixture` is attached to your type declarations, so add `Fixtures` to whichever target
*declares* the types you want to annotate — usually your library or app target, not the
test target:

```swift
.target(
  name: "MyLibrary",
  dependencies: [
    .product(name: "Fixtures", package: "swift-fixtures"),
  ]
)
```

> [!NOTE]
> The macro expands on the type itself, so the generated `fixture(...)` factory and
> `Fixture` conformance become part of that type and ship with your target — for a
> `public` type, they become public API. If you'd rather keep fixtures out of your
> shipping code, annotate types that live in a target you don't ship (e.g. declare them in
> the test target).

## Usage

### Structs

`@Fixture` on a struct generates a `fixture(...)` factory with a default for every stored
property, plus the type's `Fixture` conformance (`static var fixture`).

```swift
@Fixture
struct Team {
  let id: Int
  let name: String
}

@Fixture
struct User {
  let id: Int
  let name: String
  let avatar: URL?
  let team: Team        // nested @Fixture composes automatically
  let tags: [String]
}

User.fixture()                            // every field defaulted
User.fixture(name: "Alice", tags: ["a"])  // override only what you need
```

Defaults come from the ``Fixture`` protocol: `Int` is `0`, `String` is `""`, `Bool` is
`false`, `Optional` is `nil`, collections are empty, and nested `@Fixture` types use their
own generated default.

### Custom defaults — `@FixtureValue`

Override the default the factory uses for a single property:

```swift
@Fixture
struct Profile {
  @FixtureValue("someone@example.com") let email: String
  @FixtureValue(18) let age: Int
  let name: String
}

Profile.fixture().email                       // "someone@example.com"
Profile.fixture(email: "other@example.com")   // still overridable at the call site
```

> [!NOTE]
> The expression is type-checked where the attribute is written, before `@Fixture`
> expands. A nested `@Fixture` type's generated factory isn't visible there if the type is
> declared in the **same module**, so `@FixtureValue(Address.fixture(city: "NYC"))` won't
> compile in that case. Use the memberwise initializer
> (`@FixtureValue(Address(street: Address.fixture.street, city: "NYC"))`) or override at
> the call site (`User.fixture(address: .fixture(city: "NYC"))`) instead. See
> [ADR 0001](docs/adr/0001-nested-fixture-value-customization.md).

### Custom initializers

If a struct declares an initializer in its body, Swift suppresses the memberwise
initializer, so `@Fixture` mirrors that initializer instead: the factory's parameters
match the initializer's (labels, names, types) and its body calls the initializer. Each
parameter defaults to `.fixture` unless the initializer already supplies a default, which
is kept.

```swift
@Fixture
struct User {
  let id: Int
  let name: String

  init(id: Int) {
    self.id = id
    self.name = "anonymous"
  }
}

User.fixture(id: 1)  // calls init(id:); name stays "anonymous"
```

When a struct declares **more than one** initializer, mark the one to target with
`@FixtureInit`:

```swift
@Fixture
struct User {
  let id: Int

  @FixtureInit
  init(id: Int) { self.id = id }

  init(uuid: UUID) { self.id = uuid.hashValue }
}
```

`@FixtureValue` still works on this path, but only by **passthrough correlation**: it
applies to a parameter only when the initializer stores that parameter into the property
unchanged (`self.x = x`, exactly once, with matching types). A `@FixtureValue` that's
transformed, computed, assigned in multiple places, type-mismatched, or otherwise
correlates to no parameter is diagnosed rather than silently dropped.

> [!NOTE]
> To keep the memberwise factory while still offering a custom initializer, declare that
> initializer in an **extension** rather than the body — the body stays init-free, so the
> memberwise path applies. A failable, throwing, or async initializer cannot satisfy
> `static var fixture` and is diagnosed as unsupported. See
> [ADR 0002](docs/adr/0002-custom-initializer-support.md).

### Enums

`@Fixture` on an enum makes `static var fixture` return the first case, with any
associated values defaulted to `.fixture`:

```swift
@Fixture
enum Status {
  case active(code: Int, label: String)
  case banned
}

Status.fixture  // .active(code: 0, label: "")
```

Mark a different case with `@FixtureCase` to override the first-case default:

```swift
@Fixture
enum Connection {
  case connected(host: String)
  @FixtureCase case disconnected
}

Connection.fixture  // .disconnected
```

## Built-in conformances

The library ships `Fixture` conformances for common types, chosen to be **predictable
rather than realistic** so fixtures stay stable across runs:

- **Standard library** — integer and floating-point types (`0`), `Bool` (`false`),
  `String` (`""`), `Character` (`" "`), `Optional` (`nil`), and `Array`,
  `ContiguousArray`, `Set`, `Dictionary` (empty).
- **Foundation** — `UUID` (all-zero), `Date` (reference date), `URL`
  (`https://example.com`), `Data` (empty), `Decimal` (`0`).

## Package traits

Conformances for third-party types are gated behind opt-in
[package traits](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0450-swiftpm-package-traits.md),
so their dependencies are only resolved when you enable them:

| Trait                   | Adds a `Fixture` conformance for | Dependency |
| ----------------------- | -------------------------------- | ---------- |
| `Tagged`                | `Tagged`                         | [swift-tagged](https://github.com/pointfreeco/swift-tagged) |
| `IdentifiedCollections` | `IdentifiedArray`                | [swift-identified-collections](https://github.com/pointfreeco/swift-identified-collections) |

Enable them when adding the dependency:

```swift
.package(
  url: "https://github.com/Kaeldehta/swift-fixtures",
  from: "0.1.0",
  traits: ["Tagged", "IdentifiedCollections"]
)
```

## Conforming your own types

Anything you want as a fixture default just needs to conform to `Fixture`:

```swift
extension Color: Fixture {
  public static var fixture: Color { .black }
}
```

`@Fixture`-annotated types get this conformance for free.

## Requirements

- Swift 6.1+
- macOS 10.15+, iOS 13+, tvOS 13+, watchOS 6+

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
