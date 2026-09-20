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
		// Temporary revision pins to the swift-crypto-5 commits during the
		// org-wide migration; replace with released versions once they cut.
		.package(
			url: "https://github.com/germ-network/AtprotoClient.git",
			revision: "a26d4f27dc2b1601313e0b7a8f5f265b1c84acf5"
		),
		.package(
			url: "https://github.com/germ-network/AtprotoTypes.git",
			revision: "8e00dd81013fef864de2b0f3dde7ad7fcbdc119b"
		),
		.package(
			url: "https://github.com/germ-network/GermConvenience.git",
			revision: "f907c9018dd4c2f0110ab5f1f37c7c53fa0ae6ca"
		),
		//use this as a out of the box resolver for tests
		//does not get included in the main package
		//0.4.1 carries the GermConvenienceHTTP-adoption fix for 0.8.0.
		.package(
			url: "https://github.com/germ-network/Microcosm.git",
			from: "0.4.1"
		),
		//0.7.0 carries the GermConvenienceHTTP-adoption fix for 0.8.0.
		.package(
			url: "https://github.com/germ-network/oauth4swift.git",
			// Temporary revision pin to germ-network/oauth4swift#67 (exposes the
			// archive/DPoP fields + token inits, and moves to swift-crypto 5);
			// replace with the released version once it cuts.
			revision: "3a3faeeff2a10925dbceaeb6942d16482aeba5e2"
		),
		.package(
			url: "https://github.com/apple/swift-crypto.git",
			from: "5.0.0"),
		.package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
		.package(url: "https://github.com/apple/swift-http-types.git", from: "1.5.1"),
		.package(url: "https://github.com/swift-libp2p/swift-bases.git", from: "0.2.0"),
		// Zeroizing custody for the secrets `AtprotoOAuthAgent.Archive` carries
		// (DPoP private signing key, access/refresh tokens). 0.5.0 is the
		// swift-crypto-5 release that adds the `SecretArchive`/`@SecretField` SPI
		// this archive rides, matching the org-wide swift-crypto 5 move.
		.package(
			url: "https://github.com/germ-network/swift-secret-bytes.git",
			.upToNextMinor(from: "0.5.0")
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
				"GermConvenience",
				.product(name: "GermConvenienceHTTP", package: "GermConvenience"),
				.product(name: "Crypto", package: "swift-crypto"),
				.product(name: "HTTPTypes", package: "swift-http-types"),
				.product(name: "OAuth4Swift", package: "oauth4swift"),
				.product(name: "SecretBytes", package: "swift-secret-bytes"),
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
