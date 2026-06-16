// Compiled only when the `IdentifiedCollections` package trait is enabled, so
// swift-identified-collections stays out of the dependency graph for consumers that
// don't opt in.
#if IdentifiedCollections
  import IdentifiedCollections

  extension IdentifiedArray: Fixture where Element: Identifiable, ID == Element.ID {
    public static var fixture: Self { [] }
  }
#endif
