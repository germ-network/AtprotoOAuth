// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "OAuthenticator",
	platforms: [
		.macOS(.v11),
		.macCatalyst(.v13),
		.iOS(.v14),
		.tvOS(.v13),
		.watchOS(.v7),
		.visionOS(.v1),
	],
	products: [
		.library(name: "OAuthenticator", targets: ["OAuthenticator"]),
	],
	dependencies: [
	],
	targets: [
		.target(
			name: "OAuthenticator",
			dependencies: [],
			resources: [.process("PrivacyInfo.xcprivacy")]
		),
		.testTarget(name: "OAuthenticatorTests", dependencies: ["OAuthenticator"]),
	]
)
