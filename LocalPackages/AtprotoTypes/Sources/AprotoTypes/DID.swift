//
//  DID.swift
//  SwiftAtprotoOAuth
//
//  Created by Mark @ Germ on 4/22/25.
//

import Foundation

//https://atproto.com/specs/did
//2KB limit, case sensitive,
//https://www.w3.org/TR/did-1.0/#did-syntax

//Store it as a string, do some rudimentary checking
//can implement more checks later

extension Atproto {
	public struct DID: Equatable, Hashable, Sendable {
		enum Constants {
			static let prefix = "did:"
		}

		public let identifier: String
		public let method: Methods

		public var fullId: String {
			Constants.prefix + method.rawValue + ":" + identifier
		}

		public enum Methods: String, CaseIterable, Sendable {
			case plc
			case web

			static func parse(
				_ subsequence: String.SubSequence
			) throws -> (Self, String) {
				for method in Methods.allCases {
					if subsequence.hasPrefix(method.rawValue + ":") {
						return (
							method,
							String(
								subsequence.dropFirst(
									method.rawValue.count + 1)
							)
						)
					}
				}
				throw AtprotoDIDError.invalidMethod
			}
		}

		public init(method: Methods, identifier: String) {
			self.method = method
			self.identifier = identifier
		}

		public init(fullId: String) throws {
			guard fullId.hasPrefix(Constants.prefix) else {
				throw AtprotoDIDError.invalidPrefix
			}
			let remainder = fullId.dropFirst(Constants.prefix.count)
			(method, identifier) = try Methods.parse(remainder)
		}
	}
}

extension Atproto.DID {
	static public func mock(method: Methods = .plc) -> Self {
		.init(method: method, identifier: UUID().uuidString)
	}
}

public enum AtprotoDIDError: Error {
	case invalidPrefix
	case invalidMethod
}

extension AtprotoDIDError: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .invalidPrefix: "Invalid prefix"
		case .invalidMethod: "Invalid method"
		}
	}
}
