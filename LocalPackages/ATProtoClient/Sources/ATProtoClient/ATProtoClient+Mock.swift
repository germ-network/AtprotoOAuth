//
//  ATProtoClient+Mock.swift
//  ATProtoClient
//
//  Created by Mark @ Germ on 2/18/26.
//

import ATProtoTypes
import Foundation
import OAuthenticator

public struct MockATProtoClient: ATProtoClientInterface {
	public init() {}

	public func resolveDocument(did: ATProtoDID) async throws -> DIDDocument {
		try .mock()
	}

	public func loadProtectedResourceMetadata(
		host: String,
	) async throws -> ProtectedResourceMetadata {
		try JSONDecoder().decode(
			ProtectedResourceMetadata.self,
			from:
				"""
				{"resource":"https://blacksky.app","authorization_servers":["https://blacksky.app"],"scopes_supported":[],"bearer_methods_supported":["header"],"resource_documentation":"https://atproto.com"}
				""".utf8Data
		)
	}
}

enum MockATProtoClientError: Error {
	case urlConstructionFailed
}

extension MockATProtoClientError: LocalizedError {
	var localizedDescription: String {
		switch self {
		case .urlConstructionFailed: "Failed to construct URL"
		}
	}
}

extension String {
	var utf8Data: Data {
		Data(utf8)
	}
}
