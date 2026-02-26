// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "AtprotoTypes",
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "AtprotoTypes",
			targets: ["AtprotoTypes"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/Jarema/Base32.git", from: "0.10.2")
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "AtprotoTypes",
			dependencies: ["Base32"]
		),
		.testTarget(
			name: "AtprotoTypesTests",
			dependencies: ["AtprotoTypes"]
		),
	]
)
