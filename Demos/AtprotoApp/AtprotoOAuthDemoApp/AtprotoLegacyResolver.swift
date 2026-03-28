//
//  AtprotoPLCResolver.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/18/26.
//

import ATResolve
import AtprotoClient
import AtprotoTypes
import Foundation
import GermConvenience
import HTTPTypes

public struct AtprotoLegacyResolver: AtprotoResolver {
	let resourceFetcher: HTTPFetcher

	public init(resourceFetcher: HTTPFetcher) {
		self.resourceFetcher = resourceFetcher
	}

	public func resolve(handle: AtprotoTypes.AtIdentifier.Handle) async throws
		-> AtprotoTypes.Atproto.DID
	{
		guard
			let did = try? await ATResolver(provider: URLSession.shared).didForHandle(
				handle.lowercased())
		else {
			throw AtprotoResolverError.noDidForHandle
		}
		return try .init(string: did)
	}

	public func resolve(did: AtprotoTypes.Atproto.DID) async throws -> Atproto.DIDDocument {
		let url = try constructPlcQueryUrl(did: did)

		let request = HTTPRequestBody(url: url, method: .get)

		return try await resourceFetcher.data(for: request)
			.expectSuccess()
			.decode()
	}

	private func constructPlcQueryUrl(did: Atproto.DID) throws -> URL {
		var components = URLComponents()
		components.scheme = URLScheme.https.rawValue
		components.host = "plc.directory"
		components.path = "/\(did.stringRepresentation)"
		return try components.url.tryUnwrap
	}
}
