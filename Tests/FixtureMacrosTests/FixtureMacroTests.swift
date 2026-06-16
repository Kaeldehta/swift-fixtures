#if os(macOS)
  import MacroTesting
  import FixtureMacros
  import Testing

  @Suite(
    .macros(
      [FixtureMacro.self, FixtureCaseMacro.self],
      record: .missing
    )
  )
  struct FixtureMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @Fixture struct User {
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
          static func fixture(id: Int = .fixture,
            name: String = .fixture) -> Self {
            Self(id: id, name: name)
          }
          static var fixture: Self {
            fixture()
          }
        }
        """
      }
    }

    @Test func optionalsAndCollections() {
      assertMacro {
        """
        @Fixture struct User {
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
          static func fixture(avatar: URL? = .fixture,
            tags: [String] = .fixture,
            scores: [String: Int] = .fixture) -> Self {
            Self(avatar: avatar, tags: tags, scores: scores)
          }
          static var fixture: Self {
            fixture()
          }
        }
        """
      }
    }

    @Test func publicAccessIsMirrored() {
      assertMacro {
        """
        @Fixture public struct User {
          public let id: Int
        }
        """
      } expansion: {
        """
        public struct User {
          public let id: Int
        }

        extension User {
          public static func fixture(id: Int = .fixture) -> Self {
            Self(id: id)
          }
          public static var fixture: Self {
            fixture()
          }
        }
        """
      }
    }

    @Test func computedStaticAndInitializedPropertiesAreOmitted() {
      assertMacro {
        """
        @Fixture struct User {
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
          static func fixture(id: Int = .fixture) -> Self {
            Self(id: id)
          }
          static var fixture: Self {
            fixture()
          }
        }
        """#
      }
    }

    @Test func emptyStruct() {
      assertMacro {
        """
        @Fixture struct Empty {
        }
        """
      } expansion: {
        """
        struct Empty {
        }

        extension Empty {
            static func fixture() -> Self {
                Self()
            }
            static var fixture: Self {
                fixture()
            }
        }
        """
      }
    }

    @Test func enumUsesFirstCase() {
      assertMacro {
        """
        @Fixture enum Direction {
          case north
          case south
        }
        """
      } expansion: {
        """
        enum Direction {
          case north
          case south
        }

        extension Direction {
          static var fixture: Self {
            .north
          }
        }
        """
      }
    }

    @Test func enumFirstCaseWithAssociatedValues() {
      assertMacro {
        """
        @Fixture enum Status {
          case active(since: Date, verified: Bool)
          case banned(String)
        }
        """
      } expansion: {
        """
        enum Status {
          case active(since: Date, verified: Bool)
          case banned(String)
        }

        extension Status {
          static var fixture: Self {
            .active(since: .fixture, verified: .fixture)
          }
        }
        """
      }
    }

    @Test func enumFixtureCaseMarkerOverridesFirstCase() {
      assertMacro {
        """
        @Fixture enum Status {
          case active(since: Date)
          @FixtureCase case unknown
        }
        """
      } expansion: {
        """
        enum Status {
          case active(since: Date)
          case unknown
        }

        extension Status {
          static var fixture: Self {
            .unknown
          }
        }
        """
      }
    }

    @Test func emptyEnumDiagnoses() {
      assertMacro {
        """
        @Fixture enum Never {
        }
        """
      } diagnostics: {
        """
        @Fixture enum Never {
        ┬───────
        ╰─ 🛑 '@Fixture' requires an enum with at least one case
        }
        """
      }
    }

    @Test func attachedToClassDiagnoses() {
      assertMacro {
        """
        @Fixture class User {
          let id: Int
        }
        """
      } diagnostics: {
        """
        @Fixture class User {
        ┬───────
        ╰─ 🛑 '@Fixture' can only be attached to a struct or enum
          let id: Int
        }
        """
      }
    }
  }
#endif
