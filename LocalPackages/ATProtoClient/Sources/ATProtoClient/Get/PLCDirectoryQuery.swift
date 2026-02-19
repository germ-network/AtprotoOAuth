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

		let (result, response) = try await responseProvider(request)
		guard
			let httpResponse = response as? HTTPURLResponse,
			httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
		else {

			throw ATProtoClientError.requestFailed(
				responseCode: (response as? HTTPURLResponse)?.statusCode
			)
		}
		return try JSONDecoder()
			.decode(
				DIDDocument.self,
				from: result
			)
	}

	private func constructPlcQueryUrl(did: ATProtoDID) throws -> URL {
		var components = URLComponents()
		components.scheme = "https"
		components.host = "plc.directory"
		components.path = "/\(did)"

		guard let url = components.url else {
			throw ATProtoClientError.couldntConstructUrl
		}
		return url
	}
}
