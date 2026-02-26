//
//  PLCDirectoryQuery.swift
//  ATProtoClient
//
//  Created by Mark @ Germ on 2/19/26.
//

import ATProtoTypes
import Foundation

extension ATProtoClient {
	public func plcDirectoryQuery(
		_ did: ATProtoDID
	) async throws -> DIDDocument {
		let url = try constructPlcQueryUrl(did: did)
		var request = URLRequest(url: url)
		request.addValue("application/json", forHTTPHeaderField: "Accept")

		return try await responseProvider(request)
			.successDecode()
	}

	private func constructPlcQueryUrl(did: ATProtoDID) throws -> URL {
		var components = URLComponents()
		components.scheme = "https"
		components.host = "plc.directory"
		components.path = "/\(did.fullId)"

		guard let url = components.url else {
			throw ATProtoClientError.couldntConstructUrl
		}
		return url
	}
}
