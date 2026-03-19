// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Microcosm",
	platforms: [.iOS(.v16), .macOS(.v15)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "Microcosm",
			targets: ["Microcosm"]
		)
	],
	dependencies: [
		.package(
			url: "https://github.com/germ-network/AtprotoTypes.git",
			from: "0.0.1"
		),
		.package(
			url: "https://github.com/germ-network/GermConvenience.git",
			from: "0.0.2"
		),
		.package(path: "../AtprotoClient"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "Microcosm",
			dependencies: ["AtprotoTypes", "AtprotoClient", "GermConvenience"]
		),
		.testTarget(
			name: "MicrocosmTests",
			dependencies: ["Microcosm"]
		),
	]
)
