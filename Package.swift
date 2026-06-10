// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PointTrans",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PointTrans", targets: ["PointTrans"])
    ],
    targets: [
        .executableTarget(
            name: "PointTrans",
            path: "Sources/PointTrans",
            exclude: ["local_dict.json", "app_icon_transparent.png", "AppIcon.icns"]
        )
    ]
)
