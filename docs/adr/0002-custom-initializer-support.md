# `@Fixture` supports custom initializers via passthrough correlation, and excludes effectful inits

When a struct declares an initializer in its body, Swift suppresses the memberwise
initializer the fixture factory normally targets, so `@Fixture` must instead mirror that
custom initializer. We chose to drive the factory off the **targeted initializer's**
parameter list (the sole body init, or the one marked `@FixtureInit` when several exist),
and to keep `@FixtureValue` working by **passthrough correlation**: a property's
`@FixtureValue` applies to a factory parameter only when the init body assigns the
parameter to that property unchanged (`self.x = x`), exactly once, with matching types.

## Considered options

- **Name-matching correlation** (match init parameter name to stored-property name).
  Rejected: no single rule (label vs. internal name) covers renamed parameters, and the
  failure mode is a *silent* miss — a `@FixtureValue` quietly ignored. Body inspection is
  strictly more correct and is the principled test for whether reuse is even meaningful,
  since `@FixtureValue` is a default for the *stored property*, valid as a parameter
  default only under identity passthrough.
- **Initializer signature as the sole source** (ignore `@FixtureValue`; customize by
  giving the init parameter a default). Rejected: that default leaks to every caller of
  the init, defeating the test-only purpose `@FixtureValue` exists for.
- **A marker on the parameter** (`init(@FixtureValue("…") email: String)`). Not
  expressible: Swift attached macros apply to declarations, not function parameters. This
  is *why* the marker must live on the property and be correlated back.

## Why effectful inits are excluded

A failable, throwing, or async initializer cannot satisfy the `Fixture` protocol's
`static var fixture: Self` — the requirement that powers recursive composition — without
silently injecting `try!` / `!` / a concurrency hack. Rather than hide that trap, the
macro diagnoses such initializers as unsupported. Supporting them would require a
`throws`/`async` story for the `Fixture` protocol itself, which is out of scope.

## Consequences

- `@FixtureValue` is passthrough-only on the custom-init path: a transformed, computed, or
  multi-site assignment breaks correlation, and a `@FixtureValue` that correlates to
  nothing is diagnosed (an "orphan"), never silently dropped.
- A type that wants both a custom initializer *and* the memberwise-based factory can
  declare the initializer in an **extension**, leaving the body init-free.
