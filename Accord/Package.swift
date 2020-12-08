// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Accord",
    products: [
        .library(
            name: "Accord",
            targets: ["Accord"]),
    ],
    dependencies: [
      .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "Accord",
          dependencies: ["RxSwift", .product(name: "RxRelay", package: "RxSwift")]),
        .testTarget(
            name: "AccordTests",
            dependencies: ["Accord", .product(name: "RxBlocking", package: "RxSwift")]),
    ]
)
