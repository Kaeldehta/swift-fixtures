#if os(macOS)
  import MacroTesting
  import MockableMacros
  import Testing

  @Suite(
    .macros(
      [MockableMacro.self],
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
          static func mock(id: Int = .mock,
            name: String = .mock) -> Self {
            Self(id: id, name: name)
          }
          static var mock: Self {
            mock()
          }
        }
        """
      }
    }

    @Test func optionalsAndCollections() {
      assertMacro {
        """
        @Mockable struct User {
          let avatar: URL?
          let tags: [String]
          let scores: [String: Int]
        }
        """
      } expansion: {
        """
        struct User {
          let avatar: URL?
          let tags: [String]
          let scores: [String: Int]
        }

        extension User {
          static func mock(avatar: URL? = .mock,
            tags: [String] = .mock,
            scores: [String: Int] = .mock) -> Self {
            Self(avatar: avatar, tags: tags, scores: scores)
          }
          static var mock: Self {
            mock()
          }
        }
        """
      }
    }

    @Test func publicAccessIsMirrored() {
      assertMacro {
        """
        @Mockable public struct User {
          public let id: Int
        }
        """
      } expansion: {
        """
        public struct User {
          public let id: Int
        }

        extension User {
          public static func mock(id: Int = .mock) -> Self {
            Self(id: id)
          }
          public static var mock: Self {
            mock()
          }
        }
        """
      }
    }

    @Test func computedStaticAndInitializedPropertiesAreOmitted() {
      assertMacro {
        """
        @Mockable struct User {
          let id: Int
          var count = 0
          static let shared = "x"
          var displayName: String { "\\(id)" }
        }
        """
      } expansion: {
        #"""
        struct User {
          let id: Int
          var count = 0
          static let shared = "x"
          var displayName: String { "\(id)" }
        }

        extension User {
          static func mock(id: Int = .mock) -> Self {
            Self(id: id)
          }
          static var mock: Self {
            mock()
          }
        }
        """#
      }
    }

    @Test func emptyStruct() {
      assertMacro {
        """
        @Mockable struct Empty {
        }
        """
      } expansion: {
        """
        struct Empty {
        }

        extension Empty {
            static func mock() -> Self {
                Self()
            }
            static var mock: Self {
                mock()
            }
        }
        """
      }
    }

    @Test func attachedToNonStructDiagnoses() {
      assertMacro {
        """
        @Mockable enum Direction {
          case north
        }
        """
      } diagnostics: {
        """
        @Mockable enum Direction {
        ┬────────
        ╰─ 🛑 '@Mockable' can only be attached to a struct
          case north
        }
        """
      }
    }
  }
#endif
