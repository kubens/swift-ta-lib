// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "swift-ta-lib",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v12),
    .macOS(.v10_13),
    .watchOS(.v4),
    .tvOS(.v12),
    .visionOS(.v1),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "TALib",
      targets: ["TALib"]
    )
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "TALib"
    ),
    .testTarget(
      name: "TALibTests",
      dependencies: ["TALib"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
