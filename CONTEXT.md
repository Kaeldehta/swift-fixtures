# Fixtures

A Swift macro package that generates defaulted constructors for test data. `@Fixture`
inspects a type and synthesizes a way to build a value while overriding only the fields a
test cares about. This glossary fixes the vocabulary the macro and its docs use.

## Language

**Fixture factory**:
The generated `static func fixture(...)` whose every parameter is pre-defaulted, so a
caller supplies only what it asserts on.
_Avoid_: builder, factory method, maker

**Fixture default**:
The canonical default value of a type, exposed as `static var fixture` via the `Fixture`
protocol. This is what fills a factory parameter the caller omits, and what makes nested
`@Fixture` types compose.
_Avoid_: zero value, placeholder, sample

**Memberwise path**:
The mode `@Fixture` uses when the type declares no initializer in its body — the factory
is derived from the stored properties and targets the synthesized memberwise initializer.
_Avoid_: default path, property path

**Custom-init path**:
The mode `@Fixture` uses when the type declares an initializer in its body — the factory
mirrors that initializer's parameters instead of the stored properties.
_Avoid_: explicit-init mode

**Targeted initializer**:
The single initializer the fixture factory mirrors and calls on the custom-init path —
the sole body initializer, or the one marked `@FixtureInit` when several exist.
_Avoid_: chosen init, selected init

**Passthrough correlation**:
The inferred link from a targeted-initializer parameter to a stored property, established
only when the initializer body assigns the parameter to that property unchanged
(`self.x = x`) and their types match. It is what lets a property's `@FixtureValue` apply
to the matching factory parameter.
_Avoid_: mapping, binding, name match

**Orphan `@FixtureValue`**:
A `@FixtureValue` on a stored property that correlates to no targeted-initializer
parameter, so its expression would silently go unused. The macro diagnoses it rather than
dropping it.
_Avoid_: dangling, unused attribute
