#if IdentifiedCollections
  import Fixture
  import IdentifiedCollections
  import Testing

  struct Item: Identifiable, Equatable {
    let id: Int
    let name: String
  }

  @Fixture
  struct Inventory {
    let items: IdentifiedArrayOf<Item>
    let name: String
  }

  @Suite
  struct IdentifiedCollectionsFixtureTests {
    @Test func identifiedArrayDefaultsEmpty() {
      let inventory = Inventory.fixture()
      #expect(inventory.items.isEmpty)
      #expect(inventory.name == "")
    }

    @Test func overrideIdentifiedArray() {
      let inventory = Inventory.fixture(items: [Item(id: 1, name: "Widget")])
      #expect(inventory.items.count == 1)
      #expect(inventory.items[id: 1]?.name == "Widget")
    }
  }
#endif
