// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TabBar",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "TabBar", targets: ["TabBar"]),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.6.0"),
    ],
    targets: [
        .target(
            name: "TabBar",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios"),
            ]
        ),
        .testTarget(
            name: "TabBarTests",
            dependencies: ["TabBar"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
