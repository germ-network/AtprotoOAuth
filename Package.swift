// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "ATProtoOAuth",
	platforms: [.iOS(.v16), .macOS(.v15)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "ATProtoOAuth",
			targets: ["ATProtoOAuth"]
		)
	],
	dependencies: [
		.package(path: "./LocalPackages/ATProtoClient"),
		.package(path: "./LocalPackages/ATProtoTypes"),
		.package(path: "./LocalPackages/OAuth"),
		.package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "4.2.0")),
		//		.package(
		//			url: "https://github.com/germ-network/OAuthenticator",
		//			branch: "mark/build-runtime"
		//		),
		.package(path: "../OAuthenticator"),
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
			name: "ATProtoOAuth",
			dependencies: [
				"ATProtoClient",
				"ATProtoTypes",
				"OAuthenticator",
				.product(name: "Crypto", package: "swift-crypto"),
				//for temp shim only
				"ATResolve",
				"OAuth"
			]
		),
		.testTarget(
			name: "ATProtoOAuthTests",
			dependencies: ["ATProtoOAuth"]
		),
	]
)
