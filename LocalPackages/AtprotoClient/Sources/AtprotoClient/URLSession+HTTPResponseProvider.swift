//
//  URLResponseProviderError.swift
//  AtprotoClient
//
//  Created by Mark @ Germ on 2/24/26.
//

import Foundation
import GermConvenience

enum URLResponseProviderError: Error {
	case missingResponseComponents
}

extension URLSession {
	/// Convert a `URLSession` instance into a `URLResponseProvider`.
	public var responseProvider: HTTPDataResponse.Requester {
		{ request in
			let (data, urlResponse) = try await self.data(for: request)
			if let httpResponse = urlResponse as? HTTPURLResponse {
				return .init(data: data, response: httpResponse)
			} else {
				throw AtprotoClientError.nonHTTPResponse
			}
		}
	}

	/// Convert a `URLSession` with a default configuration into a `URLResponseProvider`.
	public static var defaultProvider: HTTPDataResponse.Requester {
		URLSession(configuration: .default).responseProvider
	}
}
