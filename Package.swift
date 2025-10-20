// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mtl-renderer",
    targets: [
        .executableTarget(
            name: "mtl-renderer",
            path: "src",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
