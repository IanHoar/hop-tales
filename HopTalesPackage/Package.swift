// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "HopTalesPackage",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "AppFeature", targets: ["AppFeature"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.12.0"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
    .package(
      url: "https://github.com/pointfreeco/TCA26",
      branch: "main",
      traits: ["Clocks", "Dependencies", "SwiftNavigation", .defaults]
    )
  ],
  targets: [
    .target(
      name: "AppFeature",
      dependencies: [
        "Content",
        "DesignSystem",
        "GrownUps",
        "Home",
        "Onboarding",
        "Reading",
        "World",
        .product(name: "ComposableArchitecture2", package: "TCA26"),
        .product(name: "Dependencies", package: "swift-dependencies"),
      ]
    ),
    .target(
      name: "Onboarding",
      dependencies: [
        "Content",
        "DesignSystem",
        "SpeechRecognition",
        "World",
        .product(name: "ComposableArchitecture2", package: "TCA26"),
        .product(name: "Dependencies", package: "swift-dependencies"),
      ]
    ),
    .target(
      name: "Content",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ],
      resources: [.process("Resources")]
    ),
    .target(
      name: "DesignSystem",
      resources: [.process("Resources")]
    ),
    .target(
      name: "GrownUps",
      dependencies: [
        "Content",
        "DesignSystem",
        "SpeechRecognition",
        "World",
        .product(name: "ComposableArchitecture2", package: "TCA26"),
        .product(name: "Dependencies", package: "swift-dependencies"),
      ]
    ),
    .target(
      name: "Home",
      dependencies: [
        "Content",
        "DesignSystem",
        "World",
        .product(name: "ComposableArchitecture2", package: "TCA26"),
        .product(name: "Dependencies", package: "swift-dependencies"),
      ]
    ),
    .target(
      name: "Reading",
      dependencies: [
        "Content",
        "DesignSystem",
        "SpeechRecognition",
        "World",
        .product(name: "ComposableArchitecture2", package: "TCA26"),
        .product(name: "Dependencies", package: "swift-dependencies"),
      ]
    ),
    .target(
      name: "SpeechRecognition",
      dependencies: [
        "Content",
        .product(name: "ComposableArchitecture2", package: "TCA26"),
        .product(name: "Dependencies", package: "swift-dependencies"),
      ]
    ),
    .target(
      name: "World",
      dependencies: [
        "Content",
        "DesignSystem"
      ],
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "AppFeatureTests",
      dependencies: [
        "AppFeature",
        "Content",
        "GrownUps",
        "Onboarding",
        "SpeechRecognition",
      ]
    ),
    .testTarget(
      name: "ReadingTests",
      dependencies: [
        "DesignSystem",
        "Reading",
        "SpeechRecognition",
        "World",
      ]
    ),
    .testTarget(
      name: "SnapshotTests",
      dependencies: [
        "AppFeature",
        "Content",
        "DesignSystem",
        "GrownUps",
        "Home",
        "Onboarding",
        "Reading",
        "SpeechRecognition",
        "World",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
      ],
      resources: [.copy("__Snapshots__")]
    ),
    .testTarget(
      name: "ContentTests",
      dependencies: [
        "Content",
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .testTarget(
      name: "WorldTests",
      dependencies: ["Content", "World"]
    ),
    .testTarget(
      name: "SpeechTests",
      dependencies: [
        "SpeechRecognition"
      ]
    ),
  ]
)
