// swift-tools-version: 6.0

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
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"603.0.0"),
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
      dependencies: ["MockableMacros"]
    ),
    .testTarget(
      name: "MockableMacrosTests",
      dependencies: [
        "MockableMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),
  ]
)
