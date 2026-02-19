//
//  LoadAuthServerMetadata.swift
//  ATProtoClient
//
//  Created by Mark @ Germ on 2/19/26.
//

import Foundation
import OAuthenticator

extension ATProtoClient {
	public func loadAuthServerMetadata(
		host: String
	) async throws -> ServerMetadata {
		var components = URLComponents()
		components.scheme = "https"
		components.host = host
		components.path = "/.well-known/oauth-authorization-server"

		guard let url = components.url else {
			throw ATProtoClientError.couldntConstructUrl
		}

		var request = URLRequest(url: url)
		request.setValue("application/json", forHTTPHeaderField: "Accept")

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
				ServerMetadata.self,
				from: result
			)
	}
}
