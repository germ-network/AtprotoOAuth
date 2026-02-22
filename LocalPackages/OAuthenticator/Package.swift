// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "OAuthenticator",
	platforms: [
		.macOS(.v12),
		.macCatalyst(.v13),
		.iOS(.v15),
		.tvOS(.v13),
		.watchOS(.v7),
		.visionOS(.v1),
	],
	products: [
		.library(name: "OAuthenticator", targets: ["OAuthenticator"])
	],
	dependencies: [
		.package(path: "../oauth4swift")
	],
	targets: [
		.target(
			name: "OAuthenticator",
			dependencies: [
				.product(name: "OAuth", package: "oauth4swift")
			],
			resources: [.process("PrivacyInfo.xcprivacy")]
		),
		.testTarget(name: "OAuthenticatorTests", dependencies: ["OAuthenticator"]),
	]
)
