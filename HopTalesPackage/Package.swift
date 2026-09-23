// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "HopTalesPackage",
  platforms: [
    .iOS(.v27)
  ],
  products: [
    .library(name: "AppFeature", targets: ["AppFeature"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.12.0"),
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
        "Home",
        "Onboarding",
        "Reading",
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
      ],
      resources: [.process("Resources")]
    ),
    .target(
      name: "DesignSystem"
    ),
    .target(
      name: "Home",
      dependencies: [
        "Content",
        "DesignSystem",
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
        "DesignSystem"
      ],
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "AppFeatureTests",
      dependencies: [
        "AppFeature",
        "Content",
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
      ]
    ),
    .testTarget(
      name: "SnapshotTests",
      dependencies: [
        "Content",
        "DesignSystem",
        "Home",
        "Reading",
        "SpeechRecognition",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
      ],
      resources: [.copy("__Snapshots__")]
    ),
    .testTarget(
      name: "ContentTests",
      dependencies: ["Content"]
    ),
    .testTarget(
      name: "WorldTests",
      dependencies: ["World"]
    ),
    .testTarget(
      name: "SpeechTests",
      dependencies: [
        "SpeechRecognition"
      ]
    ),
  ]
)
