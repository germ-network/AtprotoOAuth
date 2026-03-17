// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "AtprotoClient",
	platforms: [.iOS(.v16), .macOS(.v15)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "AtprotoClient",
			targets: ["AtprotoClient"]
		)
	],
	dependencies: [
		.package(
			url: "https://github.com/germ-network/AtprotoTypes.git",
			from: "0.0.2"
		),
		.package(
			url: "https://github.com/germ-network/GermConvenience.git",
			from: "0.0.2"
		),
		.package(
			url: "https://github.com/apple/swift-crypto.git",
			.upToNextMajor(from: "4.2.0")),
		.package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "AtprotoClient",
			dependencies: [
				"AtprotoTypes",
				.product(name: "Crypto", package: "swift-crypto"),
				"GermConvenience",
				.product(name: "Logging", package: "swift-log"),
			]
		),
		.testTarget(
			name: "AtprotoClientTests",
			dependencies: ["AtprotoClient"]
		),
	]
)
