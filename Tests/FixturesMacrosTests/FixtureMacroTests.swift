#if os(macOS)
  import MacroTesting
  import FixturesMacros
  import Testing

  @Suite(
    .macros(
      [FixtureMacro.self, FixtureCaseMacro.self, FixtureInitMacro.self, FixtureValueMacro.self],
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

    @Test func fixtureValueOverridesPropertyDefault() {
      assertMacro {
        """
        @Fixture struct User {
          @FixtureValue("someone@example.com") let email: String
          let name: String
        }
        """
      } expansion: {
        """
        struct User {
          let email: String
          let name: String
        }

        extension User {
          static func fixture(email: String = "someone@example.com",
            name: String = .fixture) -> Self {
            Self(email: email, name: name)
          }
          static var fixture: Self {
            fixture()
          }
        }
        """
      }
    }

    @Test func customInitMirrorsTargetedInitializer() {
      assertMacro {
        """
        @Fixture struct User {
          let id: Int
          let name: String
          init(id: Int) {
            self.id = id
            self.name = "anonymous"
          }
        }
        """
      } expansion: {
        """
        struct User {
          let id: Int
          let name: String
          init(id: Int) {
            self.id = id
            self.name = "anonymous"
          }
        }

        extension User {
          static func fixture(id: Int = .fixture) -> Self {
            Self(id: id)
          }
          static var fixture: Self {
            fixture()
          }
        }
        """
      }
    }

    @Test func customInitKeepsExistingDefault() {
      assertMacro {
        """
        @Fixture struct User {
          let id: Int
          let name: String
          init(id: Int, name: String = "anonymous") {
            self.id = id
            self.name = name
          }
        }
        """
      } expansion: {
        """
        struct User {
          let id: Int
          let name: String
          init(id: Int, name: String = "anonymous") {
            self.id = id
            self.name = name
          }
        }

        extension User {
          static func fixture(id: Int = .fixture,
            name: String = "anonymous") -> Self {
            Self(id: id, name: name)
          }
          static var fixture: Self {
            fixture()
          }
        }
        """
      }
    }

    @Test func customInitMirrorsLabelsNamesAndWildcard() {
      assertMacro {
        """
        @Fixture struct Point {
          let x: Int
          let y: Int
          init(_ x: Int, vertical y: Int) {
            self.x = x
            self.y = y
          }
        }
        """
      } expansion: {
        """
        struct Point {
          let x: Int
          let y: Int
          init(_ x: Int, vertical y: Int) {
            self.x = x
            self.y = y
          }
        }

        extension Point {
          static func fixture(_ x: Int = .fixture,
            vertical y: Int = .fixture) -> Self {
            Self(x, vertical: y)
          }
          static var fixture: Self {
            fixture()
          }
        }
        """
      }
    }

    @Test func customInitFixtureValuePassthroughTakesPrecedence() {
      assertMacro {
        """
        @Fixture struct User {
          @FixtureValue("anonymous") let name: String
          init(name: String = "default") {
            self.name = name
          }
        }
        """
      } expansion: {
        """
        struct User {
          let name: String
          init(name: String = "default") {
            self.name = name
          }
        }

        extension User {
          static func fixture(name: String = "anonymous") -> Self {
            Self(name: name)
          }
          static var fixture: Self {
            fixture()
          }
        }
        """
      }
    }

    @Test func multipleInitsTargetFixtureInitMarker() {
      assertMacro {
        """
        @Fixture struct User {
          let id: Int
          @FixtureInit
          init(id: Int) {
            self.id = id
          }
          init(uuid: UUID) {
            self.id = uuid.hashValue
          }
        }
        """
      } expansion: {
        """
        struct User {
          let id: Int
          init(id: Int) {
            self.id = id
          }
          init(uuid: UUID) {
            self.id = uuid.hashValue
          }
        }

        extension User {
          static func fixture(id: Int = .fixture) -> Self {
            Self(id: id)
          }
          static var fixture: Self {
            fixture()
          }
        }
        """
      }
    }

    @Test func initInExtensionKeepsMemberwisePath() {
      assertMacro {
        """
        @Fixture struct User {
          let id: Int
        }
        extension User {
          init(uuid: UUID) {
            self.id = uuid.hashValue
          }
        }
        """
      } expansion: {
        """
        struct User {
          let id: Int
        }
        extension User {
          init(uuid: UUID) {
            self.id = uuid.hashValue
          }
        }

        extension User {
          static func fixture(id: Int = .fixture) -> Self {
            Self(id: id)
          }
          static var fixture: Self {
            fixture()
          }
        }
        """
      }
    }

    @Test func orphanFixtureValueTransformedDiagnoses() {
      assertMacro {
        """
        @Fixture struct User {
          @FixtureValue("anonymous") let name: String
          init(name: String) {
            self.name = name.uppercased()
          }
        }
        """
      } diagnostics: {
        """
        @Fixture struct User {
          @FixtureValue("anonymous") let name: String
          ┬─────────────────────────
          ╰─ 🛑 '@FixtureValue' does not correspond to any initializer parameter (the property is not stored unchanged from a parameter)
          init(name: String) {
            self.name = name.uppercased()
          }
        }
        """
      }
    }

    @Test func orphanFixtureValueNoMatchingParameterDiagnoses() {
      assertMacro {
        """
        @Fixture struct User {
          let id: Int
          @FixtureValue("anonymous") let name: String
          init(id: Int) {
            self.id = id
            self.name = "x"
          }
        }
        """
      } diagnostics: {
        """
        @Fixture struct User {
          let id: Int
          @FixtureValue("anonymous") let name: String
          ┬─────────────────────────
          ╰─ 🛑 '@FixtureValue' does not correspond to any initializer parameter (the property is not stored unchanged from a parameter)
          init(id: Int) {
            self.id = id
            self.name = "x"
          }
        }
        """
      }
    }

    @Test func multipleInitsWithoutMarkerDiagnoses() {
      assertMacro {
        """
        @Fixture struct User {
          let id: Int
          init(id: Int) {
            self.id = id
          }
          init(value: Int) {
            self.id = value
          }
        }
        """
      } diagnostics: {
        """
        @Fixture struct User {
        ┬───────
        ╰─ 🛑 '@Fixture' needs '@FixtureInit' on one initializer when the type declares more than one
          let id: Int
          init(id: Int) {
            self.id = id
          }
          init(value: Int) {
            self.id = value
          }
        }
        """
      }
    }

    @Test func multipleFixtureInitMarkersDiagnoses() {
      assertMacro {
        """
        @Fixture struct User {
          let id: Int
          @FixtureInit
          init(id: Int) {
            self.id = id
          }
          @FixtureInit
          init(value: Int) {
            self.id = value
          }
        }
        """
      } diagnostics: {
        """
        @Fixture struct User {
          let id: Int
          @FixtureInit
          init(id: Int) {
            self.id = id
          }
          @FixtureInit
          ╰─ 🛑 '@Fixture' allows only one '@FixtureInit' initializer
          init(value: Int) {
            self.id = value
          }
        }
        """
      }
    }

    @Test func throwingInitDiagnoses() {
      assertMacro {
        """
        @Fixture struct User {
          let id: Int
          init(id: Int) throws {
            self.id = id
          }
        }
        """
      } diagnostics: {
        """
        @Fixture struct User {
          let id: Int
          init(id: Int) throws {
          ╰─ 🛑 '@Fixture' cannot target a failable, throwing, or async initializer
            self.id = id
          }
        }
        """
      }
    }

    @Test func failableInitDiagnoses() {
      assertMacro {
        """
        @Fixture struct User {
          let id: Int
          init?(id: Int) {
            self.id = id
          }
        }
        """
      } diagnostics: {
        """
        @Fixture struct User {
          let id: Int
          init?(id: Int) {
          ╰─ 🛑 '@Fixture' cannot target a failable, throwing, or async initializer
            self.id = id
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
