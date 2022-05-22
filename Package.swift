// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mupdf",
    platforms: [.iOS(.v11), .macOS(.v11)],
    products: [
        .library(
            name: "mupdf",
            targets: ["mupdf"]),
    ],
    dependencies: [
        .package(url: "https://github.com/awxkee/libyuv.swift.git", branch: "master")
    ],
    targets: [
        .target(
            name: "mupdf",
            dependencies: ["cmupdf", .product(name: "libyuv", package: "libyuv.swift")]),
        .target(name: "cmupdf",
                dependencies: ["libmupdf", "libmupdf-threads", "libmupdf-third", "libmupdf-pkcs7"],
                publicHeadersPath: "include",
                cSettings: [.headerSearchPath(".")],
                cxxSettings: [.headerSearchPath(".")]),
        .binaryTarget(name: "libmupdf", path: "Sources/libmupdf.xcframework"),
        .binaryTarget(name: "libmupdf-threads", path: "Sources/libmupdf-threads.xcframework"),
        .binaryTarget(name: "libmupdf-third", path: "Sources/libmupdf-third.xcframework"),
        .binaryTarget(name: "libmupdf-pkcs7", path: "Sources/libmupdf-pkcs7.xcframework"),
        .testTarget(
            name: "mupdfTests",
            dependencies: ["mupdf"]),
    ]
)
