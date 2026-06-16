# ``Fixture``

Generate `fixture(...)` factories for your types, so tests build data by overriding only
the fields they care about.

## Overview

Test data is mostly boilerplate: a `User` needs an `id`, a `name`, an `isAdmin`, a
`team`, a list of `tags` — but a given test only cares about one or two of them. The
``Fixture()`` macro generates a `static func fixture(...)` whose every parameter is
pre-defaulted, so a test supplies only what it asserts on, and every new stored property
defaults itself instead of breaking existing call sites.

```swift
@Fixture
struct User {
  let id: Int
  let name: String
  let isAdmin: Bool
}

let user = User.fixture(name: "Alice")  // id and isAdmin defaulted
```

Defaults come from the ``Fixture`` protocol and compose recursively: a `@Fixture` type
whose properties are themselves `Fixture` needs no extra wiring. The library ships
conformances for common standard-library and Foundation types, chosen to be predictable
rather than realistic so fixtures stay stable across runs.

## Topics

### Generating fixtures

- ``Fixture()``
- ``Fixture``

### Customizing generated fixtures

- ``FixtureValue(_:)``
- ``FixtureCase()``
