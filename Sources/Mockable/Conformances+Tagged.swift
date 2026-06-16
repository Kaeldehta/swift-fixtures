// Compiled only when the `Tagged` package trait is enabled, so `swift-tagged` stays
// out of the dependency graph for consumers that don't opt in.
#if Tagged
  import Tagged

  extension Tagged: Mockable where RawValue: Mockable {
    public static var mock: Self { Self(rawValue: .mock) }
  }
#endif
