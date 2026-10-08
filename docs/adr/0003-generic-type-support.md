# `@Fixture` on generic types constrains every generic-rooted type a fixture default touches

A macro sees only syntax, so it cannot tell whether a generic parameter actually needs to
be `Fixture` for a `.fixture` default to type-check: `[T]` and `T?` do not need it, a bare
`T` does, and `Other<T>` does only if `Other` is itself conditionally `Fixture`. We chose
to **over-constrain rather than under-constrain**: the conformance is emitted in an
extension carrying a **fixture constraint** (`: Fixture`) on every type path rooted at a
generic parameter (`T`, `Model.ID`, …) that appears anywhere in the type of a parameter
defaulted to `.fixture`. The guarantee is that the expansion never fails to compile for
lack of a constraint; the escape hatch is `@FixtureValue`, whose explicit default imposes
no constraint.

## Considered options

- **Constrain every generic parameter.** Simplest, but constrains parameters no fixture
  default touches, with no way to lift them.
- **Constrain only bare uses, with an allow-list of unconditionally-`Fixture` containers
  (`Optional`, `Array`, …).** Most precise, but under-constrains `Other<T>`, reproducing
  the opaque expansion error this work exists to remove, and couples the macro to the
  library's conformance list.
- **Constrain only the generic parameter, not member paths.** `Model: Fixture` says
  nothing about `Model.ID`, so `id: Model.ID = .fixture` would still fail.

## Consequences

- The same rule applies on the memberwise path, the custom-init path (a parameter with its
  own default or a correlated `@FixtureValue` imposes nothing), and to enums — where only
  the case `static var fixture` uses contributes constraints.
- An initializer with its **own** generic parameters is diagnosed: its parameters cannot
  be defaulted or constrained from the type's conformance.
- Generic parameters of an **enclosing** type are not recognized and are treated as
  concrete. `lexicalContext` would see `Outer<T>` but not `extension Outer { … }`, and a
  rule that works for only one spelling was judged worse than a documented limitation.
  Likewise, a generic parameter reached only through a typealias (`typealias E = T`) is
  invisible to the macro; the "never fails" guarantee holds only for spelled-out paths.
- Loosening the rule later (e.g. exempting known containers) is non-breaking; tightening
  it is not.
