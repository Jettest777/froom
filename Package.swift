// swift-tools-version: 5.9
// f/Room - NFL Study App
// Note: This is the SPM definition for the library logic.
// The actual iOS app target should be created as an Xcode project.
// See README.md for setup instructions.

import PackageDescription

let package = Package(
    name: "FRoom",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "FRoomCore", targets: ["FRoomCore"]),
    ],
    targets: [
        .target(
            name: "FRoomCore",
            path: "froom"
        ),
    ]
)
