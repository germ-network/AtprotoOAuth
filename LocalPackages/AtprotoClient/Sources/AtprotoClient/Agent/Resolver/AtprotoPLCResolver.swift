//
//  AtprotoPLCResolver.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/18/26.
//

import ATResolve
import AtprotoTypes
import Foundation
import GermConvenience

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

	public func resolve(did: AtprotoTypes.Atproto.DID) async throws -> AtprotoTypes.DIDDocument
	{
		let url = try constructPlcQueryUrl(did: did)
		var request = URLRequest(url: url)
		request.addValue("application/json", forHTTPHeaderField: "Accept")

		return try await resourceFetcher.data(for: request)
			.expectSuccess()
			.decode()
	}

	private func constructPlcQueryUrl(did: Atproto.DID) throws -> URL {
		var components = URLComponents()
		components.scheme = "https"
		components.host = "plc.directory"
		components.path = "/\(did.stringRepresentation)"

		return try components.url
			.tryUnwrap(AtprotoClientError.couldntConstructUrl)
	}
}
