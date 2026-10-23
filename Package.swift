// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "FrameCraft", platforms: [.macOS("15.0")], products: [.executable(name: "FrameCraft", targets: ["FrameCraft"])], targets: [.executableTarget(name: "FrameCraft"), .testTarget(name: "FrameCraftTests", dependencies: ["FrameCraft"])])
