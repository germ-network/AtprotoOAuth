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
			from: "0.4.0"
		),
		.package(
			url: "https://github.com/germ-network/AtprotoTypes.git",
			from: "0.2.3"
		),
		.package(
			url: "https://github.com/germ-network/Microcosm.git",
			from: "0.1.0"
		),
		.package(
			url: "https://github.com/germ-network/oauth4swift.git",
			//			from: "0.3.0"
			branch: "fix/refresh-api"
		),
		.package(
			url: "https://github.com/apple/swift-crypto.git",
			.upToNextMajor(from: "4.2.0")),
		.package(url: "https://github.com/apple/swift-http-types.git", from: "1.5.1"),
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
				.product(name: "HTTPTypes", package: "swift-http-types"),
				.product(name: "OAuth4Swift", package: "oauth4swift"),
			]
		),
		.testTarget(
			name: "AtprotoOAuthTests",
			dependencies: [
				"AtprotoOAuth",
				"Microcosm",
			]
		),
	]
)
