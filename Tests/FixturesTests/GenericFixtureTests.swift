import Fixtures
import Testing

@Fixture
struct Labeled<Value: Equatable>: Equatable {
  let value: Value
  let label: String?
}

@Fixture
struct Listing<Item: Equatable, Meta: Equatable>: Equatable {
  let items: [Item]
  let featured: Labeled<Item>
  @FixtureValue([Meta]()) let tags: [Meta]
}

@Fixture
struct Inventory: Equatable {
  let owner: Labeled<String>
  let listing: Listing<Int, Double>
}

struct Product: Identifiable, Equatable, Fixture {
  let id: Int
  static var fixture: Product { Product(id: 7) }
}

@Fixture
struct Row<Model: Identifiable & Equatable>: Equatable {
  let id: Model.ID
  let model: Model
}

@Fixture
struct Wrapper<Value: Equatable>: Equatable {
  let value: Value
  let note: String
  init(_ value: Value, note: String = "none") {
    self.value = value
    self.note = note
  }
}

@Fixture
enum Loadable<Value: Equatable>: Equatable {
  case idle
  @FixtureCase case loaded(Value)
}

@Suite
struct GenericFixtureTests {
  @Test func genericStructNestedInNonGenericStruct() {
    #expect(
      Inventory.fixture
        == Inventory(
          owner: Labeled(value: "", label: nil),
          listing: Listing(
            items: [], featured: Labeled(value: 0, label: nil), tags: [])))
  }

  @Test func genericFactoryOverridesFields() {
    let listing = Listing<Int, Double>.fixture(items: [1, 2], tags: [0.5])
    #expect(listing.items == [1, 2])
    #expect(listing.featured == Labeled(value: 0, label: nil))
    #expect(listing.tags == [0.5])
  }

  @Test func fixtureValueLiftsConstraint() {
    // `Meta` need not be `Fixture`: its property defaults via `@FixtureValue`.
    struct NotFixture: Equatable {}
    #expect(Listing<Int, NotFixture>.fixture.tags == [])
  }

  @Test func memberTypePathIsConstrained() {
    #expect(Row<Product>.fixture == Row(id: 0, model: Product(id: 7)))
  }

  @Test func customInitGenericStruct() {
    #expect(Wrapper<Int>.fixture == Wrapper(0, note: "none"))
    #expect(Wrapper.fixture(42).value == 42)
  }

  @Test func genericEnumUsesChosenCase() {
    #expect(Loadable<String>.fixture == .loaded(""))
  }
}
