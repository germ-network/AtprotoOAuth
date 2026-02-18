// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftATProtoOAuth",
	platforms: [.iOS(.v17), .macOS(.v15)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "SwiftATProtoOAuth",
			targets: ["SwiftATProtoOAuth"]
		)
	],
	dependencies: [
		.package(path: "./LocalPackages/SwiftATProtoTypes"),
		//for temp shim only
		.package(
			url: "https://github.com/germ-network/ATResolve",
			exact: "1.0.0-germ.2"
		),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "SwiftATProtoOAuth",
			dependencies: [
				"SwiftATProtoTypes",
				//for temp shim only
				"ATResolve"
			]
		),
		.testTarget(
			name: "SwiftATProtoOAuthTests",
			dependencies: ["SwiftATProtoOAuth"]
		),
	]
)
