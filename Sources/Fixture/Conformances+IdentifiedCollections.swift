#if IdentifiedCollections
  import IdentifiedCollections

  extension IdentifiedArray: Fixture where Element: Identifiable, ID == Element.ID {
    public static var fixture: Self { [] }
  }
#endif
