#if SwiftRandomKit
  import Fixtures
  import SwiftRandomKit
  import Testing

  @RandomFixture
  struct RandomUser: Equatable {
    let id: Int
    let name: String
    let isAdmin: Bool
    let nickname: String?
    let scores: [Int]
  }

  @RandomFixture
  enum RandomStatus: Hashable {
    case active(code: Int)
    case banned
    case pending
  }

  @RandomFixture
  struct BoundedPlayer: Equatable {
    @RandomFixtureValue(IntGenerator(in: 1...6)) let die: Int
    let name: String
  }

  @Suite
  struct RandomFixtureTests {
    @Test func reproducibleUnderTheSameSeed() {
      var rng1 = Xoshiro256(seed: 42)
      var rng2 = Xoshiro256(seed: 42)

      for _ in 0..<10 {
        #expect(RandomUser.randomFixture(using: &rng1) == RandomUser.randomFixture(using: &rng2))
      }
    }

    @Test func variedAcrossDraws() {
      var rng = Xoshiro256(seed: 42)
      let users = (0..<10).map { _ in RandomUser.randomFixture(using: &rng) }

      #expect(Set(users.map(\.id)).count > 1, "Repeated fixtures should differ")
    }

    @Test func enumPicksAllCasesUniformly() {
      var rng = Xoshiro256(seed: 7)
      var seen = Set<RandomStatus>()
      var caseCounts = [Int](repeating: 0, count: 3)

      for _ in 0..<300 {
        let status = RandomStatus.randomFixture(using: &rng)
        seen.insert(status)
        switch status {
        case .active: caseCounts[0] += 1
        case .banned: caseCounts[1] += 1
        case .pending: caseCounts[2] += 1
        }
      }

      #expect(caseCounts.allSatisfy { $0 > 50 }, "Each case should be picked roughly 1/3 of the time, got \(caseCounts)")
    }

    @Test func randomFixtureValueBoundsTheDraw() {
      var rng = Xoshiro256(seed: 1)

      for _ in 0..<100 {
        let player = BoundedPlayer.randomFixture(using: &rng)
        #expect((1...6).contains(player.die))
      }
    }

    @Test func composesWithSwiftRandomKitCombinators() {
      var rng = Xoshiro256(seed: 42)

      let party = RandomUser.randomFixtureGenerator.array(5).run(using: &rng)
      #expect(party.count == 5)

      let maybeUser = RandomUser.randomFixtureGenerator.orNil(probability: 1).run(using: &rng)
      #expect(maybeUser == nil)
    }

    @Test func builtInConformancesStayBounded() {
      var rng = Xoshiro256(seed: 3)

      for _ in 0..<50 {
        #expect(String.randomFixture(using: &rng).count <= 16)
        #expect([Int].randomFixture(using: &rng).count <= 3)
        #expect([String: Int].randomFixture(using: &rng).count <= 3)
      }
    }

    @Test func optionalDrawsBothNilAndValues() {
      var rng = Xoshiro256(seed: 5)
      var sawNil = false
      var sawValue = false

      for _ in 0..<100 {
        if Int?.randomFixture(using: &rng) == nil { sawNil = true } else { sawValue = true }
      }

      #expect(sawNil && sawValue)
    }
  }
#endif
