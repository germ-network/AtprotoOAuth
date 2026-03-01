//
//  OAuthMetadataFetcher.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/28/26.
//

import Foundation
import GermConvenience

//allows for test mocking
public protocol OAuthMetadataFetcher: Sendable {
	func fetchMetadata(
		protectedResourceHost: String
	) async throws -> ProtectedResourceMetadata

	func fetchMetadata(
		authServerHost: String
	) async throws -> AuthServerMetadata

	func fetchMetadata(
		clientHost: String
	) async throws -> ClientMetadata
}

public struct HTTPOAuthMetadataFetcher {
	let httpRequester: HTTPDataResponse.Requester

	public init(httpRequester: @escaping HTTPDataResponse.Requester) {
		self.httpRequester = httpRequester
	}
}

extension HTTPOAuthMetadataFetcher: OAuthMetadataFetcher {
	public func fetchMetadata(clientHost: String) async throws -> ClientMetadata {
		try await .load(for: clientHost, httpRequester: httpRequester)
	}

	public func fetchMetadata(
		authServerHost: String
	) async throws -> AuthServerMetadata {
		try await .load(for: authServerHost, httpRequester: httpRequester)
	}

	public func fetchMetadata(
		protectedResourceHost: String
	) async throws -> ProtectedResourceMetadata {
		try await .load(for: protectedResourceHost, httpRequester: httpRequester)
	}
}
