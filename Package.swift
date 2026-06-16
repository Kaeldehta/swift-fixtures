// swift-tools-version: 6.1

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-mockable",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(name: "Mockable", targets: ["Mockable"])
  ],
  traits: [
    // Opt-in integrations with other libraries. Enable with, e.g.,
    // `swift build --traits Tagged`, or `.package(..., traits: ["Tagged"])` from a
    // consumer. The matching `swift-tagged` dependency is only resolved when enabled.
    .trait(
      name: "Tagged",
      description: "Adds a Mockable conformance for pointfree's swift-tagged Tagged type."
    ),
    .default(enabledTraits: []),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", "601.0.0"..<"602.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.5.0"),
  ],
  targets: [
    .macro(
      name: "MockableMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "Mockable",
      dependencies: [
        "MockableMacros",
        .product(name: "Tagged", package: "swift-tagged", condition: .when(traits: ["Tagged"])),
      ]
    ),
    .testTarget(
      name: "MockableMacrosTests",
      dependencies: [
        "MockableMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),
    .testTarget(
      name: "MockableTests",
      dependencies: [
        "Mockable",
        .product(name: "Tagged", package: "swift-tagged", condition: .when(traits: ["Tagged"])),
      ]
    ),
  ]
)
