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
		// 0.7.0 is the release that adds `unfollow` (MockRepo/MockPDS).
		// 0.9.0 carries the GermConvenienceHTTP-adoption fix for 0.8.0.
		.package(
			url: "https://github.com/germ-network/AtprotoClient.git",
			from: "0.9.0"
		),
		.package(
			url: "https://github.com/germ-network/AtprotoTypes.git",
			from: "0.4.5"
		),
		.package(
			url: "https://github.com/germ-network/GermConvenience.git",
			// 0.8.0 split HTTP helpers into GermConvenienceHTTP — the floor this
			// package now needs for HTTPFetcher/HTTPDataResponse.
			from: "0.8.0"
		),
		//use this as a out of the box resolver for tests
		//does not get included in the main package
		//0.4.1 carries the GermConvenienceHTTP-adoption fix for 0.8.0.
		.package(
			url: "https://github.com/germ-network/Microcosm.git",
			from: "0.4.1"
		),
		// NEGATIVE PROBE (throwaway): revision pin must make the guard go red.
		.package(
			url: "https://github.com/germ-network/oauth4swift.git",
			revision: "f8bed9aae685813c832ab87bb48d9dc6f86fcc30"
		),
		.package(
			url: "https://github.com/apple/swift-crypto.git",
			.upToNextMajor(from: "4.2.0")),
		.package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
		.package(url: "https://github.com/apple/swift-http-types.git", from: "1.5.1"),
		.package(url: "https://github.com/swift-libp2p/swift-bases.git", from: "0.2.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "AtprotoOAuth",
			dependencies: [
				"AtprotoClient",
				"AtprotoTypes",
				"GermConvenience",
				.product(name: "GermConvenienceHTTP", package: "GermConvenience"),
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
				.product(name: "Base64", package: "swift-bases"),
				.product(name: "Logging", package: "swift-log"),
				.product(name: "GermConvenienceHTTP", package: "GermConvenience"),
			]
		),
		.testTarget(
			name: "AtprotoOAuthTests",
			dependencies: [
				"AtprotoOAuth",
				"Microcosm",
				.product(name: "GermConvenienceHTTP", package: "GermConvenience"),
			]
		),
	]
)
