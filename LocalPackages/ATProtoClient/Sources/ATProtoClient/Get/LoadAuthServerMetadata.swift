//
//  LoadAuthServerMetadata.swift
//  ATProtoClient
//
//  Created by Mark @ Germ on 2/19/26.
//

import Foundation
import OAuth

extension ATProtoClient {
	public func loadAuthServerMetadata(
		host: String
	) async throws -> AuthServerMetadata {
		var components = URLComponents()
		components.scheme = "https"
		components.host = host
		components.path = "/.well-known/oauth-authorization-server"

		guard let url = components.url else {
			throw ATProtoClientError.couldntConstructUrl
		}

		var request = URLRequest(url: url)
		request.setValue("application/json", forHTTPHeaderField: "Accept")

		return try await responseProvider(request)
			.successDecode()
	}
}
