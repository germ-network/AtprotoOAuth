//
//  PLCDirectoryQuery.swift
//  AtprotoClient
//
//  Created by Mark @ Germ on 2/19/26.
//

import AtprotoTypes
import Foundation
import GermConvenience

extension AtprotoClient {
	public func plcDirectoryQuery(
		_ did: Atproto.DID
	) async throws -> DIDDocument {
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
