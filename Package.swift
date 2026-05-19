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
		),
		.library(name: "AtprotoOAuthMocks", targets: ["AtprotoOAuthMocks"]),
	],
	dependencies: [
		.package(
			url: "https://github.com/germ-network/AtprotoClient.git",
			//			from: "0.5.7"
			branch: "fix/imports"
		),
		.package(
			url: "https://github.com/germ-network/AtprotoTypes.git",
			//			from: "0.4.4"
			branch: "fix/reduce-imports"
		),
		//use this as a out of the box resolver for tests
		//does not get included in the main package
		.package(
			url: "https://github.com/germ-network/Microcosm.git",
			from: "0.3.2"
		),
		.package(
			url: "https://github.com/germ-network/oauth4swift.git",
			//			from: "0.3.3"
			branch: "fix/imports"
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
		.target(
			name: "AtprotoOAuthMocks",
			dependencies: [
				"AtprotoClient",
				"AtprotoOAuth",
				.product(name: "AtprotoClientMocks", package: "AtprotoClient"),
				.product(name: "AtprotoTypesMocks", package: "AtprotoTypes"),
				.product(name: "Mockable", package: "AtprotoTypes"),
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
