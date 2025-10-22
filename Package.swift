// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "sendgrid-kit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "SendGridKit", targets: ["SendGridKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.29.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "3.9.0"..<"5.0.0"),
    ],
    targets: [
        .target(
            name: "SendGridKit",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Crypto", package: "swift-crypto"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SendGridKitTests",
            dependencies: [
                .target(name: "SendGridKit")
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("ExistentialAny")
    ]
}
