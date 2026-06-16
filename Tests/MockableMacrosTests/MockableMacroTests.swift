#if os(macOS)
  import MacroTesting
  import MockableMacros
  import Testing

  @Suite(
    .macros(
      ["Mockable": MockableMacro.self],
      record: .missing
    )
  )
  struct MockableMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @Mockable struct User {
          let id: Int
          let name: String
        }
        """
      } expansion: {
        """
        struct User {
          let id: Int
          let name: String
        }

        extension User {
          static func mock() -> Self {
            fatalError("unimplemented")
          }
        }
        """
      }
    }
  }
#endif
