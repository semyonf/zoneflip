// swift-tools-version:5.10
import PackageDescription

let package = Package(
	name: "ZoneFlip",
	platforms: [.macOS(.v14)],
	targets: [
		.executableTarget(name: "ZoneFlip", path: "Sources")
	]
)
