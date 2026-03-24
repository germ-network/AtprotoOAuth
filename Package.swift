// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "AtprotoOAuth",
	platforms: [.iOS(.v16), .macOS(.v15)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "AtprotoOAuth",
			targets: ["AtprotoOAuth"]
		)
	],
	dependencies: [
		.package(
			url: "https://github.com/germ-network/AtprotoClient.git",
			from: "0.0.4"
		),
		.package(
			url: "https://github.com/germ-network/AtprotoTypes.git",
			from: "0.0.4"
		),
		.package(
			url: "https://github.com/germ-network/oauth4swift.git",
			from: "0.0.2"
		),
		.package(
			url: "https://github.com/germ-network/Microcosm.git",
			branch: "0.0.4"
		),
		.package(
			url: "https://github.com/apple/swift-crypto.git",
			.upToNextMajor(from: "4.2.0")),
		.package(
			url: "https://github.com/germ-network/ATResolve",
			exact: "1.0.0-germ.2"
		),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "AtprotoOAuth",
			dependencies: [
				"AtprotoClient",
				"AtprotoTypes",
				.product(name: "Crypto", package: "swift-crypto"),
				"Microcosm",
				.product(name: "OAuth", package: "oauth4swift"),
			]
		),
		.testTarget(
			name: "AtprotoOAuthTests",
			dependencies: [
				"AtprotoOAuth",
				//for temp shim only
				"ATResolve",
			]
		),
	]
)
