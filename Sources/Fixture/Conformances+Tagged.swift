#if Tagged
  import Tagged

  extension Tagged: Fixture where RawValue: Fixture {
    public static var fixture: Self { Self(rawValue: .fixture) }
  }
#endif
