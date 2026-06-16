# Nested `@FixtureValue` customization is left to the call site, not the attribute

`@FixtureValue(Nested.fixture(city: "NYC"))` does not compile when `Nested` is a `@Fixture`
type in the *same module*: the attribute argument is type-checked before `@Fixture`
expands, and a macro cannot see the members another macro synthesizes at that point, so
`Nested`'s generated `fixture(...)` factory is invisible there. We accept this limitation
and document the workarounds rather than adding API to work around it. `Fixture`'s
requirement stays named `fixture`.

## Considered options

- **Rename the requirement `fixture` → `defaultFixture`** so the factory name is unshadowed.
  Verified it does not help — the factory is still macro-generated and invisible, the error
  just changes to "no member 'fixture'".
- **Emit the factory via `@attached(member)` instead of only the extension.** Verified it
  does not help — members synthesized by one macro are still invisible to another macro's
  argument type-checking within a compilation.
- **`@autoclosure` parameter** to defer the type-check. Verified it does not defer.
- **A string escape hatch `@FixtureValue(raw: "...")`** injected verbatim. Works, but is
  stringly-typed for a gain the typed workarounds already cover, so not added.

## Why this is fine

The limitation is same-compilation-only and the practical gap is small:

- It already works when `Nested` lives in a **different module** (its factory is a visible
  member by the time this module is type-checked).
- Same module, fully typed: `@FixtureValue(Nested(field: Nested.fixture.field, custom: x))`
  uses the compiler-synthesized memberwise initializer, which *is* visible.
- Same module, using the factory's defaulting: override at the call site —
  `Parent.fixture(child: .fixture(field: x))`.
