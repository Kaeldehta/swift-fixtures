// swift-tools-version: 6.1

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-fixture",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(name: "Fixture", targets: ["Fixture"])
  ],
  traits: [
    // Opt-in integrations; each dependency is only resolved when its trait is enabled.
    .trait(
      name: "Tagged",
      description: "Adds a Fixture conformance for pointfree's swift-tagged Tagged type."
    ),
    .trait(
      name: "IdentifiedCollections",
      description:
        "Adds a Fixture conformance for pointfree's swift-identified-collections IdentifiedArray."
    ),
    .default(enabledTraits: []),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.1.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", "601.0.0"..<"602.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.5.0"),
  ],
  targets: [
    .macro(
      name: "FixtureMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "Fixture",
      dependencies: [
        "FixtureMacros",
        .product(name: "Tagged", package: "swift-tagged", condition: .when(traits: ["Tagged"])),
        .product(
          name: "IdentifiedCollections",
          package: "swift-identified-collections",
          condition: .when(traits: ["IdentifiedCollections"])
        ),
      ]
    ),
    .testTarget(
      name: "FixtureMacrosTests",
      dependencies: [
        "FixtureMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),
    .testTarget(
      name: "FixtureTests",
      dependencies: [
        "Fixture",
        .product(name: "Tagged", package: "swift-tagged", condition: .when(traits: ["Tagged"])),
        .product(
          name: "IdentifiedCollections",
          package: "swift-identified-collections",
          condition: .when(traits: ["IdentifiedCollections"])
        ),
      ]
    ),
  ]
)
