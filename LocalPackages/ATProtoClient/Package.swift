// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "AtprotoClient",
	platforms: [.iOS(.v15), .macOS(.v13)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "AtprotoClient",
			targets: ["AtprotoClient"]
		)
	],
	dependencies: [
		.package(path: "../AtprotoTypes"),
		.package(path: "../GermConvenience"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "AtprotoClient",
			dependencies: ["AtprotoTypes", "GermConvenience"]
		),
		.testTarget(
			name: "AtprotoClientTests",
			dependencies: ["AtprotoClient"]
		),
	]
)
