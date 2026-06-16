// Compiled only when the `Tagged` package trait is enabled, so `swift-tagged` stays
// out of the dependency graph for consumers that don't opt in.
#if Tagged
  import Tagged

  extension Tagged: Fixture where RawValue: Fixture {
    public static var fixture: Self { Self(rawValue: .fixture) }
  }
#endif
