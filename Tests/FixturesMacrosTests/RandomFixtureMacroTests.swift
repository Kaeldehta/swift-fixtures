#if os(macOS)
  import MacroTesting
  import FixturesMacros
  import Testing

  @Suite(
    .macros(
      [RandomFixtureMacro.self, RandomFixtureValueMacro.self],
      record: .missing
    )
  )
  struct RandomFixtureMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @RandomFixture struct User {
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
          static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Self {
            Self(id: .randomFixture(using: &rng),
              name: .randomFixture(using: &rng))
          }
        }
        """
      }
    }

    @Test func randomFixtureValue() {
      assertMacro {
        """
        @RandomFixture struct Player {
          @RandomFixtureValue(IntGenerator(in: 1...6)) let die: Int
          let name: String
        }
        """
      } expansion: {
        """
        struct Player {
          let die: Int
          let name: String
        }

        extension Player {
          static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Self {
            Self(die: (IntGenerator(in: 1 ... 6)).run(using: &rng),
              name: .randomFixture(using: &rng))
          }
        }
        """
      }
    }

    @Test func publicAccessIsMirrored() {
      assertMacro {
        """
        @RandomFixture public struct User {
          public let id: Int
        }
        """
      } expansion: {
        """
        public struct User {
          public let id: Int
        }

        extension User {
          public static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Self {
            Self(id: .randomFixture(using: &rng))
          }
        }
        """
      }
    }

    @Test func multiCaseEnum() {
      assertMacro {
        """
        @RandomFixture enum Status {
          case active(code: Int, label: String)
          case banned
        }
        """
      } expansion: {
        """
        enum Status {
          case active(code: Int, label: String)
          case banned
        }

        extension Status {
          static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Self {
            switch Int.random(in: 0 ..< 2, using: &rng) {
            case 0:
              return .active(code: .randomFixture(using: &rng), label: .randomFixture(using: &rng))
            default:
              return .banned
            }
          }
        }
        """
      }
    }

    @Test func singleCaseEnum() {
      assertMacro {
        """
        @RandomFixture enum Wrapper {
          case value(Int)
        }
        """
      } expansion: {
        """
        enum Wrapper {
          case value(Int)
        }

        extension Wrapper {
          static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Self {
            .value(.randomFixture(using: &rng))
          }
        }
        """
      }
    }

    @Test func computedAndDefaultedPropertiesAreSkipped() {
      assertMacro {
        """
        @RandomFixture struct User {
          let id: Int
          var displayName: String { "user-\\(id)" }
          static let kind = "user"
        }
        """
      } expansion: {
        #"""
        struct User {
          let id: Int
          var displayName: String { "user-\(id)" }
          static let kind = "user"
        }

        extension User {
          static func randomFixture<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Self {
            Self(id: .randomFixture(using: &rng))
          }
        }
        """#
      }
    }

    @Test func customInitializerIsDiagnosed() {
      assertMacro {
        """
        @RandomFixture struct User {
          let id: Int
          init(id: Int) { self.id = id }
        }
        """
      } diagnostics: {
        """
        @RandomFixture struct User {
        ┬─────────────
        ╰─ 🛑 '@RandomFixture' supports only the memberwise path; declare custom initializers in an extension to keep it
          let id: Int
          init(id: Int) { self.id = id }
        }
        """
      }
    }

    @Test func classIsDiagnosed() {
      assertMacro {
        """
        @RandomFixture class User {
          let id: Int = 0
        }
        """
      } diagnostics: {
        """
        @RandomFixture class User {
        ┬─────────────
        ╰─ 🛑 '@RandomFixture' can only be attached to a struct or enum
          let id: Int = 0
        }
        """
      }
    }
  }
#endif
