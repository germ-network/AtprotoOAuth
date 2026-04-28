//
//  ATResolveResolver.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/18/26.
//

import ATResolve
import AtprotoClient
import AtprotoOAuth
import AtprotoTypes
import Foundation
import GermConvenience
import HTTPTypes

public struct ATResolveResolver: Atproto.Resolver {
	let resourceFetcher: HTTPFetcher

	public init(resourceFetcher: HTTPFetcher) {
		self.resourceFetcher = resourceFetcher
	}

	public func resolve(
		handle: Atproto.Handle
	) async throws -> Atproto.DID? {
		let did = try await ATResolver(provider: URLSession.shared)
			.didForHandle(handle.rawValue.lowercased())

		return try .init(string: did.tryUnwrap)
	}

	public func resolve(did: Atproto.DID) async throws -> Atproto.DIDDocument? {
		let url = try constructPlcQueryUrl(did: did)

		let request = BundledHTTPRequest(
			request: .init(method: .get, url: url)
		)

		return try await resourceFetcher.data(for: request)
			.expectSuccess()
			.decode()
	}

	private func constructPlcQueryUrl(did: Atproto.DID) throws -> URL {
		var components = URLComponents()
		components.scheme = URLScheme.https.rawValue
		components.host = "plc.directory"
		components.path = "/\(did.rawValue)"
		return try components.url.tryUnwrap
	}
}
