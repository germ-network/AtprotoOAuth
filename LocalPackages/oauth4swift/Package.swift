// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "OAuth",
	platforms: [.iOS(.v15), .macOS(.v12)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "OAuth",
			targets: ["OAuth"]
		)
	],
	dependencies: [
		.package(path: "../GermConvenience"),
		.package(
			url: "https://github.com/apple/swift-crypto.git",
			.upToNextMajor(from: "4.2.0")),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "OAuth",
			dependencies: [
				"GermConvenience",
				.product(name: "Crypto", package: "swift-crypto"),
			]
		),
		.testTarget(
			name: "OAuthTests",
			dependencies: ["OAuth"]
		),
	]
)
