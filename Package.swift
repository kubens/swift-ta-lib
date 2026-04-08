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
      name: "TALib",
      dependencies: [.target(name: "ta-lib")],
      plugins: [.plugin(name: "TAGeneratorPlugin")]
    ),
    .target(
      name: "ta-lib",
      exclude: [
        "src/ta_func/Makefile.am",
        "src/ta_abstract/Makefile.am",
        "src/ta_abstract/templates",
        "src/ta_common/Makefile.am",
        "src/ta_common/ta_retcode.csv",
        "src/tools",
      ],
      sources: [
        "src/ta_func",
        "src/ta_abstract",
        "src/ta_common",
      ],
      publicHeadersPath: "include",
      cSettings: [
        .headerSearchPath("include"),
        .headerSearchPath("src/ta_abstract"),
        .headerSearchPath("src/ta_abstract/frames"),
        .headerSearchPath("src/ta_common"),
        .headerSearchPath("src/ta_func"),
        .define("TA_LIB_VERSION_MAJOR", to: "0"),
        .define("TA_LIB_VERSION_MINOR", to: "6"),
        .define("TA_LIB_VERSION_BUILD", to: "0"),
        .define("TA_LIB_VERSION_EXTRA", to: "\"dev\""),
        .define("TA_LIB_VERSION_FULL", to: "\"0.6.0-dev\""),
      ],
      linkerSettings: [
        .linkedLibrary("m", .when(platforms: [.linux]))
      ]
    ),
    .executableTarget(
      name: "TACodeGenerator"
    ),
    .plugin(
      name: "TAGeneratorPlugin",
      capability: .buildTool(),
      dependencies: ["TACodeGenerator"]
    ),
    .testTarget(
      name: "TALibTests",
      dependencies: ["TALib"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
