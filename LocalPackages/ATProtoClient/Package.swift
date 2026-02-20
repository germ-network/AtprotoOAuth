// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "ATProtoClient",
	platforms: [.macOS(.v13)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "ATProtoClient",
			targets: ["ATProtoClient"]
		)
	],
	dependencies: [
		.package(path: "../ATProtoTypes"),
		//for temp shim only
		//		.package(
		//			url: "https://github.com/germ-network/OAuthenticator",
		//			branch: "mark/build-runtime"
		//		),
		.package(path: "../../OAuthenticator"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "ATProtoClient",
			dependencies: [
				"ATProtoTypes",
				"OAuthenticator",
			]
		),
		.testTarget(
			name: "ATProtoClientTests",
			dependencies: ["ATProtoClient"]
		),
	]
)
