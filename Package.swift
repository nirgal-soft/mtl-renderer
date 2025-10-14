// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mtl_renderer",
    targets: [
        .executableTarget(
            name: "mtl_renderer",
            path: "src",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
